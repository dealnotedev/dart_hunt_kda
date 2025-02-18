import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hunt_stats/generated/assets.dart';
import 'package:hunt_stats/hunt_bundle.dart';
import 'package:hunt_stats/hunt_finder.dart';
import 'package:hunt_stats/observable_value.dart';
import 'package:hunt_stats/ringtone.dart';
import 'package:hunt_stats/text_stats_generator.dart';

class TrackerEngine {
  final _gameEventSubject = StreamController<_BaseEvent>.broadcast();

  final bool mapSounds;
  final Duration updateInterval;

  TrackerEngine({required this.mapSounds, required this.updateInterval}) {
    _gameEventSubject.stream.listen(_handleGameEvent);
  }

  bool? _missionActive;
  String? _lastMap;

  TrackerState get state =>
      TrackerState(activeMatch: _missionActive, map: _lastMap);

  final _textGenerator =
      TextStatsGenerator(tableWidth: 32, style: TableStyle.simple);

  Completer<void>? _soundCompleter;

  Future<void> _handleGameEvent(_BaseEvent info) async {
    if (info is _MapLoading) {
      _lastMap = info.levelName;

      if (mapSounds) {
        await _playMapSound(info.levelName);
      }
    }

    bool writeFileStats = false;

    if (info is _StatsEvent) {
      bundle.set(bundle.current.add(kills: info.kills, deaths: info.deaths));

      await _soundCompleter?.future;

      if (info.kills > 0) {
        RingtonePlayer.play(Assets.assetsKill);
      } else if (info.deaths > 0) {
        RingtonePlayer.play(Assets.assetsDeath);
      }

      if (info.deaths > 0 || info.kills > 0) {
        _soundCompleter = Completer();

        await Future.delayed(const Duration(seconds: 1));

        _soundCompleter?.complete();
        _soundCompleter = null;
      }
    }

    if (info is _AssistsEvent) {
      if (bundle.current.currentMatchAssists != info.count) {
        bundle.set(bundle.current.setAssists(assists: info.count));
      } else {
        return;
      }
    }

    if (info is _StatsEvent || info is _AssistsEvent) {
      writeFileStats = true;
    }

    if (info is _MissionState) {
      final missionActive = info.state == 'MissionStarted';

      if (_missionActive != missionActive) {
        _missionActive = missionActive;

        if (missionActive) {
          bundle.set(bundle.current.resetMatchData());
          writeFileStats = true;
        }
      }
    }

    if (writeFileStats) {
      _textGenerator.write(bundle: bundle.current, file: _textStatsFile);
    }

    if(info is _MatchFinishReason){
      bundle.set(bundle.current.addMatchResult(success: info.success));
    }
  }

  File get _textStatsFile {
    final dir = File(Platform.resolvedExecutable).parent;
    return File('${dir.path}/stats.txt');
  }

  final bundle = ObservableValue(
      current: HuntBundle(
          assists: 0,
          history: [false, true, true, true, false, true, true],
          kills: 4,
          deaths: 2,
          currentMatchAssists: 0,
          currentMatchDeaths: 1,
          currentMatchKills: 0,
          matches: 0));

  Future<void> _playMapSound(String mapName) async {
    switch (mapName) {
      case 'colorado':
        RingtonePlayer.play(Assets.assetsColorado);
        break;
      case 'creek':
        RingtonePlayer.play(Assets.assetsCreek);
        break;
      case 'cemetery':
        RingtonePlayer.play(Assets.assetsCemetery);
        break;
      case 'civilwar':
        RingtonePlayer.play(Assets.assetsCivilwar);
        break;
    }
  }

