class HuntBundle {
  final int kills;

  final int deaths;

  final int currentMatchKills;

  final int currentMatchDeaths;

  final int matches;

  HuntBundle(
      {required this.kills,
      required this.deaths,
      required this.currentMatchDeaths,
      required this.currentMatchKills,
      required this.matches});

  double get kd => kills.toDouble() / deaths.toDouble();

  int? get killsChanges => currentMatchKills > 0 ? currentMatchKills : null;

  int? get deatchChanges => currentMatchDeaths > 0 ? currentMatchDeaths : null;

  double? get kdaChanges {
    final killsBefore = kills - currentMatchKills;
    final deathsBefore = deaths - currentMatchDeaths;

    final kdBefore = killsBefore.toDouble() / deathsBefore.toDouble();
    final kdCurrent = kills.toDouble() / deaths.toDouble();

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

  HuntBundle add({required int kills, required int deaths}) {
    return HuntBundle(
        matches: matches,
        kills: this.kills + kills,
        deaths: this.deaths + deaths,
        currentMatchDeaths: currentMatchDeaths + deaths,
        currentMatchKills: currentMatchKills + kills);
  }

  HuntBundle resetMatchData() {
    return HuntBundle(
        kills: kills,
        matches: matches + 1,
        deaths: deaths,
        currentMatchDeaths: 0,
        currentMatchKills: 0);
  }
}
