import 'dart:io';

import 'package:dio/dio.dart';
import 'package:hunt_stats/twitch/twitch_creds.dart';
import 'package:url_launcher/url_launcher.dart';

class TwitchAuthenticator {
  final String clientId;
  final String clientSecret;
  final String oauthRedirectUrl;

  static const _scope = 'chat:edit channel:manage:predictions chat:read';
  static const _scopeEncoded = 'chat%3Aedit%20channel%3Amanage%3Apredictions%20chat%3Aread';

  TwitchAuthenticator({required this.clientId, required this.clientSecret, required this.oauthRedirectUrl});

  Future<TwitchCreds?> login() async {
    final authorizationCode = await _startOauth();

    if(authorizationCode == null) return null;

    final body = <String, String>{
      'redirect_uri': oauthRedirectUrl,
      'scope': _scope,
      'client_id': clientId,
      'client_secret': clientSecret,
      'grant_type': 'authorization_code',
      'code': authorizationCode
    };

    final dio = Dio();

    final response = await dio.post('https://id.twitch.tv/oauth2/token',
        data: FormData.fromMap(body),
        options: Options(contentType: "application/x-www-form-urlencoded"));
    final json = response.data;
    final accessToken = json['access_token'] as String;

    final userId = await dio
        .get('https://api.twitch.tv/helix/users',
        options: Options(headers: {
          'Authorization': 'Bearer $accessToken',
          'Client-Id': clientId
        }))
        .then((value) => value.data['data'] as List<dynamic>)
        .then((array) => array[0]['id']);

    return TwitchCreds(
        refreshToken: json['refresh_token'] as String,
        accessToken: accessToken,
        clientId: clientId,
        broadcasterId: userId);
  }

  Future<String?> _startOauth() async {
    final server = await HttpServer.bind('localhost', 3000);

    try {
      final url = 'https://id.twitch.tv/oauth2/authorize?client_id=$clientId&redirect_uri=http%3A%2F%2Flocalhost%3A3000&response_type=code&scope=$_scopeEncoded';
      launchUrl(Uri.parse(url));

      final request = await server.first;

      try {
        final code = request.requestedUri.queryParameters['code'];
        _writeHtml(request);
        await request.response.close();

        return code;
      } catch (e) {
        request.response.statusCode = 500;
        await request.response.close().catchError((_) {});
        rethrow;
      }
    } finally {
      await server.close();
    }
  }

  void _writeHtml(HttpRequest request) {
    request.response
      ..statusCode = 200
      ..headers.set('content-type', 'text/html; charset=UTF-8')
      ..write(
        '''
<!DOCTYPE html>

<html>
  <head>
    <meta charset="utf-8">
    <title>Authorization successful.</title>
  </head>

  <body>
    <h2 style="text-align: center">Hunt: Predictor is ready for your game</h2>
    <p style="text-align: center">This window can be closed now.</p>
  </body>
</html>''',
      );
  }
}