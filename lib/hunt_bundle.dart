import 'package:hunt_stats/db/stats.dart';
import 'package:hunt_stats/match_data.dart';

class HuntBundle {
  final MatchData match;

  final OwnStats ownStats;

  final OwnStats? previousOwnStats;

  final TeamStats teamStats;

  final TeamStats? previousTeamStats;

  final MatchData? previousMatch;

  HuntBundle(
      {required this.match,
      required this.ownStats,
      required this.teamStats,
      required this.previousOwnStats,
      required this.previousTeamStats,
      required this.previousMatch});

  String? get teamId => match.match.teamId;

  int? get ownKillsChanges {
    final prev = previousOwnStats?.ownKills;
    return prev != null ? ownStats.ownKills - prev : null;
  }

  int? get ownDeatchChanges {
    final prev = previousOwnStats?.ownDeaths;
    return prev != null ? ownStats.ownDeaths - prev : null;
  }

  int? get ownAssistsChanges {
    final prev = previousOwnStats?.ownAssists;
    return prev != null ? ownStats.ownAssists - prev : null;
  }

  int? get teamKillsChanges {
    final prev = previousTeamStats?.teamKills;
    return prev != null ? teamStats.teamKills - prev : null;
  }

  int? get teamDeathsChanges {
    final prev = previousTeamStats?.teamDeaths;
    return prev != null ? teamStats.teamDeaths - prev : null;
  }

  double? get teamKdChanges {
    final prev = previousTeamStats?.kd;
    return prev != null ? teamStats.kd - prev : null;
  }

  double? get kdaChanges {
    final prev = previousOwnStats?.kda;
    if (prev != null) {
      return ownStats.kda - prev;
    } else {
      return null;
    }
  }
}