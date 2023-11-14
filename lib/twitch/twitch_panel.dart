import 'package:flutter/material.dart';
import 'package:hunt_stats/prediction_template.dart';
import 'package:hunt_stats/secrets.dart';
import 'package:hunt_stats/span_util.dart';
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

  Widget _createMissionStateWidget(BuildContext context, MissionState state) {
    final String formatted;
    final Color color;

    switch (state) {
      case MissionState.unknown:
        formatted = 'Unknown';
        color = Colors.grey;
        break;

      case MissionState.started:
        formatted = 'Active match';
        color = Colors.red;
        break;

      case MissionState.empty:
      case MissionState.ended:
        formatted = 'Lobby';
        color = Colors.green;
        break;
    }

    return RichText(
        text: TextSpan(
            style: const TextStyle(color: Colors.white, fontSize: 12),
            children: SpanUtil.createSpans(
                'Game state: $formatted',
                formatted,
                (highlighted) => TextSpan(
                    text: formatted,
                    style: TextStyle(
                        color: color, fontWeight: FontWeight.bold)))));
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
          final bool canRunPredictions =
              state.missionState != MissionState.started &&
                  state.missionState != MissionState.unknown;
          return Stack(
            alignment: Alignment.topRight,
            children: [
              SizedBox(
                width: double.infinity,
                child: Column(
                  children: [
                    _createMissionStateWidget(context, state.missionState),
                    const SizedBox(
                      height: 8,
                    ),
                    if (active != null) ...[
                      Text(
                        active.template.title,
                        textAlign: TextAlign.center,
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
                          onPressed: canRunPredictions
                              ? () => _cubit.runPrediction(
                                  available: _mode.available)
                              : null,
                          child: const Text(
                            'Run prediction',
                          )),
                    ],
                    const SizedBox(height: 8,),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Checkbox(
                            activeColor: Colors.indigo,
                            value: state.automatically,
                            onChanged: (checked) =>
                                _cubit.setAutomatically(checked ?? false)),
                        const Text('Automatically',
                            style: TextStyle(fontSize: 12)),
                        if(active == null) ... [
                          const SizedBox(
                            width: 8,
                          ),
                          ..._createModeWidgets('Solo', _Mode.solo),
                          ..._createModeWidgets('Duo', _Mode.duo),
                          ..._createModeWidgets('Trio', _Mode.trio)
                        ]
                      ],
                    )
                  ],
                ),
              ),
              if (state.processing) ...[
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                )
              ]
            ],
          );
        },
      ),
    );
  }

  List<Widget> _createModeWidgets(String title, _Mode mode) {
    return [
      Checkbox(
          value: _mode == mode,
          activeColor: Colors.indigo,
          onChanged: (_) => _handleModeChanged(mode)),
      Text(
        title,
        style: const TextStyle(fontSize: 12),
      ),
    ];
  }

  _Mode _mode = _Mode.solo;

  void _handleModeChanged(_Mode value) {
    setState(() {
      _mode = value;
    });
  }
}

enum _Mode {
  solo,
  duo,
  trio;

  List<PredictionTemplate> get available {
    switch (this) {
      case _Mode.solo:
        return PredictionTemplate.solo;
      case _Mode.duo:
        return PredictionTemplate.duo;
      case _Mode.trio:
        return PredictionTemplate.trio;
    }
  }
}
