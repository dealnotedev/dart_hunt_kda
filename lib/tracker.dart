import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:hunt_stats/db/entities.dart';
import 'package:hunt_stats/db/entities_ext.dart';
import 'package:hunt_stats/db/stats_db.dart';
import 'package:hunt_stats/generated/assets.dart';
import 'package:hunt_stats/hunt_bundle.dart';
import 'package:hunt_stats/hunt_finder.dart';
import 'package:hunt_stats/parser/hunt_attributes_parser.dart';
import 'package:hunt_stats/parser/models.dart';
import 'package:hunt_stats/ringtone.dart';
import 'package:hunt_stats/text_stats_generator.dart';
import 'package:rxdart/rxdart.dart';

class TrackerEngine {
  final _bundleSubject = StreamController<HuntBundle?>.broadcast();
  final _newMatchesSubject = StreamController<MatchEntity>.broadcast();
  final _mapSubject = StreamController<String>.broadcast();

  final bool listenGameLog;
  final bool sound;
  final StatsDb db;

  final _gameEventSubject = StreamController<_TrackerEvent>.broadcast();

  TrackerEngine(this.db, {required this.listenGameLog, required this.sound}) {
    _gameEventSubject.stream.listen(_handleGameEvent);
  }

  Stream<MissionState> get missionState => _gameEventSubject.stream
      .where((event) => event is _MissionState)
      .cast<_MissionState>()
      .map(_parseMissionState)
      .distinct();

  Stream<MatchEntity> get newMatches => _newMatchesSubject.stream;

  static MissionState _parseMissionState(_MissionState event) {
    switch (event.state) {
      case 'MissionStarted':
        return MissionState.started;
      case 'ContentsDumped':
        return MissionState.ended;
      case 'Empty':
        return MissionState.empty;
      default:
        return MissionState.unknown;
    }
  }

  MissionState lastKnownMissionState = MissionState.unknown;

  Future<void> _handleGameEvent(_TrackerEvent info) async {
    if (info is _NewHuntMatch) {
      await _saveHuntMatch(info.match);
    }

    if (info is _MissionState) {
      lastKnownMissionState = _parseMissionState(info);
    }

    if (info is _MapLoading) {
      _mapSubject.add(info.levelName);

      if (sound) {
        await _playMapSound(info.levelName);
      }
    }
  }

  Future<void> start() async {
    await _refreshData();
    await _startTracking();
  }

  Future<void> _playMapSound(String mapName) async {
    switch (mapName) {
      case 'creek':
        RingtonePlayer.play(Assets.assetsCreek);
        break;
      case 'cemetery':
        RingtonePlayer.play(Assets.assetsCemetery);
        break;
      case 'civilwar':
        RingtonePlayer.play(Assets.assetsCivilwar);
        break;
    }
  }

  final _textGenerator = TextStatsGenerator(tableWidth: 32);

  File get _textStatsFile {
    final dir = File(Platform.resolvedExecutable).parent;
    return File('${dir.path}/stats.txt');
  }

