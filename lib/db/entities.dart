class HuntMatchHeader {
  late final int id;

  final DateTime date;
  final int mode;
  final int teams;
  final int teamSize;
  final int teamMmr;
  final int ownDowns;
  final int teamDowns;
  final int ownEnemyDowns;
  final int teamEnemyDowns;
  final int ownDeaths;
  final int teamDeaths;
  final int ownEnemyDeaths;
  final int teamEnemyDeaths;
  final int ownAssists;
  final bool outdated;
  final bool extracted;
  final String teamId;
  final String signature;

  HuntMatchHeader(
      {required this.mode,
      required this.teams,
      required this.teamSize,
      required this.teamMmr,
      required this.ownDowns,
      required this.teamDowns,
      required this.ownEnemyDowns,
      required this.teamEnemyDowns,
      required this.ownDeaths,
      required this.teamDeaths,
      required this.ownEnemyDeaths,
      required this.teamEnemyDeaths,
      required this.ownAssists,
      required this.outdated,
      required this.extracted,
      required this.teamId,
      required this.signature,
      required this.date});
}

class HuntPlayer {
  late final int id;
  late final int matchId;
  late final String teamId;

  final bool teammate;
  final int teamIndex;
  final int profileId;
  final String username;
  final int bountyExtracted;
  final int bountyPickedup;
  final int downedByMe;
  final int downedByTeam;
  final int downedMe;
  final int downedTeam;
  final bool hadWellspring;
  final bool soulSurvivor;
  final int killedByMe;
  final int killedByTeam;
  final int killedMe;
  final int killedTeam;
  final int mmr;
  final bool voiceToMe;
  final bool voiceToTeam;
  final bool teamExtraction;
  final bool skillBased;

  bool get hasMutuallyKillDowns =>
      killedByMe > 0 || killedMe > 0 || downedMe > 0 || downedByMe > 0;

  HuntPlayer(
      {required this.teammate,
      required this.teamIndex,
      required this.profileId,
      required this.username,
      required this.bountyExtracted,
      required this.bountyPickedup,
      required this.downedByMe,
      required this.downedByTeam,
      required this.downedMe,
      required this.downedTeam,
      required this.hadWellspring,
      required this.soulSurvivor,
      required this.killedByMe,
      required this.killedByTeam,
      required this.killedMe,
      required this.killedTeam,
      required this.mmr,
      required this.voiceToMe,
      required this.voiceToTeam,
      required this.teamExtraction,
      required this.skillBased});
}
