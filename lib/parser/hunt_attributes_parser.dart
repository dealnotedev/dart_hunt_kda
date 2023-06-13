import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:hunt_stats/parser/match_data.dart';
import 'package:hunt_stats/parser/mode.dart';
import 'package:hunt_stats/parser/models.dart';
import 'package:xml/xml.dart';

class HuntAttributesParser {
  Future<MatchData> parseFromFile(File file) async {
    final document = XmlDocument.parse(await file.readAsString());
    final huntData = HuntData();
    huntData._fill(document);

    return huntData.extractMatchData();
  }
}

class HuntData {
  int? numTeams;

  bool? isQuickPlay;

  bool? isHunterDead;

  bool? isTutorial;

  int? missionBagFbeGoldBonus;

  final players = <int,
      Map<int,
          Map<String, PlayerNode>>>{}; // <team, <player_num, [player_values]>>

  final teams = <int, Map<String, TeamNode>>{};
  final bags = <String, BagEntry>{};
  final accolades = <String, Accolade>{};

  MatchData extractMatchData() {
    if (isTutorial ?? false) {
      throw StateError('Skip tutorial');
    }

    final int mode = (isQuickPlay ?? false) ? Mode.quickPlay : Mode.bountyHunt;
    final int teamsCount = numTeams ?? 0;
    if (teamsCount == 0) {
      throw StateError('Zero teams found');
    }

    int ownDowns = 0;
    int teamDowns = 0;

    int ownEnemyDowns = 0;
    int ownEnemyDeaths = 0;

    int teamEnemyDowns = 0;
    int teamEnemyDeaths = 0;

    int ownDeaths = 0;
    int teamDeaths = 0;

    int? ownTeamSize;
    int? ownTeamMmr;

    final int ownAssists = bags['kill player assist']?.amount ?? 0;
    final teamId = <int>[];

    final signature = SignatureBuilder();
    final users = <HuntPlayer>[];

    for (int i = 0; i < teamsCount; i++) {
      final data = teams[i];
      final ownTeam = data?['ownteam']?.node.boolValue ?? false;
      final teamSize = data?['numplayers']?.node.intValue ?? 0;

      if (ownTeam) {
        ownTeamSize = teamSize;
        ownTeamMmr = data?['mmr']?.node.intValue;
      }

      for (int p = 0; p < teamSize; p++) {
        final data = players[i]?[p];

        if (data != null) {
          final player = HuntPlayer(
              teamIndex: i,
              teammate: ownTeam,
              profileId: data['profileid']?.node.intValue ?? 0,
              username: data['blood_line_name']?.node.stringValue ?? '',
              bountyExtracted: data['bountyextracted']?.node.intValue ?? 0,
              bountyPickedup: data['bountypickedup']?.node.intValue ?? 0,
              downedByMe: data['downedbyme']?.node.intValue ?? 0,
              downedByTeam: data['downedbyteammate']?.node.intValue ?? 0,
              downedMe: data['downedme']?.node.intValue ?? 0,
              downedTeam: data['downedteammate']?.node.intValue ?? 0,
              hadWellspring: data['hadWellspring']?.node.boolValue ?? false,
              soulSurvivor: data['issoulsurvivor']?.node.boolValue ?? false,
              killedByMe: data['killedbyme']?.node.intValue ?? 0,
              killedByTeam: data['killedbyteammate']?.node.intValue ?? 0,
              killedMe: data['killedme']?.node.intValue ?? 0,
              killedTeam: data['killedteammate']?.node.intValue ?? 0,
              mmr: data['mmr']?.node.intValue ?? 0,
              voiceToMe: data['proximitytome']?.node.boolValue ?? false,
              voiceToTeam: data['proximitytoteammate']?.node.boolValue ?? false,
              teamExtraction: data['teamextraction']?.node.boolValue ?? false,
              skillBased: data['skillbased']?.node.boolValue ?? false);

          signature.append(player.profileId.toString());
          if (player.teammate) {
            teamId.add(player.profileId);
          }

          ownDowns += player.downedMe;
          teamDowns += player.downedTeam;
          teamEnemyDowns += player.downedByTeam;
          ownEnemyDowns += player.downedByMe;
          ownEnemyDeaths += player.killedByMe;
          teamEnemyDeaths += player.killedByTeam;
          ownDeaths += player.killedMe;
          teamDeaths += player.killedTeam;

          users.add(player);
        } else {
          throw StateError('No player data found');
        }
      }
    }

    teamId.sort();
    if (ownTeamSize == null) {
      throw StateError('No own team size');
    }
    if (ownTeamMmr == null) {
      throw StateError('No own team mmr');
    }

    int money = 0;
    int bounty = 0;
    int bonds = 0;

    for (var accolade in accolades.values) {
      money += accolade.gold ?? 0;
      bounty += accolade.bounty ?? 0;
      bonds += accolade.generatedGems ?? 0;
    }

    final entity = HuntMatchHeader(
        mode: mode,
        teams: teamsCount,
        ownDowns: ownDowns,
        teamDowns: teamDowns,
        ownEnemyDowns: ownEnemyDowns,
        teamEnemyDowns: teamEnemyDowns,
        ownDeaths: ownDeaths,
        teamDeaths: teamDeaths,
        ownEnemyDeaths: ownEnemyDeaths,
        teamEnemyDeaths: teamEnemyDeaths,
        ownAssists: ownAssists,
        outdated: false,
        teamOutdated: false,
        extracted: !(isHunterDead ?? false),
        teamId: teamId.join('-'),
        signature: signature.generate(),
        date: DateTime.now(),
        teamSize: ownTeamSize,
        teamMmr: ownTeamMmr,
        killMeatheads: bags.amountOf('kill meatheads'),
        killImmolators: bags.amountOf('kill immolator'),
        killHorses: bags.amountOf('kill horse'),
        killHives: bags.amountOf('kill hive'),
        killHellhound: bags.amountOf('kill hellhound'),
        killArmored: bags.amountOf('kill armored'),
        killLeeches: bags.amountOf('kill leeches'),
        killWaterdevils: bags.amountOf('kill waterdevil'),
        killGrunts: bags.amountOf('kill grunt'),
        moneyFound: money,
        bountyFound: bounty,
        bondsFound: bonds,
        teammateRevives: bags.amountOf('revive team mate'));

    return MatchData(match: entity, players: users);
  }

