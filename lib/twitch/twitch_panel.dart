import 'package:flutter/material.dart';
import 'package:hunt_stats/secrets.dart';
import 'package:hunt_stats/tracker.dart';
import 'package:hunt_stats/twitch/settings.dart';
import 'package:hunt_stats/twitch/twitch_api.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class TwitchPanel extends StatefulWidget {
  final TrackerEngine engine;

  const TwitchPanel({super.key, required this.engine});

  @override
  State<StatefulWidget> createState() => _State();
}

class _State extends State<TwitchPanel> {
  final _twitchApi =
      TwitchApi(settings: Settings.instance, clientSecret: twitchClientSecret);

  @override
  void initState() {
    _request();
    super.initState();
  }

  Future<void> _request() async {
    final response = await _twitchApi.getPredictions(
        broadcasterId: Settings.instance.twitchAuth?.broadcasterId,
        count: 1,
        after: null);

    for (var prediction in response) {
      print(prediction.status);

      if ('LOCKED' == prediction.status) {
        await _twitchApi.endPrediction(
            broadcasterId: Settings.instance.twitchAuth?.broadcasterId,
            id: prediction.id,
            status: 'RESOLVED',
            winningOutcomeId: prediction.outcomes.last.id);
      }
    }
  }

  Future<void> _connectToChat() async {
    final channel =
        WebSocketChannel.connect(Uri.parse('wss://irc-ws.chat.twitch.tv:443'));
    await channel.ready;

    channel.stream.listen((event) {
      print(event);
    }, onError: (e) {
      print(e);
    });

    channel.sink.add('PASS oauth:${Settings.instance.twitchAuth?.accessToken}');
    channel.sink.add('NICK huntpredictor');
    channel.sink.add('JOIN #bilosnizhka_ua');
    channel.sink.add('PRIVMSG #bilosnizhka_ua :вітання');

    print('Wss connected');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 128),
      padding: const EdgeInsets.all(32),
      child: TextButton(
          onPressed: () {
            Settings.instance.saveTwitchAuth(null);
          },
          child: const Text(
            'Logout',
            style: TextStyle(color: Colors.white),
          )),
    );
  }
}
