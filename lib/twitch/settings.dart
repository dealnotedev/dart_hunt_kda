import 'dart:async';
import 'dart:convert';

import 'package:hunt_stats/twitch/twitch_creds.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Settings {
  static final instance = Settings._();

  Settings._();

  static const _kTwitchAuth = 'twitch_auth';

  Future<void> init() async {
    twitchAuth = await _twitchAuth;
  }

  Future<void> saveTwitchAuth(TwitchCreds? creds) async {
    final prefs = await SharedPreferences.getInstance();

    if (creds != null) {
      prefs.setString(_kTwitchAuth, jsonEncode(creds.toJson()));
    } else {
      prefs.remove(_kTwitchAuth);
    }

    twitchAuth = creds;
    _twitchAuthSubject.add(creds);
  }

  Stream<TwitchCreds?> get twitchAuthChanges => _twitchAuthSubject.stream;

  late TwitchCreds? twitchAuth;

  final _twitchAuthSubject = StreamController<TwitchCreds?>.broadcast();

  Future<TwitchCreds?> get _twitchAuth async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_kTwitchAuth);
    return json != null ? TwitchCreds.fromJson(jsonDecode(json)) : null;
  }
}
