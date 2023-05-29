import 'package:hunt_stats/db/entities.dart';

class MatchData {
  final HuntMatchHeader match;

  final List<HuntPlayer> players;

  MatchData({required this.match, required this.players});
}
