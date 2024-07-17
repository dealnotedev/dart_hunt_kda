class HuntBundle {
  final int kills;

  final int deaths;

  final int currentMatchKills;

  final int currentMatchDeaths;

  final int currentMatchAssists;

  final int matches;

  final int assists;

  HuntBundle(
      {required this.kills,
      required this.deaths,
      required this.currentMatchDeaths,
      required this.currentMatchKills,
      required this.currentMatchAssists,
      required this.assists,
      required this.matches});

  double get kd => (kills + assists).toDouble() / deaths.toDouble();

  int? get killsChanges => currentMatchKills > 0 ? currentMatchKills : null;

  int? get assistsChanges =>
      currentMatchAssists > 0 ? currentMatchAssists : null;

  int? get deatchChanges => currentMatchDeaths > 0 ? currentMatchDeaths : null;

  double? get kdaChanges {
    final killsBefore = kills - currentMatchKills;
    final deathsBefore = deaths - currentMatchDeaths;
    final assistsBefore = assists - currentMatchAssists;

    final kdBefore =
        (killsBefore + assistsBefore).toDouble() / deathsBefore.toDouble();
    final kdCurrent = (kills + assists).toDouble() / deaths.toDouble();

    if (kdBefore.isFinite &&
        kdBefore > 0 &&
        kdCurrent.isFinite &&
        kdCurrent > 0 &&
        kdCurrent != kdBefore) {
      return kdCurrent - kdBefore;
    } else {
      return null;
    }
  }

  HuntBundle addAssist({required int assists}) {
    return HuntBundle(
        kills: kills,
        deaths: deaths,
        currentMatchDeaths: currentMatchDeaths,
        currentMatchKills: currentMatchKills,
        currentMatchAssists: currentMatchAssists + assists,
        assists: this.assists + assists,
        matches: matches);
  }

  HuntBundle add({required int kills, required int deaths}) {
    return HuntBundle(
        matches: matches,
        assists: assists,
        kills: this.kills + kills,
        deaths: this.deaths + deaths,
        currentMatchAssists: currentMatchAssists,
        currentMatchDeaths: currentMatchDeaths + deaths,
        currentMatchKills: currentMatchKills + kills);
  }

  HuntBundle resetMatchData() {
    return HuntBundle(
        kills: kills,
        matches: matches + 1,
        deaths: deaths,
        assists: assists,
        currentMatchAssists: 0,
        currentMatchDeaths: 0,
        currentMatchKills: 0);
  }
}
