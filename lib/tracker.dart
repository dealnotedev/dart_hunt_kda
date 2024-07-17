import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hunt_stats/generated/assets.dart';
import 'package:hunt_stats/hunt_bundle.dart';
import 'package:hunt_stats/hunt_finder.dart';
import 'package:hunt_stats/observable_value.dart';
import 'package:hunt_stats/ringtone.dart';

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

  Future<void> _handleGameEvent(_BaseEvent info) async {
    if (info is _MapLoading) {
      _lastMap = info.levelName;

      if (mapSounds) {
        await _playMapSound(info.levelName);
      }
    }

    if (info is _StatsEvent) {
      bundle.set(bundle.current.add(kills: info.kills, deaths: info.deaths));
    }

    if (info is _MissionState) {
      final missionActive = info.state == 'MissionStarted';

      if (_missionActive != missionActive) {
        _missionActive = missionActive;

        if (missionActive) {
          bundle.set(bundle.current.resetMatchData());
        }
      }
    }
  }

  final bundle = ObservableValue(
      current: HuntBundle(
          kills: 0,
          deaths: 0,
          currentMatchDeaths: 0,
          currentMatchKills: 0,
          matches: 0));

  Future<void> _playMapSound(String mapName) async {
    switch (mapName) {
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
    final finder = HuntFinder();

    final file = await finder.findHuntAttributes();
    final attributes = file.path;

    _gameEventSubject.add(_HuntFound(attributes));

    final userDirectory = file.parent.parent.parent;
    final logFile = File('${userDirectory.path}\\game.log');

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
          .transform(utf8.decoder)
          .map((s) {
            length += s.length;
            return s;
          })
          .transform(const LineSplitter())
          .forEach((s) {
            final parts = s.split(' ').map((e) => e.trim()).toList();

            final map = _findMissionMap(parts);
            if (map != null) {
              _gameEventSubject.add(_MapLoading(map));
            }

            final savedIndex = parts.indexOf('Saved');
            int kills = 0;
            int deaths = 0;

            if (savedIndex != -1 && parts[savedIndex + 1] == 'video') {
              switch (parts[savedIndex + 2]) {
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
        .transform(utf8.decoder)
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
