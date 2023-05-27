import 'package:hunt_stats/db/stats.dart';
import 'package:hunt_stats/match_data.dart';

class HuntBundle {
  final MatchData match;

  final OwnStats ownStats;

  final TeamStats teamStats;

  HuntBundle(
      {required this.match, required this.ownStats, required this.teamStats});
}