  Future<void> _refreshData() async {
    final header = await db.getLastMatch(mode: LastMatchMode.lastActual);

    if (header != null) {
      final firstActual =
          await db.getLastMatch(mode: LastMatchMode.firstActual);

      final players = await db.getMatchPlayers(header.id);
      final match = MatchEntity(match: header, players: players);
      final ownStats = await db.getOwnStats();
      final teamStats = await db.getTeamStats(header.teamId);

      final enemiesStats = await db.getEnemiesStats(_getEnemiesMap(players));

      final myProfileId = await db.calculateMostPlayerTeammate(
          players.where((element) => element.teammate).map((e) => e.profileId));

      final bundle = HuntBundle(
          from: firstActual?.date,
          match: match,
          me: players
              .firstWhereOrNull((element) => element.profileId == myProfileId),
          enemyStats: enemiesStats.values.toList(),
          ownStats: ownStats,
          teamStats: teamStats,
          previousTeamStats: null,
          previousOwnStats: null,
          previousMatch: null);

      await _textGenerator.write(bundle: bundle, file: _textStatsFile);

      lastBundle = bundle;
      _bundleSubject.add(bundle);
    } else {
      lastBundle = null;
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

  HuntBundle? lastBundle;

  Stream<String> get map => _mapSubject.stream;

  Stream<HuntBundle?> get lastMatch {
    final last = lastBundle;
    if (last != null) {
      return Stream<HuntBundle?>.value(last)
          .concatWith([_bundleSubject.stream]);
    } else {
      return _bundleSubject.stream;
    }
  }

  Future<void> _saveHuntMatch(MatchEntity data) async {
    final previousTeamStats = data.match.teamId == lastBundle?.teamId
        ? lastBundle?.teamStats
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
        from: lastBundle?.from ?? data.match.date,
        match: data,
        me: players
            .firstWhereOrNull((element) => element.profileId == myProfileId),
        enemyStats: enemiesStats.values.toList(),
        ownStats: ownStats,
        teamStats: teamStats,
        previousTeamStats: previousTeamStats,
        previousOwnStats: lastBundle?.ownStats,
        previousMatch: lastBundle?.match);

    lastBundle = bundle;

    await _textGenerator.write(bundle: bundle, file: _textStatsFile);

    _bundleSubject.add(bundle);
    _newMatchesSubject.add(data);
  }

  Future<void> invalidateMatches() async {
    await db.outdate();
    await _refreshData();
  }

  Future<void> invalidateTeam(String teamId) async {
    await db.outdateTeam(teamId);
    await _refreshData();
  }

  Future<void> _checkHuntMatch(
      HuntAttributesParser parser, String attributes, Set<String> signatures,
      {required bool initial}) async {
    final file = File(attributes);

    final HuntMatchData data;
    try {
      data = await compute(parser.parseFromFile, file);
    } catch (_) {
      _gameEventSubject.add(_AttributesParseFail());
      return;
    }

    if (signatures.add(data.header.signature)) {
      final match =
          await data.toEntity(db, outdated: false, teamOutdated: false);
      _gameEventSubject.add(_NewHuntMatch(match: match, initial: initial));
    } else {
      _gameEventSubject.add(_NoNewMatches());
    }
  }

  Future<void> _startTracking() async {
    final finder = HuntFinder();
    final parser = HuntAttributesParser();

    final file = await finder.findHuntAttributes();
    final attributes = file.path;

    _gameEventSubject.add(_HuntFound(attributes));

    final signatures = <String>{};
    await _checkHuntMatch(parser, attributes, signatures, initial: true);

    Timer.periodic(const Duration(seconds: 10), (timer) async {
      await _checkHuntMatch(parser, attributes, signatures, initial: false);
    });

    if (listenGameLog) {
      await _statsGameLogListening(attributes: file);
    }
  }

  Future<void> _statsGameLogListening({required File attributes}) async {
    final userDirectory = attributes.parent.parent.parent;
    final logFile = File('${userDirectory.path}\\game.log');

    final currentState = await _findMissionState(logFile);
    _gameEventSubject.add(_MissionState(state: currentState));

    //<01:06:53> ============================ PrepareLevel levels/creek ============================
    // ....
    //<01:08:03> CMetaMissionBag state: MissionStarted
    //<22:57:22> CMetaMissionBag state: ContentsDumped
    //<22:22:36> CMetaMissionBag state: Empty

    var length = await logFile.length();
    Timer.periodic(const Duration(seconds: 1), (timer) {
      final actualLength = logFile.lengthSync();
      if (actualLength == length) {
        return;
      }
      if (actualLength < length) {
        length = 0;
      }

      logFile
          .openRead(length)
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .forEach((s) {
        length += s.length;

        final parts = s.split(' ');

        final level = _findPrepareLevel(parts);
        if (level != null) {
          _gameEventSubject.add(_MapLoading(level));
        }

        final state = _findMissionBag(parts);
        if (state != null) {
          _gameEventSubject.add(_MissionState(state: state));
        }
      });
    });
  }

  static String? _findPrepareLevel(List<String> parts) {
    final levelIndex = parts.lastIndexOf('PrepareLevel');
    if (levelIndex != -1) {
      return parts[levelIndex + 1].split('/')[1];
    } else {
      return null;
    }
  }

  static String? _findMissionBag(List<String> parts) {
    final index = parts.lastIndexOf('CMetaMissionBag');
    if (index != -1) {
      return parts[index + 2];
    } else {
      return null;
    }
  }

  Future<String?> _findMissionState(File logFile) async {
    String? state;
    await logFile
        .openRead()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .forEach((s) {
      final parts = s.split(' ');
      state = _findMissionBag(parts) ?? state;
    });
    return state;
  }

  Future<HuntMatchData> extractFromFile(File file) async {
    return HuntAttributesParser().parseFromFile(file);
  }

  Future<void> validateLast({required bool reset}) async {
    final last = await db.getLastMatch(
        mode: reset ? LastMatchMode.firstActual : LastMatchMode.lastOutdated);
    if (last != null) {
      await db.outdateOne(id: last.id, outdated: reset, teamOutdated: reset);
      await _refreshData();
    }
  }
}

sealed class _TrackerEvent {}

class _MissionState extends _TrackerEvent {
  /// One of MissionStarted, ContentsDumped, Empty
  final String? state;

  _MissionState({required this.state});
}

class _AttributesParseFail extends _TrackerEvent {}

class _NewHuntMatch extends _TrackerEvent {
  final bool initial;
  final MatchEntity match;

  _NewHuntMatch({required this.match, required this.initial});
}

class _NoNewMatches extends _TrackerEvent {}

class _MapLoading extends _TrackerEvent {
  final String levelName;

  _MapLoading(this.levelName);
}

class _HuntFound extends _TrackerEvent {
  final String attributes;

  _HuntFound(this.attributes);
}

enum MissionState { empty, unknown, started, ended }
