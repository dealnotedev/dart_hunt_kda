import 'package:hunt_stats/db/entities.dart';
import 'package:hunt_stats/parser/models.dart';

extension MatchDataExt on HuntMatchData {
  MatchEntity toEntity({required bool teamOutdated, required bool outdated}) {
    return MatchEntity(
        match: header.toEntity(teamOutdated: teamOutdated, outdated: outdated),
        players: players.map((e) => e.toEntity()).toList());
  }
}

extension MatchHeaderExt on HuntMatchHeader {
  MatchHeaderEntity toEntity(
      {required bool teamOutdated, required bool outdated}) {
    return MatchHeaderEntity(
        mode: mode,
        teams: teams,
        teamSize: teamSize,
        teamMmr: teamMmr,
        ownDowns: ownDowns,
        teamDowns: teamDowns,
        ownEnemyDowns: ownEnemyDowns,
        teamEnemyDowns: teamEnemyDowns,
        ownDeaths: ownDeaths,
        teamDeaths: teamDeaths,
        ownEnemyDeaths: ownEnemyDeaths,
        teamEnemyDeaths: teamEnemyDeaths,
        ownAssists: ownAssists,
        teamOutdated: teamOutdated,
        outdated: outdated,
        extracted: extracted,
        teamId: teamId,
        signature: signature,
        date: date,
        killArmored: killArmored,
        killLeeches: killLeeches,
        killGrunts: killGrunts,
        killHellhound: killHellhound,
        killHives: killHives,
        killHorses: killHorses,
        killImmolators: killImmolators,
        killMeatheads: killMeatheads,
        killWaterdevils: killWaterdevils,
        moneyFound: moneyFound,
        bountyFound: bountyFound,
        bondsFound: bondsFound,
        teammateRevives: teammateRevives);
  }
}

extension PlayerExt on HuntPlayer {
  PlayerEntity toEntity() {
    return PlayerEntity(
        teammate: teammate,
        teamIndex: teamIndex,
        profileId: profileId,
        username: username,
        bountyExtracted: bountyExtracted,
        bountyPickedup: bountyPickedup,
        downedByMe: downedByMe,
        downedByTeam: downedByTeam,
        downedMe: downedMe,
        downedTeam: downedTeam,
        hadWellspring: hadWellspring,
        soulSurvivor: soulSurvivor,
        killedByMe: killedByMe,
        killedByTeam: killedByTeam,
        killedMe: killedMe,
        killedTeam: killedTeam,
        mmr: mmr,
        voiceToMe: voiceToMe,
        voiceToTeam: voiceToTeam,
        teamExtraction: teamExtraction,
        skillBased: skillBased);
  }
}
