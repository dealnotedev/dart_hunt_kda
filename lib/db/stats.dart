class OwnStats {
  final int ownKills;

  final int ownDeaths;

  final int ownAssists;

  OwnStats(
      {required this.ownKills,
      required this.ownDeaths,
      required this.ownAssists});

  @override
  String toString() {
    return 'Stats{ownKills: $ownKills, ownDeaths: $ownDeaths, ownAssists: $ownAssists}';
  }
}

class TeamStats {
  final int teamKills;

  final int teamDeaths;

  TeamStats({required this.teamKills, required this.teamDeaths});

  @override
  String toString() {
    return 'TeamStats{teamKills: $teamKills, teamDeaths: $teamDeaths}';
  }
}
