import 'package:flutter/material.dart';
import 'package:hunt_stats/secrets.dart';
import 'package:hunt_stats/tracker.dart';
import 'package:hunt_stats/twitch/settings.dart';
import 'package:hunt_stats/twitch/twitch_api.dart';
import 'package:hunt_stats/twitch/twitch_panel_cubit.dart';
import 'package:hunt_stats/twitch/twitch_panel_state.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class TwitchPanel extends StatefulWidget {
  final TrackerEngine engine;

  const TwitchPanel({super.key, required this.engine});

  @override
  State<StatefulWidget> createState() => _State();
}

class _State extends State<TwitchPanel> {
  late final TwitchPanelCubit _cubit;

  @override
  void initState() {
    final settings = Settings.instance;
    final twitchApi = TwitchApi(
        settings: Settings.instance, clientSecret: twitchClientSecret);

    _cubit = TwitchPanelCubit(
        engine: widget.engine, twitchApi: twitchApi, settings: settings);
    super.initState();
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
  void dispose() {
    _cubit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 128),
      padding: const EdgeInsets.all(32),
      child: StreamBuilder<TwitchPanelState>(
        stream: _cubit.state.changes,
        initialData: _cubit.state.current,
        builder: (cntx, snapshot) {
          final state = snapshot.requireData;
          final active = state.active;
          return Stack(
            alignment: Alignment.center,
            children: [
              Column(
                children: [
                  Text(
                    'Mission state: ${state.missionState.name}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  if (active != null) ...[
                    Text(
                      active.template.title,
                      style: const TextStyle(
                          fontSize: 17,
                          color: Colors.white,
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    ElevatedButton(
                        style: ButtonStyle(
                            backgroundColor: MaterialStateColor.resolveWith(
                                (_) => Colors.red)),
                        onPressed: () => _cubit.stop(),
                        child: const Text(
                          'Stop',
                        ))
                  ] else ...[
                    ElevatedButton(
                        onPressed: () => _cubit.runPredictionInternal(
                            automatically: _automaticallyNext ?? false,
                            sound: _sound ?? false),
                        child: const Text(
                          'Run prediction',
                        )),
                    const SizedBox(
                      height: 8,
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Checkbox(
                            activeColor: Colors.indigo,
                            value: _automaticallyNext,
                            onChanged: _handleAutomaticallyChanged),
                        const Text('Automatically',
                            style: TextStyle(fontSize: 12)),
                        const SizedBox(
                          width: 8,
                        ),
                        Checkbox(
                            value: _sound,
                            activeColor: Colors.indigo,
                            onChanged: _handleSoundChanged),
                        const Text(
                          'Sound',
                          style: TextStyle(fontSize: 12),
                        )
                      ],
                    )
                  ]
                ],
              ),
              if (state.processing) ...[
                const Align(
                  alignment: Alignment.topRight,
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  ),
                )
              ]
            ],
          );
        },
      ),
    );
  }

  bool? _automaticallyNext = false;
  bool? _sound = false;

  void _handleAutomaticallyChanged(bool? value) {
    setState(() {
      _automaticallyNext = value;
    });
  }

  void _handleSoundChanged(bool? value) {
    setState(() {
      _sound = value;
    });
  }
}
