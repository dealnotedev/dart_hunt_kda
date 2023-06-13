import 'package:hunt_stats/parser/models.dart';

class MatchData {
  final HuntMatchHeader match;

  final List<HuntPlayer> players;

  MatchData({required this.match, required this.players});
}