  void startTracking() async {
    _textGenerator.write(bundle: bundle.current, file: _textStatsFile);

    final finder = HuntFinder();

    final logFile = await finder.findHuntGameLogFile();
    _gameEventSubject.add(_HuntFound(logFile.path));

    final initial = await _findMissionState(logFile);

    final initialState = initial.state;
    final initialMap = initial.map;

    if (initialState != null) {
      _gameEventSubject.add(_MissionState(state: initialState));
    }
    if (initialMap != null) {
      _gameEventSubject.add(_MapLoading(initialMap));
    }

    var length = await logFile.length();

    while (true) {
      await Future.delayed(updateInterval);

      final start = DateTime.now().millisecondsSinceEpoch;

      final actualLength = await logFile.length();
      if (actualLength == length) {
        continue;
      }

      if (actualLength < length) {
        length = 0;
      }

      await logFile
          .openRead(length)
          .transform(const Utf8Decoder(allowMalformed: true))
          .map((s) {
            length += s.length;
            return s;
          })
          .transform(const LineSplitter())
          .forEach((s) {
            final parts = s.split(' ').map((e) => e.trim()).toList();

            //<23:46:52> <Flash> bountyList - cat: accolade_clues_found, bounty: 50, data.xp: 0, data.gold: 0 [#!NO_CONTEXT!#]
            //<23:25:40> <Flash> boss_data() [#!NO_CONTEXT!#]

            //<21:35:09> <Flash> 	 category: accolade_players_killed_assist [#!NO_CONTEXT!#]
            //<21:35:09> <Flash> 	 kills: 1 [#!NO_CONTEXT!#]

            if (parts.contains('<Flash>') && parts.contains('boss_data()')) {
              // reset assists count
              _gameEventSubject.add(_AssistsEvent(count: 0));
            }

            //<22:00:31> [EAC] Client disconnected by server. Cause : GameSessionEnded. Reason: Remote disconnected: PlayerKickManager.
            //<21:26:24> [EAC] Client disconnected by server. Cause : UserRequested. Reason: Remote disconnected: User requested to leave mission.
            //<21:41:16> [EAC] Client disconnected by server. Cause : MissionRequested. Reason: Remote disconnected: (null).

            final eacIndex = parts.indexOf('[EAC]');
            if (eacIndex != -1 &&
                parts[eacIndex + 1] == 'Client' &&
                parts[eacIndex + 2] == 'disconnected' &&
                parts[eacIndex + 3] == 'by' &&
                parts[eacIndex + 4] == 'server.' &&
                parts[eacIndex + 5] == 'Cause' &&
                parts[eacIndex + 6] == ':') {
              final reason = parts[eacIndex + 7];
              switch (reason) {
                case 'GameSessionEnded.':
                case 'UserRequested.':
                  _gameEventSubject.add(_MatchFinishReason(success: false));
                  break;

                case 'MissionRequested.':
                  _gameEventSubject.add(_MatchFinishReason(success: true));
                  break;
              }
            }

            final map = _findMissionMap(parts);
            if (map != null) {
              _gameEventSubject.add(_MapLoading(map));
            }

            //<21:08:36> [Error] [Geforce Experience] Failed to save video 'PLAYER_DOWNED': NVGSDK_ERR_IPC_FAILED
            //<21:08:36> [Error] [Geforce Experience] Failed to save video 'HUNTER_KILLED': NVGSDK_ERR_IPC_FAILED
            //<21:14:11> [Geforce Experience] Saved video 'PLAYER_DOWNED'
            //<20:46:16> [Geforce Experience] Saved video 'HUNTER_KILLED'

            final savedIndex = parts.indexOf('Saved');
            final saveIndex = parts.indexOf('save');

            final preVideoIndex = savedIndex != -1 ? savedIndex : saveIndex;

            int kills = 0;
            int deaths = 0;

            if (preVideoIndex != -1 && parts[preVideoIndex + 1] == 'video') {
              final videoType = parts[preVideoIndex + 2].replaceAll(':', '');

              switch (videoType) {
                case '\'HUNTER_KILLED\'':
                  kills++;
                  break;

                case '\'PLAYER_DOWNED\'':
                  deaths++;
                  break;
              }
            }

            if (kills > 0 || deaths > 0) {
              _gameEventSubject.add(_StatsEvent(kills: kills, deaths: deaths));
            }

            final state = _findMissionBag(parts);
            if (state != null) {
              _gameEventSubject.add(_MissionState(state: state));
            }
          });

      final end = DateTime.now().millisecondsSinceEpoch;
      if (kDebugMode) {
        print('Processed in ${end - start}ms');
      }
    }
  }

  static String? _findMissionMap(List<String> parts) {
    final index = parts.indexOf('PrepareLevel');
    if (index != -1) {
      return parts[index + 1].trim().toLowerCase().split('/')[1];
    } else {
      return null;
    }
  }

  static Future<({String? state, String? map})> _findMissionState(
      File logFile) async {
    String? state;
    String? map;

    await logFile
        .openRead()
        .transform(const Utf8Decoder(allowMalformed: true))
        .transform(const LineSplitter())
        .forEach((s) {
      final parts = s.split(' ');
      state = _findMissionBag(parts) ?? state;
      map = _findMissionMap(parts) ?? map;
    });

    return (state: state, map: map);
  }

  static String? _findMissionBag(List<String> parts) {
    final index = parts.indexOf('CMetaMissionBag');
    if (index != -1) {
      return parts[index + 2];
    } else {
      return null;
    }
  }
}

class _AssistsEvent extends _BaseEvent {
  final int count;

  _AssistsEvent({required this.count});
}

class _StatsEvent extends _BaseEvent {
  final int kills;
  final int deaths;

  _StatsEvent({required this.kills, required this.deaths});
}

class _MissionState extends _BaseEvent {
  /// One of MissionStarted, ContentsDumped, Empty
  final String state;

  _MissionState({required this.state});
}

class _MatchFinishReason extends _BaseEvent {
  final bool success;

  _MatchFinishReason({required this.success});
}

class _MapLoading extends _BaseEvent {
  final String levelName;

  _MapLoading(this.levelName);
}

class _HuntFound extends _BaseEvent {
  final String attributes;

  _HuntFound(this.attributes);
}

abstract class _BaseEvent {}

class TrackerState {
  final bool? activeMatch;
  final String? map;

  TrackerState({required this.activeMatch, required this.map});
}
