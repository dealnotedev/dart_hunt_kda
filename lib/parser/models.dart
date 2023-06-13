import 'package:json_annotation/json_annotation.dart';

part 'models.g.dart';

@JsonSerializable(explicitToJson: true)
class HuntMatchData {
  final HuntMatchHeader header;

  final List<HuntPlayer> players;

  HuntMatchData({required this.header, required this.players});

  factory HuntMatchData.fromJson(Map<String, dynamic> json) =>
      _$HuntMatchDataFromJson(json);

  Map<String, dynamic> toJson() => _$HuntMatchDataToJson(this);
}

@JsonSerializable(explicitToJson: true)
class HuntMatchHeader {
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
      required this.teammateRevives});

  factory HuntMatchHeader.fromJson(Map<String, dynamic> json) =>
      _$HuntMatchHeaderFromJson(json);

  Map<String, dynamic> toJson() => _$HuntMatchHeaderToJson(this);
}

@JsonSerializable(explicitToJson: true)
class HuntPlayer {
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

  factory HuntPlayer.fromJson(Map<String, dynamic> json) =>
      _$HuntPlayerFromJson(json);

  Map<String, dynamic> toJson() => _$HuntPlayerToJson(this);
}
