import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
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

  final _huntFinder = HuntFinder();

  final bundle = ObservableValue(
      current: HuntBundle(
          killStreak: 0,
          currentMatchKillStreak: 0,
          assists: 0,
          history: [],
          kills: 0,
          deaths: 0,
          currentMatchAssists: 0,
          currentMatchDeaths: 0,
          currentMatchKills: 0,
          matches: 0));

  final _textGenerator =
      TextStatsGenerator(tableWidth: 32, style: TableStyle.simple);

  final _kills = StreamController<KillInfo>.broadcast();

  Stream<KillInfo> get kills => _kills.stream;

  TrackerEngine({required this.mapSounds, required this.updateInterval}) {
    _gameEventSubject.stream.listen(_handleGameEvent);
    _kills.stream.listen(_sendKillBroadcast);
  }

  Completer<void>? _killBroadcastCompleter;

  final _dio = Dio(BaseOptions(
    baseUrl: 'http://127.0.0.1:4080',
    connectTimeout: const Duration(seconds: 2),
  ));

  void _sendKillBroadcast(KillInfo kill) async {
    await _killBroadcastCompleter?.future;

    try {
      _killBroadcastCompleter = Completer();

      final attrs = _createKillAttrs(kill.inMatch);

      await _dio.get('/kill', queryParameters: {
        'text': attrs.text,
        'in_match': kill.inMatch,
        'in_match_streak': kill.inMatchStreak,
        'total_streak': kill.totalStreak
      });
    } finally {
      _killBroadcastCompleter?.complete();
    }
  }

  bool? _missionActive;
  String? _lastMap;

  static _KillAttrs _createKillAttrs(int streak) {
    switch (streak) {
      case 1:
        return _KillAttrs(
            text: 'First Blood', audio: Assets.assetsSxFirstBlood);

      case 2:
        return _KillAttrs(
            text: 'Double Kill', audio: Assets.assetsSxDoubleKill);

      case 3:
        return _KillAttrs(text: 'Multi Kill', audio: Assets.assetsSxMultiKill);

      case 4:
        return _KillAttrs(text: 'Rampage', audio: Assets.assetsSxRampage);

      case 5:
        return _KillAttrs(
            text: 'Killing Spree', audio: Assets.assetsSxKillingSpree);

      case 6:
        return _KillAttrs(text: 'Dominating', audio: Assets.assetsSxDominating);

      case 7:
        return _KillAttrs(
            text: 'Unstoppable', audio: Assets.assetsSxUnstoppable);

      case 8:
        return _KillAttrs(text: 'Mega Kill', audio: Assets.assetsSxMegaKill);

      case 9:
        return _KillAttrs(text: 'Ultra Kill', audio: Assets.assetsSxUltraKill);

      case 10:
        return _KillAttrs(
            text: 'Whicked Sick', audio: Assets.assetsSxWhickedSick);

      case 11:
        return _KillAttrs(
            text: 'Monster Kill', audio: Assets.assetsSxMonsterKill);

      case 12:
        return _KillAttrs(text: 'Holy Shit', audio: Assets.assetsSxHolyShit);
      case 13:
      default:
        return _KillAttrs(text: 'God Like', audio: Assets.assetsSxGodLike);
    }
  }

  TrackerState get state =>
      TrackerState(activeMatch: _missionActive, map: _lastMap);

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
      switch (info.type) {
        case _StatsType.kill:
          final updated = bundle.set(bundle.current.addKill());
          _kills.add(KillInfo(
              inMatch: updated.currentMatchKills,
              totalStreak: updated.killStreak,
              inMatchStreak: updated.currentMatchKillStreak));
          break;

        case _StatsType.death:
          bundle.set(bundle.current.addDeath());
          break;
      }

      await _soundCompleter?.future;

      switch (info.type) {
        case _StatsType.kill:
          final attrs = _createKillAttrs(bundle.current.currentMatchKills);
          RingtonePlayer.play(attrs.audio);
          break;

        case _StatsType.death:
          RingtonePlayer.play(Assets.assetsDeath);
          break;
      }

      _soundCompleter = Completer();

      await Future.delayed(const Duration(seconds: 1));

      _soundCompleter?.complete();
      _soundCompleter = null;
    }

    if (info is _StatsEvent) {
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

    if (info is _MatchFinishReason) {
      bundle.set(bundle.current.addMatchResult(success: info.success));
    }
  }

  File get _textStatsFile {
    final dir = File(Platform.resolvedExecutable).parent;
    return File('${dir.path}/stats.txt');
  }

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

    final logFile = await _huntFinder.findHuntGameLogFile();
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

            _StatsType? statsType;

            if (preVideoIndex != -1 && parts[preVideoIndex + 1] == 'video') {
              final videoType = parts[preVideoIndex + 2].replaceAll(':', '');

              switch (videoType) {
                case '\'HUNTER_KILLED\'':
                  statsType = _StatsType.kill;
                  break;

                case '\'PLAYER_DOWNED\'':
                  statsType = _StatsType.death;
                  break;
              }
            }

            if (statsType != null) {
              _gameEventSubject.add(_StatsEvent(type: statsType));
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

enum _StatsType { kill, death }

class _StatsEvent extends _BaseEvent {
  final _StatsType type;

  _StatsEvent({required this.type});
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

class _KillAttrs {
  final String text;
  final String audio;

  _KillAttrs({required this.text, required this.audio});
}

abstract class _BaseEvent {}

class TrackerState {
  final bool? activeMatch;
  final String? map;

  TrackerState({required this.activeMatch, required this.map});
}
