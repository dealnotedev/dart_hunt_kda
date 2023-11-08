// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HuntMatchData _$HuntMatchDataFromJson(Map<String, dynamic> json) =>
    HuntMatchData(
      header: HuntMatchHeader.fromJson(json['header'] as Map<String, dynamic>),
      players: (json['players'] as List<dynamic>)
          .map((e) => HuntPlayer.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$HuntMatchDataToJson(HuntMatchData instance) =>
    <String, dynamic>{
      'header': instance.header.toJson(),
      'players': instance.players.map((e) => e.toJson()).toList(),
    };

HuntMatchHeader _$HuntMatchHeaderFromJson(Map<String, dynamic> json) =>
    HuntMatchHeader(
      mode: json['mode'] as int,
      teams: json['teams'] as int,
      teamSize: json['teamSize'] as int,
      teamMmr: json['teamMmr'] as int,
      ownDowns: json['ownDowns'] as int,
      teamDowns: json['teamDowns'] as int,
      ownEnemyDowns: json['ownEnemyDowns'] as int,
      teamEnemyDowns: json['teamEnemyDowns'] as int,
      ownDeaths: json['ownDeaths'] as int,
      teamDeaths: json['teamDeaths'] as int,
      ownEnemyDeaths: json['ownEnemyDeaths'] as int,
      teamEnemyDeaths: json['teamEnemyDeaths'] as int,
      ownAssists: json['ownAssists'] as int,
      extracted: json['extracted'] as bool,
      teamId: json['teamId'] as String,
      signature: json['signature'] as String,
      date: DateTime.parse(json['date'] as String),
      killArmored: json['killArmored'] as int,
      killLeeches: json['killLeeches'] as int,
      killGrunts: json['killGrunts'] as int,
      killHellhound: json['killHellhound'] as int,
      killHives: json['killHives'] as int,
      killHorses: json['killHorses'] as int,
      killImmolators: json['killImmolators'] as int,
      killMeatheads: json['killMeatheads'] as int,
      killWaterdevils: json['killWaterdevils'] as int,
      moneyFound: json['moneyFound'] as int,
      bountyFound: json['bountyFound'] as int,
      bondsFound: json['bondsFound'] as int,
      teammateRevives: json['teammateRevives'] as int,
      isInvite: json['isInvite'] as bool,
    );

Map<String, dynamic> _$HuntMatchHeaderToJson(HuntMatchHeader instance) =>
    <String, dynamic>{
      'date': instance.date.toIso8601String(),
      'mode': instance.mode,
      'teams': instance.teams,
      'teamSize': instance.teamSize,
      'teamMmr': instance.teamMmr,
      'ownDowns': instance.ownDowns,
      'teamDowns': instance.teamDowns,
      'ownEnemyDowns': instance.ownEnemyDowns,
      'teamEnemyDowns': instance.teamEnemyDowns,
      'ownDeaths': instance.ownDeaths,
      'teamDeaths': instance.teamDeaths,
      'ownEnemyDeaths': instance.ownEnemyDeaths,
      'teamEnemyDeaths': instance.teamEnemyDeaths,
      'ownAssists': instance.ownAssists,
      'extracted': instance.extracted,
      'teamId': instance.teamId,
      'signature': instance.signature,
      'killGrunts': instance.killGrunts,
      'killHives': instance.killHives,
      'killImmolators': instance.killImmolators,
      'killArmored': instance.killArmored,
      'killHorses': instance.killHorses,
      'killHellhound': instance.killHellhound,
      'killMeatheads': instance.killMeatheads,
      'killLeeches': instance.killLeeches,
      'killWaterdevils': instance.killWaterdevils,
      'moneyFound': instance.moneyFound,
      'bountyFound': instance.bountyFound,
      'bondsFound': instance.bondsFound,
      'teammateRevives': instance.teammateRevives,
      'isInvite': instance.isInvite,
    };

HuntPlayer _$HuntPlayerFromJson(Map<String, dynamic> json) => HuntPlayer(
      teammate: json['teammate'] as bool,
      teamIndex: json['teamIndex'] as int,
      profileId: json['profileId'] as int,
      username: json['username'] as String,
      bountyExtracted: json['bountyExtracted'] as int,
      bountyPickedup: json['bountyPickedup'] as int,
      downedByMe: json['downedByMe'] as int,
      downedByTeam: json['downedByTeam'] as int,
      downedMe: json['downedMe'] as int,
      downedTeam: json['downedTeam'] as int,
      hadWellspring: json['hadWellspring'] as bool,
      soulSurvivor: json['soulSurvivor'] as bool,
      killedByMe: json['killedByMe'] as int,
      killedByTeam: json['killedByTeam'] as int,
      killedMe: json['killedMe'] as int,
      killedTeam: json['killedTeam'] as int,
      mmr: json['mmr'] as int,
      voiceToMe: json['voiceToMe'] as bool,
      voiceToTeam: json['voiceToTeam'] as bool,
      teamExtraction: json['teamExtraction'] as bool,
      skillBased: json['skillBased'] as bool,
    );

Map<String, dynamic> _$HuntPlayerToJson(HuntPlayer instance) =>
    <String, dynamic>{
      'teammate': instance.teammate,
      'teamIndex': instance.teamIndex,
      'profileId': instance.profileId,
      'username': instance.username,
      'bountyExtracted': instance.bountyExtracted,
      'bountyPickedup': instance.bountyPickedup,
      'downedByMe': instance.downedByMe,
      'downedByTeam': instance.downedByTeam,
      'downedMe': instance.downedMe,
      'downedTeam': instance.downedTeam,
      'hadWellspring': instance.hadWellspring,
      'soulSurvivor': instance.soulSurvivor,
      'killedByMe': instance.killedByMe,
      'killedByTeam': instance.killedByTeam,
      'killedMe': instance.killedMe,
      'killedTeam': instance.killedTeam,
      'mmr': instance.mmr,
      'voiceToMe': instance.voiceToMe,
      'voiceToTeam': instance.voiceToTeam,
      'teamExtraction': instance.teamExtraction,
      'skillBased': instance.skillBased,
    };
