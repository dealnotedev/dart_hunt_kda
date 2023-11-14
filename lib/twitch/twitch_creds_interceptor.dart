import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:fresh_dio/fresh_dio.dart';
import 'package:hunt_stats/twitch/settings.dart';
import 'package:hunt_stats/twitch/twitch_creds.dart';

class TwitchCredsInterceptor extends Fresh<TwitchCreds> {
  TwitchCredsInterceptor(
      {required Settings settings, required String clientSecret})
      : super(
            refreshToken: (t, _) => _refreshToken(t, clientSecret),
            tokenHeader: (token) => {
                  'Authorization': 'Bearer ${token.accessToken}',
                  'Client-Id': token.clientId
                },
            tokenStorage: _SettingTokenStorage(settings: settings));

  static Future<TwitchCreds> _refreshToken(
      TwitchCreds? token, String clientSecret) {
    if (token == null) {
      throw StateError('No token found');
    }

    debugPrint('Try to refresh token...');

    final body = <String, String>{
      'refresh_token': token.refreshToken,
      'client_id': token.clientId,
      'client_secret': clientSecret,
      'grant_type': 'refresh_token',
    };

    return Dio()
        .post('https://id.twitch.tv/oauth2/token',
            data: FormData.fromMap(body),
            options: Options(contentType: "application/x-www-form-urlencoded"))
        .then((value) => value.data)
        .then((json) => token.copy(
            accessToken: json['access_token'] as String,
            refreshToken: json['refresh_token'] as String));
  }
}

class _SettingTokenStorage extends TokenStorage<TwitchCreds> {
  final Settings settings;

  _SettingTokenStorage({required this.settings});

  @override
  Future<void> delete() {
    return settings.saveTwitchAuth(null);
  }

  @override
  Future<TwitchCreds?> read() {
    return Future.value(settings.twitchAuth);
  }

  @override
  Future<void> write(TwitchCreds token) {
    return settings.saveTwitchAuth(token);
  }
}
