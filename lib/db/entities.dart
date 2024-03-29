class MatchEntity {
  final MatchHeaderEntity match;

  final List<PlayerEntity> players;

  MatchEntity({required this.match, required this.players});
}

class MatchHeaderEntity {
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
  final bool teamOutdated;
  final bool extracted;
  final String teamId;
  final String signature;

  final int killGrunts;
  final int killHives;
  final int killImmolators;
  final int killArmored;
  final int killHorses;
  final int killHellhound;
  final int killMeatheads;
  final int killLeeches;
  final int killWaterdevils;

  final int moneyFound;
  final int bountyFound;
  final int bondsFound;
  final int teammateRevives;

  final bool isInvite;

  MatchHeaderEntity(
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
      required this.teamOutdated,
      required this.outdated,
      required this.extracted,
      required this.teamId,
      required this.signature,
      required this.date,
      required this.killArmored,
      required this.killLeeches,
      required this.killGrunts,
      required this.killHellhound,
      required this.killHives,
      required this.killHorses,
      required this.killImmolators,
      required this.killMeatheads,
      required this.killWaterdevils,
      required this.moneyFound,
      required this.bountyFound,
      required this.bondsFound,
      required this.teammateRevives,
      required this.isInvite});

  int get totalOwnEnemyDeathsDowns => ownEnemyDowns + ownEnemyDeaths;

  int get totalOwnDeathsDowns => ownDeaths + ownDowns;

  int get totalEnemyDeathsDowns =>
      ownEnemyDeaths + ownEnemyDowns + teamEnemyDowns + teamEnemyDeaths;

  int get totalDeathsDowns => ownDeaths + ownDowns + teamDowns + teamDeaths;
}

class PlayerEntity {
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

  PlayerEntity(
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
