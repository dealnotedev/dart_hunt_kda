import 'package:hunt_stats/db/entities.dart';

class OwnStats {
  final int ownKills;

  final int ownDeaths;

  final int ownAssists;

  final int teamKills;

  final int teamDeaths;

  final int matches;

  OwnStats(
      {required this.ownKills,
      required this.ownDeaths,
      required this.teamKills,
      required this.teamDeaths,
      required this.matches,
      required this.ownAssists});

  int get totalKills => ownKills + teamKills;

  int get totalDeaths => ownDeaths + teamDeaths;

  double get kda => (ownKills + ownAssists).toDouble() / ownDeaths.toDouble();
}

class TeamStats {
  final int teamKills;

  final int teamDeaths;

  final int matches;

  TeamStats(
      {required this.teamKills,
      required this.teamDeaths,
      required this.matches});

  double get kd => teamKills.toDouble() / teamDeaths.toDouble();
}

class EnemyStats {
  final HuntPlayer player;
  final int killedMe;
  final int killedByMe;
  final int matches;

  final int killedMeLastMatch;
  final int killedByMeLastMatch;

  EnemyStats(
      {required this.player,
      required this.killedMe,
        required this.matches,
        required this.killedByMeLastMatch,
        required this.killedMeLastMatch,
      required this.killedByMe});
}