  static const rewardBounty = 0;
  static const rewardTypeXp = 2;
  static const rewardTypeMoney = 4;

  static Set<String> extractActionTimes(String? value, String key) {
    if (value == null) return {};

    // Example @ui_mmr_killed_hunter ~~@ui_team_details_downed ~20:13~@ui_team_details_downed ~20:22~@ui_team_details_killed ~20:57

    final result = <String>{};
    final parts = value.split('~');

    for (int i = 0; i < parts.length; i++) {
      if (parts[i].trim() == key) {
        result.add(parts[i + 1]);
      }
    }
    return result;
  }

  void _fill(XmlDocument document) {
    int? missionBagNumEntries;
    int? missionBagNumAccolades;

    final bags = <int, BagEntry>{};
    final accolades = <int, Accolade>{};

    for (var node in document.descendants) {
      final name = node.name;
      if (name == null) {
        continue;
      }

      if (name.startsWith('ActiveSkin') ||
          name.startsWith('ItemsUserData') ||
          name.startsWith('FilterStates') ||
          name.startsWith('Loadout') ||
          name.startsWith('NewsFeed') ||
          name.startsWith('PC_') ||
          name.startsWith('PS4_') ||
          name.startsWith('FilterContainer') ||
          name.startsWith('Xbox_') ||
          name.startsWith('ScreenIntroductions') ||
          name.startsWith('Unlocks') ||
          name.endsWith('_iconPath2') ||
          name.endsWith('_iconPath')) {
        continue;
      }

      switch (name) {
        case 'MissionBagFbeGoldBonus':
          missionBagFbeGoldBonus = node.intValue;
          break;

        case 'MissionBagNumTeams':
          numTeams = node.intValue;
          break;

        case 'MissionBagIsQuickPlay':
          isQuickPlay = node.boolValue;
          break;

        case 'MissionBagIsHunterDead':
          isHunterDead = node.boolValue;
          break;

        case 'MissionBagIsTutorial':
          isTutorial = node.boolValue;
          break;

        case 'MissionBagNumEntries':
          missionBagNumEntries = node.intValue;
          break;

        case 'MissionBagNumAccolades':
          missionBagNumAccolades = node.intValue;
          break;

        default:
          if (name.startsWith('MissionBagPlayer_')) {
            final parts = name.split('_');
            final playerNode = PlayerNode(
                team: int.parse(parts[1]),
                index: int.parse(parts[2]),
                node: node,
                suffix: _joinPartsAfter(parts, 3));

            final map = players
                .putIfAbsent(playerNode.team, () => {})
                .putIfAbsent(playerNode.index, () => {});
            map.addEntries([MapEntry(playerNode.suffix, playerNode)]);
            continue;
          }

          if (name.startsWith('MissionBagTeam_')) {
            final parts = name.split('_');
            final teamNode = TeamNode(
                team: int.parse(parts[1]),
                suffix: _joinPartsAfter(parts, 2),
                node: node);
            teams
                .putIfAbsent(teamNode.team, () => {})
                .addEntries([MapEntry(teamNode.suffix, teamNode)]);
            continue;
          }

          if (name.startsWith('MissionBagEntry_')) {
            final parts = name.split('_');
            final index = int.parse(parts[1]);
            final entry = bags.putIfAbsent(index, () => BagEntry());

            if (parts.length > 2) {
              switch (parts[2]) {
                case 'amount':
                  entry.amount = node.intValue;
                  break;
                case 'category':
                  entry.category = node.stringValue;
                  break;
                case 'descriptorName':
                  entry.descriptor = node.stringValue;
                  break;
                case 'reward':
                  entry.rewardType = node.intValue;
                  break;
                case 'rewardSize':
                  entry.rewardAmount = node.intValue;
                  break;
              }
            }
            continue;
          }

          if (name.startsWith('MissionAccoladeEntry_')) {
            final parts = name.split('_');
            final index = int.parse(parts[1]);
            final entry = accolades.putIfAbsent(index, () => Accolade());

            if (parts.length > 2) {
              switch (parts[2]) {
                case 'bloodlineXp':
                  entry.bloodlineXp = node.intValue;
                  break;
                case 'bounty':
                  entry.bounty = node.intValue;
                  break;
                case 'category':
                  entry.category = node.stringValue;
                  break;
                case 'eventPoints':
                  entry.eventPoints = node.intValue;
                  break;
                case 'gems':
                  entry.gems = node.intValue;
                  break;
                case 'generatedGems':
                  entry.generatedGems = node.intValue;
                  break;
                case 'gold':
                  entry.gold = node.intValue;
                  break;
                case 'hits':
                  entry.hits = node.intValue;
                  break;
                case 'hunterPoints':
                  entry.hunterPoints = node.intValue;
                  break;
                case 'hunterXp':
                  entry.hunterXp = node.intValue;
                  break;
                case 'weighting':
                  entry.weighting = node.intValue;
                  break;
                case 'xp':
                  entry.xp = node.intValue;
                  break;
              }
            }
            continue;
          }
          break;
      }
    }

    for (int i = 0; i < (missionBagNumEntries ?? 0); i++) {
      final bag = bags[i];
      final descriptor = bag?.descriptor;

      if (bag != null && descriptor != null) {
        this.bags[descriptor] = bag;
      }
    }

    for (int i = 0; i < (missionBagNumAccolades ?? 0); i++) {
      final accolade = accolades[i];
      final category = accolade?.category;

      if (accolade != null && category != null) {
        this.accolades[category] = accolade;
      }
    }
  }

