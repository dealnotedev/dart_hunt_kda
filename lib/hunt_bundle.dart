import 'package:hunt_stats/db/entities.dart';
import 'package:hunt_stats/db/stats.dart';

class HuntBundle {
  final PlayerEntity? me;

  final MatchEntity match;

  final OwnStats ownStats;

  final OwnStats? previousOwnStats;

  final TeamStats teamStats;

  final TeamStats? previousTeamStats;

  final MatchEntity? previousMatch;

  final List<EnemyStats> enemyStats;

  final DateTime? from;

  HuntBundle(
      {required this.match,
      required this.me,
      required this.ownStats,
      required this.enemyStats,
      required this.teamStats,
      required this.from,
      required this.previousOwnStats,
      required this.previousTeamStats,
      required this.previousMatch});

  String get teamId => match.match.teamId;

  int? get totalKillsChanges =>
      _intDiff(previousOwnStats?.totalKills, ownStats.totalKills);

  static int? _intDiff(int? previous, int current) =>
      (previous != null && previous != current) ? current - previous : null;

  int? get totalDeathsChanges =>
      _intDiff(previousOwnStats?.totalDeaths, ownStats.totalDeaths);

  int? get ownKillsChanges =>
      _intDiff(previousOwnStats?.ownKills, ownStats.ownKills);

  int? get ownDeatchChanges =>
      _intDiff(previousOwnStats?.ownDeaths, ownStats.ownDeaths);

  int? get ownAssistsChanges =>
      _intDiff(previousOwnStats?.ownAssists, ownStats.ownAssists);

  int? get teamKillsChanges =>
      _intDiff(previousTeamStats?.teamKills, teamStats.teamKills);

  int? get teamDeathsChanges =>
      _intDiff(previousTeamStats?.teamDeaths, teamStats.teamDeaths);

  double? get teamKdChanges {
    final prev = previousTeamStats?.kd;
    return prev != null && prev.isFinite ? teamStats.kd - prev : null;
  }

  double? get kdaChanges {
    final prev = previousOwnStats?.kda;
    return prev != null && prev.isFinite ? ownStats.kda - prev : null;
  }
}
