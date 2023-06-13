class HuntMatchColumns {
  static const String table = 'hunt_matches';

  static const String id = '_id';

  static const String date = 'date';
  static const String mode = 'mode';
  static const String teams = 'teams';
  static const String teamSize = 'team_size';
  static const String teamMmr = 'teamMmr';
  static const String ownDowns = 'own_downs';
  static const String teamDowns = 'team_downs';
  static const String ownEnemyDowns = 'own_enemy_downs';
  static const String teamEnemyDowns = 'team_enemy_downs';
  static const String ownDeaths = 'own_deaths';
  static const String teamDeaths = 'team_deaths';
  static const String ownEnemyDeaths = 'own_enemy_deaths';
  static const String teamEnemyDeaths = 'team_enemy_deaths';
  static const String ownAssists = 'own_assists';
  static const String outdated = 'outdated';
  static const String teamOutdated = 'team_outdated';
  static const String extracted = 'extracted';
  static const String teamId = 'team_id';
  static const String signature = 'signature';

  static const String killGrunts = 'kill_grunts';
  static const String killHives = 'kill_hives';
  static const String killImmolators = 'kill_immolators';
  static const String killArmored = 'kill_armored';
  static const String killHorses = 'kill_horses';
  static const String killHellhound = 'kill_hellhounds';
  static const String killMeatheads = 'kill_meathead';
  static const String killLeeches = 'kill_leeches';
  static const String killWaterdevils = 'kill_waterdevils';

  static const String moneyFound = 'money_found';
  static const String bountyFound = 'bounty_found';
  static const String bondsFound = 'bonds_found';

  static const String teammateRevives = 'teammate_revives';
}

class HuntPlayerColumns {
  static const String table = 'hunt_players';
  static const String id = '_id';

  static const String matchId = 'match_id';
  static const String teamId = 'team_id';
  static const String teammate = 'teammate';
  static const String teamIndex = 'team_index';
  static const String profileId = 'profile_id';
  static const String username = 'username';
  static const String bountyExtracted = 'bounty_extracted';
  static const String bountyPickedup = 'bounty_pickedup';
  static const String downedByMe = 'downed_by_me';
  static const String downedByTeam = 'downed_by_team';
  static const String downedMe = 'downed_me';
  static const String downedTeam = 'downed_team';
  static const String hadWellspring = 'had_wellspring';
  static const String soulSurvivor = 'soul_survivor';
  static const String killedByMe = 'killed_by_me';
  static const String killedByTeam = 'killed_by_team';
  static const String killedMe = 'killed_me';
  static const String killedTeam = 'killed_team';
  static const String mmr = 'mmr';
  static const String voiceToMe = 'voice_to_me';
  static const String voiceToTeam = 'voice_to_team';
  static const String teamExtraction = 'team_extraction';
  static const String skillBased = 'skill_based';
}
