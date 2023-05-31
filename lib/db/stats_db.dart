import 'dart:async';
import 'dart:io';

import 'package:hunt_stats/db/columns.dart';
import 'package:hunt_stats/db/entities.dart';
import 'package:hunt_stats/db/stats.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class StatsDb {
  late final DatabaseFactory dbFactory;

  StatsDb() {
    sqfliteFfiInit();
    dbFactory = createDatabaseFactoryFfi();
  }

  Future<Database> get database {
    final String path;

    if (Platform.isWindows) {
      final executable = Platform.resolvedExecutable;
      final parent = File(executable).parent;

      path = join(parent.path, '.dart_tool', 'sqflite_common_ffi', 'databases',
          'stats.db');
    } else {
      path = 'stats.db';
    }

    return dbFactory.openDatabase(path,
        options: OpenDatabaseOptions(
            version: 2,
            singleInstance: true,
            onCreate: _onCreate,
            onUpgrade: _onUpgrade));
  }

  Future<void> insertHuntMatchPlayers(Iterable<HuntPlayer> entities) async {
    final db = await database;

    await db.transaction<void>((txn) async {
      for (var entity in entities) {
        final values = <String, Object?>{};

        values[HuntPlayerColumns.teamId] = entity.teamId;
        values[HuntPlayerColumns.matchId] = entity.matchId;
        values[HuntPlayerColumns.teammate] = entity.teammate ? 1 : 0;
        values[HuntPlayerColumns.teamIndex] = entity.teamIndex;
        values[HuntPlayerColumns.profileId] = entity.profileId;
        values[HuntPlayerColumns.username] = entity.username;
        values[HuntPlayerColumns.bountyExtracted] = entity.bountyExtracted;
        values[HuntPlayerColumns.bountyPickedup] = entity.bountyPickedup;
        values[HuntPlayerColumns.downedByMe] = entity.downedByMe;
        values[HuntPlayerColumns.downedByTeam] = entity.downedByTeam;
        values[HuntPlayerColumns.downedMe] = entity.downedMe;
        values[HuntPlayerColumns.downedTeam] = entity.downedTeam;
        values[HuntPlayerColumns.hadWellspring] = entity.hadWellspring ? 1 : 0;
        values[HuntPlayerColumns.soulSurvivor] = entity.soulSurvivor ? 1 : 0;
        values[HuntPlayerColumns.killedByMe] = entity.killedByMe;
        values[HuntPlayerColumns.killedByTeam] = entity.killedByTeam;
        values[HuntPlayerColumns.killedMe] = entity.killedMe;
        values[HuntPlayerColumns.killedTeam] = entity.killedTeam;
        values[HuntPlayerColumns.mmr] = entity.mmr;
        values[HuntPlayerColumns.voiceToMe] = entity.voiceToMe ? 1 : 0;
        values[HuntPlayerColumns.voiceToTeam] = entity.voiceToTeam ? 1 : 0;
        values[HuntPlayerColumns.teamExtraction] =
            entity.teamExtraction ? 1 : 0;
        values[HuntPlayerColumns.skillBased] = entity.skillBased ? 1 : 0;

        final id = await txn.insert(HuntPlayerColumns.table, values,
            conflictAlgorithm: ConflictAlgorithm.ignore);
        entity.id = id;
      }
    });
  }

  Future<TeamStats> getTeamStats(String teamId) async {
    final db = await database;

    final cursor = await db.rawQuery(
        'SELECT '
        'sum(${HuntMatchColumns.teamDeaths}) as team_deaths, '
        'sum(${HuntMatchColumns.teamDowns}) as team_downs, '
        'sum(${HuntMatchColumns.ownDowns}) as own_downs, '
        'sum(${HuntMatchColumns.ownDeaths}) as own_deaths, '
        'sum(${HuntMatchColumns.ownEnemyDeaths}) as own_enemy_deaths, '
        'sum(${HuntMatchColumns.ownEnemyDowns}) as own_enemy_downs, '
        'sum(${HuntMatchColumns.teamEnemyDeaths}) as team_enemy_deaths, '
        'sum(${HuntMatchColumns.teamEnemyDowns}) as team_enemy_downs, '
        'count(${HuntMatchColumns.id}) as matches '
        'FROM ${HuntMatchColumns.table} '
        'WHERE ${HuntMatchColumns.teamId} LIKE ? AND ${HuntMatchColumns.outdated} = ?',
        [teamId, 0]);

    final row = cursor[0];
    return TeamStats(
        matches: row.intOf('matches'),
        teamKills: row.intOf('team_enemy_deaths') +
            row.intOf('team_enemy_downs') +
            row.intOf('own_enemy_deaths') +
            row.intOf('own_enemy_downs'),
        teamDeaths: row.intOf('team_deaths') +
            row.intOf('team_downs') +
            row.intOf('own_downs') +
            row.intOf('own_deaths'));
  }

  Future<OwnStats> getOwnStats() async {
    final db = await database;

    final cursor = await db.rawQuery(
        'SELECT '
        'sum(${HuntMatchColumns.ownEnemyDowns}) as own_enemy_downs, '
        'sum(${HuntMatchColumns.ownEnemyDeaths}) as own_enemy_deaths, '
        'sum(${HuntMatchColumns.ownDeaths}) as own_deaths, '
        'sum(${HuntMatchColumns.ownDowns}) as own_downs, '
        'sum(${HuntMatchColumns.teamDeaths}) as team_deaths, '
        'sum(${HuntMatchColumns.teamDowns}) as team_downs, '
        'sum(${HuntMatchColumns.teamEnemyDeaths}) as team_enemy_deaths, '
        'sum(${HuntMatchColumns.teamEnemyDowns}) as team_enemy_downs, '
        'sum(${HuntMatchColumns.ownAssists}) as own_assists, '
        'count(${HuntMatchColumns.id}) as matches '
        'FROM ${HuntMatchColumns.table} '
        'WHERE ${HuntMatchColumns.outdated} = ?',
        [0]);

    final row = cursor[0];
    return OwnStats(
        matches: row.intOf('matches'),
        teamDeaths: row.intOf('team_deaths') + row.intOf('team_downs'),
        teamKills:
            row.intOf('team_enemy_deaths') + row.intOf('team_enemy_downs'),
        ownKills: row.intOf('own_enemy_downs') + row.intOf('own_enemy_deaths'),
        ownDeaths: row.intOf('own_deaths') + row.intOf('own_downs'),
        ownAssists: row.intOf('own_assists'));
  }

  Future<Map<int, EnemyStats>> getEnemiesStats(
      Map<int, HuntPlayer> enemies) async {
    final db = await database;
    final keys = enemies.keys;

    final cursor = await db.rawQuery(
        'SELECT ${HuntPlayerColumns.profileId}, '
        'count(${HuntPlayerColumns.matchId}) as matches, '
        'sum(${HuntPlayerColumns.downedByMe}) as downed_by_me, '
        'sum(${HuntPlayerColumns.killedByMe}) as killed_by_me, '
        'sum(${HuntPlayerColumns.killedMe}) as killed_me, '
        'sum(${HuntPlayerColumns.downedMe}) as downed_me '
        'FROM ${HuntPlayerColumns.table} '
        'WHERE ${HuntPlayerColumns.profileId} IN (${_quotes(keys)}) '
        'GROUP BY ${HuntPlayerColumns.profileId}',
        keys.toList());

    final map = <int, EnemyStats>{};
    for (var row in cursor) {
      final profileId = row[HuntPlayerColumns.profileId] as int;
      final player = enemies[profileId]!;

      final matches = row.intOf('matches');
      if (matches < 2) {
        continue;
      }

      final downedByMe = row.intOf('downed_by_me');
      final killedByMe = row.intOf('killed_by_me');
      final downedMe = row.intOf('downed_me');
      final killedMe = row.intOf('killed_me');

      if (player.downedByMe == downedByMe &&
          player.killedByMe == killedByMe &&
          player.downedMe == downedMe &&
          player.killedMe == killedMe) {
        continue;
      }

      map[profileId] = EnemyStats(
          matches: matches,
          player: player,
          killedByMeLastMatch: player.downedByMe + player.killedByMe,
          killedMeLastMatch: player.downedMe + player.killedMe,
          killedMe: downedMe + killedMe,
          killedByMe: downedByMe + killedByMe);
    }

    return map;
  }

  int? _myProfileId;

  Future<int?> calculateMostPlayerTeammate(Iterable<int> profileIds) async {
    if (_myProfileId != null) {
      return _myProfileId;
    }

    final db = await database;
    final cursor = await db.rawQuery(
        'SELECT count(${HuntPlayerColumns.id}) as matches, ${HuntPlayerColumns.profileId} '
        'FROM ${HuntPlayerColumns.table} '
        'WHERE ${HuntPlayerColumns.teammate} = ? '
        'AND ${HuntPlayerColumns.profileId} IN (${_quotes(profileIds)})'
        'GROUP BY ${HuntPlayerColumns.profileId}',
        [1, ...profileIds]);

    int max = 0;
    List<int> maxProfileIds = [];

    for (var row in cursor) {
      final count = row['matches'] as int;
      final profileId = row[HuntPlayerColumns.profileId] as int;

      if (count > max) {
        max = count;
        maxProfileIds = List.of([profileId], growable: true);
      } else if (count == max) {
        maxProfileIds.add(profileId);
      }
    }

    if (maxProfileIds.length == 1) {
      final mostPlayedId = maxProfileIds[0];
      _myProfileId = mostPlayedId;
      return mostPlayedId;
    } else {
      return null;
    }
  }

  static String _quotes(Iterable<Object> list) =>
      list.map((e) => '?').join(',');

  Future<void> outdate() async {
    final db = await database;
    await db.rawUpdate(
        'UPDATE ${HuntMatchColumns.table} '
        'SET ${HuntMatchColumns.outdated} = ?, ${HuntMatchColumns.teamOutdated} = ? '
        'WHERE ${HuntMatchColumns.outdated} = ?',
        [1, 1, 0]);
  }

  Future<void> outdateTeam(String teamId) async {
    final db = await database;
    await db.rawUpdate(
        'UPDATE ${HuntMatchColumns.table} '
        'SET ${HuntMatchColumns.teamOutdated} = ? '
        'WHERE ${HuntMatchColumns.teamOutdated} = ? '
        'AND ${HuntMatchColumns.teamId} LIKE ?',
        [1, 0, teamId]);
  }

  Future<List<HuntPlayer>> getMatchPlayers(int matchId) async {
    final db = await database;

    final cursor = await db.rawQuery(
        'SELECT * FROM ${HuntPlayerColumns.table} WHERE ${HuntPlayerColumns.matchId} = ?',
        [matchId]);

    return cursor.map((row) {
      final entity = HuntPlayer(
          teammate: row[HuntPlayerColumns.teammate] as int == 1,
          teamIndex: row[HuntPlayerColumns.teamIndex] as int,
          profileId: row[HuntPlayerColumns.profileId] as int,
          username: row[HuntPlayerColumns.username] as String,
          bountyExtracted: row[HuntPlayerColumns.bountyExtracted] as int,
          bountyPickedup: row[HuntPlayerColumns.bountyPickedup] as int,
          downedByMe: row[HuntPlayerColumns.downedByMe] as int,
          downedByTeam: row[HuntPlayerColumns.downedByTeam] as int,
          downedMe: row[HuntPlayerColumns.downedMe] as int,
          downedTeam: row[HuntPlayerColumns.downedTeam] as int,
          hadWellspring: row[HuntPlayerColumns.hadWellspring] as int == 1,
          soulSurvivor: row[HuntPlayerColumns.soulSurvivor] as int == 1,
          killedByMe: row[HuntPlayerColumns.killedByMe] as int,
          killedByTeam: row[HuntPlayerColumns.killedByTeam] as int,
          killedMe: row[HuntPlayerColumns.killedMe] as int,
          killedTeam: row[HuntPlayerColumns.killedTeam] as int,
          mmr: row[HuntPlayerColumns.mmr] as int,
          voiceToMe: row[HuntPlayerColumns.voiceToMe] as int == 1,
          voiceToTeam: row[HuntPlayerColumns.voiceToTeam] as int == 1,
          teamExtraction: row[HuntPlayerColumns.teamExtraction] as int == 1,
          skillBased: row[HuntPlayerColumns.skillBased] as int == 1);

      entity.teamId = row[HuntPlayerColumns.teamId] as String;
      entity.id = row[HuntPlayerColumns.id] as int;
      entity.matchId = row[HuntPlayerColumns.matchId] as int;
      return entity;
    }).toList();
  }

  Future<HuntMatchHeader?> getLastMatch() async {
    final db = await database;

    final cursor = await db.rawQuery(
        'SELECT * FROM ${HuntMatchColumns.table} WHERE ${HuntMatchColumns.outdated} = ? ORDER BY ${HuntMatchColumns.date} DESC',
        [0]);

    if (cursor.isNotEmpty) {
      final row = cursor[0];
      final entity = HuntMatchHeader(
        mode: row[HuntMatchColumns.mode] as int,
        teams: row[HuntMatchColumns.teams] as int,
        teamOutdated: row[HuntMatchColumns.teamOutdated] as int == 1,
        teamSize: row[HuntMatchColumns.teamSize] as int,
        teamMmr: row[HuntMatchColumns.teamMmr] as int,
        ownDowns: row[HuntMatchColumns.ownDowns] as int,
        teamDowns: row[HuntMatchColumns.teamDowns] as int,
        ownEnemyDowns: row[HuntMatchColumns.ownEnemyDowns] as int,
        teamEnemyDowns: row[HuntMatchColumns.teamEnemyDowns] as int,
        ownDeaths: row[HuntMatchColumns.ownDeaths] as int,
        teamDeaths: row[HuntMatchColumns.teamDeaths] as int,
        ownEnemyDeaths: row[HuntMatchColumns.ownEnemyDeaths] as int,
        teamEnemyDeaths: row[HuntMatchColumns.teamEnemyDeaths] as int,
        ownAssists: row[HuntMatchColumns.ownAssists] as int,
        outdated: row[HuntMatchColumns.outdated] as int == 1,
        extracted: row[HuntMatchColumns.extracted] as int == 1,
        teamId: row[HuntMatchColumns.teamId] as String,
        signature: row[HuntMatchColumns.signature] as String,
        date: DateTime.fromMillisecondsSinceEpoch(
            row[HuntMatchColumns.date] as int),
      );

      entity.id = row[HuntMatchColumns.id] as int;
      return entity;
    }

    return null;
  }

  Future<void> insertHuntMatch(HuntMatchHeader entity) async {
    final db = await database;

    final values = <String, Object?>{};
    values[HuntMatchColumns.date] = entity.date.millisecondsSinceEpoch;
    values[HuntMatchColumns.mode] = entity.mode;
    values[HuntMatchColumns.teams] = entity.teams;
    values[HuntMatchColumns.teamSize] = entity.teamSize;
    values[HuntMatchColumns.teamMmr] = entity.teamMmr;
    values[HuntMatchColumns.ownDowns] = entity.ownDowns;
    values[HuntMatchColumns.teamDowns] = entity.teamDowns;
    values[HuntMatchColumns.ownEnemyDowns] = entity.ownEnemyDowns;
    values[HuntMatchColumns.teamEnemyDowns] = entity.teamEnemyDowns;
    values[HuntMatchColumns.ownDeaths] = entity.ownDeaths;
    values[HuntMatchColumns.teamDeaths] = entity.teamDeaths;
    values[HuntMatchColumns.ownEnemyDeaths] = entity.ownEnemyDeaths;
    values[HuntMatchColumns.teamEnemyDeaths] = entity.teamEnemyDeaths;
    values[HuntMatchColumns.ownAssists] = entity.ownAssists;
    values[HuntMatchColumns.outdated] = entity.outdated ? 1 : 0;
    values[HuntMatchColumns.teamOutdated] = entity.teamOutdated ? 1 : 0;
    values[HuntMatchColumns.extracted] = entity.extracted ? 1 : 0;
    values[HuntMatchColumns.teamId] = entity.teamId;
    values[HuntMatchColumns.signature] = entity.signature;

    final id = await db.insert(HuntMatchColumns.table, values,
        conflictAlgorithm: ConflictAlgorithm.ignore);
    entity.id = id;
  }

  FutureOr<void> _onCreate(Database db, int version) async {
    await db.execute('CREATE TABLE [${HuntMatchColumns.table}] ('
        '[${HuntMatchColumns.id}]	INTEGER PRIMARY KEY AUTOINCREMENT,'
        '[${HuntMatchColumns.date}]	INTEGER NOT NULL,'
        '[${HuntMatchColumns.mode}]	INTEGER NOT NULL,'
        '[${HuntMatchColumns.teams}]	INTEGER NOT NULL,'
        '[${HuntMatchColumns.teamSize}]	INTEGER NOT NULL,'
        '[${HuntMatchColumns.teamMmr}]	INTEGER NOT NULL,'
        '[${HuntMatchColumns.ownDowns}]	INTEGER NOT NULL,'
        '[${HuntMatchColumns.teamDowns}]	INTEGER NOT NULL,'
        '[${HuntMatchColumns.ownEnemyDowns}]	INTEGER NOT NULL,'
        '[${HuntMatchColumns.teamEnemyDowns}]	INTEGER NOT NULL,'
        '[${HuntMatchColumns.ownDeaths}]	INTEGER NOT NULL,'
        '[${HuntMatchColumns.teamDeaths}]	INTEGER NOT NULL,'
        '[${HuntMatchColumns.ownEnemyDeaths}]	INTEGER NOT NULL,'
        '[${HuntMatchColumns.teamEnemyDeaths}]	INTEGER NOT NULL,'
        '[${HuntMatchColumns.ownAssists}]	INTEGER NOT NULL,'
        '[${HuntMatchColumns.outdated}]	INTEGER NOT NULL,'
        '[${HuntMatchColumns.teamOutdated}]	INTEGER NOT NULL,'
        '[${HuntMatchColumns.extracted}]	INTEGER NOT NULL,'
        '[${HuntMatchColumns.teamId}]	TEXT NOT NULL,'
        '[${HuntMatchColumns.signature}]	TEXT NOT NULL UNIQUE);');

    await db.execute('CREATE TABLE [${HuntPlayerColumns.table}] ('
        '[${HuntMatchColumns.id}]	INTEGER PRIMARY KEY AUTOINCREMENT,'
        '[${HuntPlayerColumns.matchId}]	INTEGER NOT NULL,'
        '[${HuntPlayerColumns.teammate}]	INTEGER NOT NULL,'
        '[${HuntPlayerColumns.teamIndex}]	INTEGER NOT NULL,'
        '[${HuntPlayerColumns.teamId}]	TEXT NOT NULL,'
        '[${HuntPlayerColumns.profileId}]	INTEGER NOT NULL,'
        '[${HuntPlayerColumns.username}]	TEXT NOT NULL,'
        '[${HuntPlayerColumns.bountyExtracted}]	INTEGER NOT NULL,'
        '[${HuntPlayerColumns.bountyPickedup}]	INTEGER NOT NULL,'
        '[${HuntPlayerColumns.downedByMe}]	INTEGER NOT NULL,'
        '[${HuntPlayerColumns.downedByTeam}]	INTEGER NOT NULL,'
        '[${HuntPlayerColumns.downedMe}]	INTEGER NOT NULL,'
        '[${HuntPlayerColumns.downedTeam}]	INTEGER NOT NULL,'
        '[${HuntPlayerColumns.hadWellspring}]	INTEGER NOT NULL,'
        '[${HuntPlayerColumns.soulSurvivor}]	INTEGER NOT NULL,'
        '[${HuntPlayerColumns.killedByMe}]	INTEGER NOT NULL,'
        '[${HuntPlayerColumns.killedByTeam}]	INTEGER NOT NULL,'
        '[${HuntPlayerColumns.killedMe}]	INTEGER NOT NULL,'
        '[${HuntPlayerColumns.killedTeam}]	INTEGER NOT NULL,'
        '[${HuntPlayerColumns.mmr}]	INTEGER NOT NULL,'
        '[${HuntPlayerColumns.voiceToMe}]	INTEGER NOT NULL,'
        '[${HuntPlayerColumns.voiceToTeam}]	INTEGER NOT NULL,'
        '[${HuntPlayerColumns.teamExtraction}]	INTEGER NOT NULL,'
        '[${HuntPlayerColumns.skillBased}]	INTEGER NOT NULL,'
        'CONSTRAINT fk_match FOREIGN KEY ([${HuntPlayerColumns.matchId}]) REFERENCES [${HuntMatchColumns.table}] ([${HuntMatchColumns.id}]) ON DELETE CASCADE,'
        'UNIQUE([${HuntPlayerColumns.matchId}],[${HuntPlayerColumns.profileId}]));');
  }

  FutureOr<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE ${HuntMatchColumns.table} '
          'ADD COLUMN ${HuntMatchColumns.teamOutdated} '
          'INTEGER NOT NULL DEFAULT 0;');

      await db.execute('UPDATE ${HuntMatchColumns.table} '
          'SET ${HuntMatchColumns.teamOutdated} = ${HuntMatchColumns.outdated};');

      await db.execute('ALTER TABLE ${HuntMatchColumns.table} '
          'ALTER COLUMN ${HuntMatchColumns.teamOutdated} '
          'DROP DEFAULT;');
    }
  }
}

extension _MapExt on Map<String, Object?> {
  int intOf(String column) => this[column] as int? ?? 0;
}
