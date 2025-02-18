class HuntBundle {
  final int kills;

  final int deaths;

  final int currentMatchKills;

  final int currentMatchDeaths;

  final int currentMatchAssists;

  final int matches;

  final int assists;

  final List<bool> history;

  HuntBundle(
      {required this.kills,
      required this.deaths,
      required this.history,
      required this.currentMatchDeaths,
      required this.currentMatchKills,
      required this.currentMatchAssists,
      required this.assists,
      required this.matches});

  int get totalKills => kills + currentMatchKills;

  int get totalDeaths => deaths + currentMatchDeaths;

  int get totalAssists => assists + currentMatchAssists;

  double get kda =>
      (totalKills + totalAssists).toDouble() / totalDeaths.toDouble();

  int? get killsChanges => currentMatchKills > 0 ? currentMatchKills : null;

  int? get assistsChanges =>
      currentMatchAssists > 0 ? currentMatchAssists : null;

  int? get deatchChanges => currentMatchDeaths > 0 ? currentMatchDeaths : null;

  double? get kdaChanges {
    final killsBefore = kills;
    final deathsBefore = deaths;
    final assistsBefore = assists;

    final kdBefore =
        (killsBefore + assistsBefore).toDouble() / deathsBefore.toDouble();

    final kdCurrent =
        (totalKills + totalAssists).toDouble() / totalDeaths.toDouble();

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

  int get losses => history.where((r) => !r).length;

  int get extracted => history.where((r) => r).length;

  HuntBundle addMatchResult({required bool success}) {
    return HuntBundle(
        kills: kills,
        deaths: deaths,
        history: List.of(history)..add(success),
        currentMatchDeaths: currentMatchDeaths,
        currentMatchKills: currentMatchKills,
        currentMatchAssists: currentMatchAssists,
        assists: assists,
        matches: matches);
  }

  HuntBundle addAssist({required int assists}) {
    return HuntBundle(
        kills: kills,
        deaths: deaths,
        history: history,
        currentMatchDeaths: currentMatchDeaths,
        currentMatchKills: currentMatchKills,
        currentMatchAssists: currentMatchAssists + assists,
        assists: this.assists,
        matches: matches);
  }

  HuntBundle setAssists({required int assists}) {
    return HuntBundle(
        kills: kills,
        deaths: deaths,
        history: history,
        currentMatchDeaths: currentMatchDeaths,
        currentMatchKills: currentMatchKills,
        currentMatchAssists: assists,
        assists: this.assists,
        matches: matches);
  }

  HuntBundle add({required int kills, required int deaths}) {
    return HuntBundle(
        matches: matches,
        assists: assists,
        kills: this.kills,
        deaths: this.deaths,
        history: history,
        currentMatchAssists: currentMatchAssists,
        currentMatchDeaths: currentMatchDeaths + deaths,
        currentMatchKills: currentMatchKills + kills);
  }

  HuntBundle resetMatchData() {
    return HuntBundle(
        kills: kills + currentMatchKills,
        matches: matches + 1,
        deaths: deaths + currentMatchDeaths,
        assists: assists + currentMatchAssists,
        history: history,
        currentMatchAssists: 0,
        currentMatchDeaths: 0,
        currentMatchKills: 0);
  }
}