  static String _joinPartsAfter(List<String> parts, int after) {
    return parts.sublist(after).join('_');
  }
}

extension BagEntriesExt on Map<String, BagEntry> {
  int amountOf(String name, {int fallback = 0}) =>
      this[name]?.amount ?? fallback;
}

class BagEntry {
  int? amount;
  String? category;
  String? descriptor;
  int? rewardType;
  int? rewardAmount;

  @override
  String toString() {
    return 'BagEntry{amount: $amount, category: $category, rewardType: $rewardType, rewardAmount: $rewardAmount}';
  }
}

class Accolade {
  int? bloodlineXp;
  int? bounty;
  String? category;
  int? eventPoints;
  int? gems;
  int? generatedGems;
  int? gold;
  int? hits;
  int? hunterPoints;
  int? hunterXp;
  int? weighting;
  int? xp;

  @override
  String toString() {
    return 'Accolade{bloodlineXp: $bloodlineXp, bounty: $bounty, eventPoints: $eventPoints, gems: $gems, generatedGems: $generatedGems, gold: $gold, hits: $hits, hunterPoints: $hunterPoints, hunterXp: $hunterXp, weighting: $weighting, xp: $xp}';
  }
}

class TeamNode {
  final int team;

  final String suffix;

  final XmlNode node;

  TeamNode({required this.team, required this.suffix, required this.node});

  @override
  String toString() {
    return 'TeamNode{team: $team, suffix: $suffix}';
  }
}

class PlayerNode {
  final int team;
  final int index;

  final XmlNode node;
  final String suffix;

  PlayerNode(
      {required this.team,
      required this.index,
      required this.node,
      required this.suffix});

  @override
  String toString() {
    return 'PlayerNode{team: $team, index: $index, suffix: $suffix}';
  }
}

extension XmlNodeExt on XmlNode {
  String? get name {
    return getAttribute('name');
  }

  String? get stringValue {
    return getAttribute('value');
  }

  bool? get boolValue {
    final value = getAttribute('value');
    return value != null && value.isNotEmpty ? 'true' == value : null;
  }

  int? get intValue {
    final value = getAttribute('value');
    return value != null && value.isNotEmpty ? int.parse(value) : null;
  }
}

class SignatureBuilder {
  var _value = '';

  void append(String part) {
    _value += part;
  }

  String generate() {
    return md5.convert(utf8.encode(_value)).toString();
  }
}
