import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:collection/collection.dart';
import 'package:hunt_stats/db/entities.dart';
import 'package:hunt_stats/db/entities_ext.dart';
import 'package:hunt_stats/db/stats_db.dart';
import 'package:hunt_stats/hunt_bundle.dart';
import 'package:hunt_stats/hunt_finder.dart';
import 'package:hunt_stats/parser/hunt_attributes_parser.dart';
import 'package:hunt_stats/parser/models.dart';
import 'package:rxdart/rxdart.dart';

class TrackerEngine {
  final _bundleSubject = StreamController<HuntBundle?>.broadcast();

  final StatsDb db;

  TrackerEngine(this.db);

  Future<void> start() async {
    await _refreshData();

    final ReceivePort port = ReceivePort('Tracking')
      ..listen((dynamic info) {
        if (info is MatchEntity) {
          saveHuntMatch(info);
        }
      });

    await Isolate.spawn(_startTracking, port.sendPort);
  }

  Future<void> _refreshData() async {
    final header = await db.getLastMatch();

    if (header != null) {
      final players = await db.getMatchPlayers(header.id);
      final match = MatchEntity(match: header, players: players);
      final ownStats = await db.getOwnStats();
      final teamStats = await db.getTeamStats(header.teamId);

      final enemiesStats = await db.getEnemiesStats(_getEnemiesMap(players));

      final myProfileId = await db.calculateMostPlayerTeammate(
          players.where((element) => element.teammate).map((e) => e.profileId));

      final bundle = HuntBundle(
          match: match,
          me: players
              .firstWhereOrNull((element) => element.profileId == myProfileId),
          enemyStats: enemiesStats.values.toList(),
          ownStats: ownStats,
          teamStats: teamStats,
          previousTeamStats: null,
          previousOwnStats: null,
          previousMatch: null);
      _lastBundle = bundle;
      _bundleSubject.add(bundle);
    } else {
      _lastBundle = null;
      _bundleSubject.add(null);
    }
  }

  static Map<int, PlayerEntity> _getEnemiesMap(List<PlayerEntity> players) {
    final enemies = players
        .where((element) => !element.teammate && element.hasMutuallyKillDowns);
    final map = <int, PlayerEntity>{};
    map.addEntries(enemies.map((e) => MapEntry(e.profileId, e)));
    return map;
  }

  HuntBundle? _lastBundle;

  Stream<HuntBundle?> get lastMatch {
    final last = _lastBundle;
    if (last != null) {
      return Stream<HuntBundle?>.value(last)
          .concatWith([_bundleSubject.stream]);
    } else {
      return _bundleSubject.stream;
    }
  }

  Future<void> saveHuntMatch(MatchEntity data) async {
    final previousTeamStats = data.match.teamId == _lastBundle?.teamId
        ? _lastBundle?.teamStats
        : await db.getTeamStats(data.match.teamId);

    await db.insertHuntMatch(data.match);

    if (data.match.id == 0) return;

    final players = data.players;

    for (var element in players) {
      element.matchId = data.match.id;
      element.teamId = data.match.teamId;
    }

    await db.insertHuntMatchPlayers(players);

    final enemiesStats = await db.getEnemiesStats(_getEnemiesMap(players));

    final myProfileId = await db.calculateMostPlayerTeammate(
        players.where((element) => element.teammate).map((e) => e.profileId));

    final ownStats = await db.getOwnStats();
    final teamStats = await db.getTeamStats(data.match.teamId);

    final bundle = HuntBundle(
        match: data,
        me: players
            .firstWhereOrNull((element) => element.profileId == myProfileId),
        enemyStats: enemiesStats.values.toList(),
        ownStats: ownStats,
        teamStats: teamStats,
        previousTeamStats: previousTeamStats,
        previousOwnStats: _lastBundle?.ownStats,
        previousMatch: _lastBundle?.match);

    _lastBundle = bundle;
    _bundleSubject.add(bundle);
  }

  Future<void> invalidateMatches() async {
    await db.outdate();
    await _refreshData();
  }

  Future<void> invalidateTeam(String teamId) async {
    await db.outdateTeam(teamId);
    await _refreshData();
  }

  static void _startTracking(SendPort port) async {
    final finder = HuntFinder();
    final parser = HuntAttributesParser();

    final file = await finder.findHuntAttributes();
    final attributes = file.path;

    port.send(HuntPath(attributes));

    final signatures = <String>{};

    Timer.periodic(const Duration(seconds: 30), (timer) async {
      final file = File(attributes);

      final data = await parser.parseFromFile(file);
      if (signatures.add(data.match.signature)) {
        port.send(data.toEntity());
      }
    });
  }

  Future<HuntMatchData> extractFromFile(File file) async {
    return HuntAttributesParser().parseFromFile(file);
  }
}

class HuntPath {
  final String attributes;

  HuntPath(this.attributes);
}
