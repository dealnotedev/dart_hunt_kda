import 'package:hunt_stats/db/entities.dart';
import 'package:hunt_stats/db/stats_db.dart';
import 'package:hunt_stats/parser/models.dart';

extension MatchDataExt on HuntMatchData {
  Future<MatchEntity> toEntity(StatsDb db,
      {required bool teamOutdated, required bool outdated}) async {
    final List<PlayerEntity> hunters = [];

    for (HuntPlayer player in players) {
      hunters.add(await player.toEntity(db));
    }

    return MatchEntity(
        match: header.toEntity(teamOutdated: teamOutdated, outdated: outdated),
        players: hunters);
  }
}

extension MatchHeaderExt on HuntMatchHeader {
  MatchHeaderEntity toEntity(
      {required bool teamOutdated, required bool outdated}) {
    return MatchHeaderEntity(
        isInvite: isInvite,
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
  Future<PlayerEntity> toEntity(StatsDb db) async {
    return PlayerEntity(
        teammate: teammate,
        teamIndex: teamIndex,
        profileId: profileId,
        username: username.isEmpty
            ? await db.findPlayerName(profileId, fallback: '')
            : username,
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
