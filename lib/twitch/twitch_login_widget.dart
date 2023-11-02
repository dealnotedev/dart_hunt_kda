import 'package:flutter/material.dart';
import 'package:hunt_stats/generated/assets.dart';
import 'package:hunt_stats/secrets.dart';
import 'package:hunt_stats/twitch/settings.dart';
import 'package:hunt_stats/twitch/twitch_authenticator.dart';

class TwitchLoginWidget extends StatefulWidget {
  const TwitchLoginWidget({super.key});

  @override
  State<StatefulWidget> createState() => _State();
}

class _State extends State<TwitchLoginWidget> {
  final _authenticator = TwitchAuthenticator(
      clientId: twitchClientId,
      clientSecret: twitchClientSecret,
      oauthRedirectUrl: 'https://hunt.predictor.ua/redirect/?to=auth');

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(4);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      constraints: const BoxConstraints(
        minHeight: 128
      ),
      child: Center(
        child: Material(
          color: const Color(0xFF6542A6),
          borderRadius: radius,
          child: InkWell(
            onTap: _login2Twitch,
            borderRadius: radius,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    Assets.assetsIcTwitchWhite24dp,
                    width: 24,
                    height: 24,
                    filterQuality: FilterQuality.medium,
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  const Text(
                    'Connect with Twitch',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 14),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _login2Twitch() async {
    final creds = await _authenticator.login();
    await Settings.instance.saveTwitchAuth(creds);
  }
}
