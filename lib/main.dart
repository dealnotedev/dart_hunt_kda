import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:xml/xml.dart';

void main() async {
  final file = File('attributes.xml');

  final start = DateTime.now().microsecondsSinceEpoch;

  final document = XmlDocument.parse(await file.readAsString());
  final huntData = HuntData();
  huntData._fill(document);

  final teams = huntData.numTeams;
  if (teams != null && teams > 0) {
    for (int i = 0; i < teams; i++) {
      final teamData = huntData.teams[i];
      final teamSize = teamData?['numplayers']?.node.intValue ?? 0;
      final ownTeam = teamData?['ownteam']?.node.boolValue ?? false;
      final mmr = teamData?['mmr']?.node.intValue;
      final isinvite = teamData?['isinvite']?.node.boolValue;
      //final handicap = teamData?['handicap']?.node.boolValue;

      //print(teamSize);
      //print(ownTeam);
      //print(mmr);
      //print(isinvite);

      print('TEAM #${i + 1}, ${ownTeam ? 'MY' : 'ENEMY'}');

      for (int p = 0; p < teamSize; p++) {
        final playerData = huntData.players[i]?[p];
        final name = playerData?['blood_line_name']?.node.stringValue;
        final mmr = playerData?['mmr']?.node.intValue;
        print('$name, mmr $mmr}');
      }

      print('################');
    }

    huntData.entries.forEach((key, value) {
      print('${value.descriptor}:${value.amount}');
    });
  }

  print('Time: ${DateTime.now().microsecondsSinceEpoch - start}');

  runApp(const MyApp());
}

class HuntData {
  int? numTeams;

  bool? isQuickPlay;

  bool? isHunterDead;

  bool? isTutorial;

  final players = <int,
      Map<int,
          Map<String, PlayerNode>>>{}; // <team, <player_num, [player_values]>>

  final teams = <int, Map<String, TeamNode>>{};
  final entries = <String, BagEntry>{};

  void _fill(XmlDocument document) {
    int? missionBagNumEntries;

    final bagEntries = <int, BagEntry>{};

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
            final entry = bagEntries.putIfAbsent(index, () => BagEntry());

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
          }
          break;
      }
    }

    for (int i = 0; i < (missionBagNumEntries ?? 0); i++) {
      final entry = bagEntries[i];
      final descriptor = entry?.descriptor;

      if (entry != null && descriptor != null) {
        entries.addEntries([MapEntry(descriptor, entry)]);
      } else {
        print('FAILED $i');
      }
    }
  }

  static String _joinPartsAfter(List<String> parts, int after) {
    return parts.sublist(after).join('_');
  }
}

class BagEntry {
  int? amount;
  String? category;
  String? descriptor;
  int? rewardType;
  int? rewardAmount;
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
