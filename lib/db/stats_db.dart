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
            version: 1, singleInstance: true, onCreate: _onCreate));
  }

  Future<void> insertHuntMatchPlayers(
      Iterable<HuntPlayer> entities) async {
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
        'sum(${HuntMatchColumns.teamEnemyDeaths}) as team_enemy_deaths, '
        'sum(${HuntMatchColumns.teamEnemyDowns}) as team_enemy_downs '
        'FROM ${HuntMatchColumns.table} '
        'WHERE ${HuntMatchColumns.teamId} LIKE ?',
        [teamId]);
    final row = cursor[0];

    return TeamStats(
        teamKills: (row['team_enemy_deaths'] as int) +
            (row['team_enemy_downs'] as int),
        teamDeaths: (row['team_deaths'] as int) + (row['team_downs'] as int));
  }

  Future<OwnStats> getOwnStats() async {
    final db = await database;

    final cursor = await db.rawQuery(
        'SELECT '
        'sum(${HuntMatchColumns.ownEnemyDowns}) as own_enemy_downs, '
        'sum(${HuntMatchColumns.ownEnemyDeaths}) as own_enemy_deaths, '
        'sum(${HuntMatchColumns.ownDeaths}) as own_deaths, '
        'sum(${HuntMatchColumns.ownDowns}) as own_downs, '
        'sum(${HuntMatchColumns.ownAssists}) as own_assists '
        'FROM ${HuntMatchColumns.table} '
        'WHERE ${HuntMatchColumns.outdated} = ?',
        [0]);
    final row = cursor[0];
    return OwnStats(
        ownKills:
            (row['own_enemy_downs'] as int) + (row['own_enemy_deaths'] as int),
        ownDeaths: (row['own_deaths'] as int) + (row['own_downs'] as int),
        ownAssists: row['own_assists'] as int);
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
}
