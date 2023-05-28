import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:bitsdojo_window_platform_interface/window.dart';
import 'package:flutter/material.dart';
import 'package:hunt_stats/db/stats_db.dart';
import 'package:hunt_stats/hunt_bundle.dart';
import 'package:hunt_stats/tracker.dart';
import 'package:system_tray/system_tray.dart' as tray;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //await Window.initialize();
  //await Window.disableShadow();

  //await Window.setEffect(
  //  effect: WindowEffect.tabbed,
  //);

  final db = StatsDb();
  final tracker = TrackerEngine(db);

  runApp(MyApp(engine: tracker));

  await tracker.start();

  doWhenWindowReady(() {
    final window = appWindow;

    const initialSize = Size(360, 256);
    window.minSize = initialSize;
    window.size = initialSize;
    window.alignment = Alignment.center;
    window.show();

    _startSystemTray(window);
  });
}

void _startSystemTray(DesktopWindow window) async {
  final systemTray = tray.SystemTray();

  await systemTray.initSystemTray(
      title: 'system_tray',
      iconPath: 'assets/icon.ico',
      toolTip: 'Hunt: Stats');

  final menu = tray.Menu();
  await menu.buildFrom([
    tray.MenuItemLabel(
        label: 'Show',
        onClicked: (_) => window.isVisible ? window.restore() : window.show()),
    tray.MenuSeparator(),
    tray.MenuItemLabel(
        label: 'Exit',
        onClicked: (_) async {
          await systemTray.destroy();
          exit(0);
        })
  ]);

  await systemTray.setContextMenu(menu);

  systemTray.registerSystemTrayEventHandler((eventName) {
    debugPrint('eventName: $eventName');

    switch (eventName) {
      case 'double-click':
        window.restore();
        break;
      case 'click':
        window.show();
        break;
      case 'right-click':
        systemTray.popUpContextMenu();
        break;
    }
  });
}

const backgroundColor = /*Colors.grey.withOpacity(0.2)*/ Colors.green;

class MyApp extends StatelessWidget {
  final TrackerEngine engine;

  const MyApp({super.key, required this.engine});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
      home: Column(
        children: [
          Container(
            color: backgroundColor,
            height: 32,
            width: double.infinity,
            child: MoveWindow(
              onDoubleTap: () => appWindow.minimize(),
            ),
          ),
          Expanded(child: MyHomePage(engine: engine)),
        ],
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final TrackerEngine engine;

  const MyHomePage({super.key, required this.engine});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  @override
  Widget build(BuildContext context) {
    const textColor = Colors.white;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: StreamBuilder<HuntBundle?>(
        stream: widget.engine.lastMatch,
        builder: (cntx, snapshot) {
          final bundle = snapshot.data;

          if (bundle == null) {
            return const Center(
              child: Text(
                'Awaiting for hunt data',
                style: TextStyle(color: textColor),
              ),
            );
          }

          final teammates = bundle.match.players
              .where((element) => element.teammate)
              .map((e) => e.username);

          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _createTeamKdWidget(bundle, _teamStats, textColor: textColor),
                if (_teamStats) ...[
                  const SizedBox(
                    height: 4,
                  ),
                  Text(
                    teammates.join(', '),
                    style: const TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w500),
                  ),
                ],
                const SizedBox(
                  height: 8,
                ),
                _createOwnKdaWidget(bundle, textColor: textColor),
                if (size.height > 480) ...[
                  const SizedBox(
                    height: 64,
                  ),
                  _createTeamStatsSwitch(textColor: textColor),
                  const SizedBox(
                    height: 8,
                  ),
                  ElevatedButton(
                      onPressed: _handleResetClick, child: const Text('Reset'))
                ],
                const SizedBox(
                  height: 32,
                )
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _createOwnKdaWidget(HuntBundle bundle, {Color? textColor}) {
    final kdaChanges = bundle.kdaChanges;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'KDA ${formatDouble(bundle.ownStats.kda)}',
          style: TextStyle(
              fontSize: 24, color: textColor, fontWeight: FontWeight.bold),
        ),
        if (kdaChanges != null && kdaChanges != 0) ...[
          const SizedBox(
            width: 4,
          ),
          Text(
            '(${formatDouble(kdaChanges, plusIfPositive: true, precision: 3)})',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w500, color: textColor),
          )
        ]
      ],
    );
  }

  Widget _createTeamStatsSwitch({Color? textColor}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Total',
          style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
        ),
        const SizedBox(
          width: 8,
        ),
        Switch(
            value: _teamStats,
            onChanged: (checked) {
              setState(() {
                _teamStats = checked;
              });
            }),
        const SizedBox(
          width: 8,
        ),
        Text(
          'Team',
          style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _createTeamKdWidget(HuntBundle bundle, bool teamStats,
      {Color? textColor}) {
    final kills =
        teamStats ? bundle.teamStats.teamKills : bundle.ownStats.totalKills;
    final deaths =
        teamStats ? bundle.teamStats.teamDeaths : bundle.ownStats.totalDeaths;

    final killsChanges =
        teamStats ? bundle.teamKillsChanges : bundle.ownKillsChanges;
    final deathsChanges =
        teamStats ? bundle.teamDeathsChanges : bundle.ownDeatchChanges;

    final assistsChanges = teamStats ? null : bundle.ownAssistsChanges;
    final assists = teamStats ? null : bundle.ownStats.ownAssists;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          kills.toString(),
          style: TextStyle(fontSize: 48, color: textColor),
        ),
        if (killsChanges != null && killsChanges != 0) ...[
          Text(
            intPlusIfPositive(killsChanges),
            style: TextStyle(
                fontSize: 16, color: textColor, fontWeight: FontWeight.w500),
          )
        ],
        Text(' / ', style: TextStyle(fontSize: 48, color: textColor)),
        Text(
          deaths.toString(),
          style: TextStyle(fontSize: 48, color: textColor),
        ),
        if (deathsChanges != null && deathsChanges != 0) ...[
          Text(
            intPlusIfPositive(deathsChanges),
            style: TextStyle(
                fontSize: 16, color: textColor, fontWeight: FontWeight.w500),
          )
        ],
        if (assists != null) ...[
          Text(' / ', style: TextStyle(fontSize: 48, color: textColor)),
          Text(
            assists.toString(),
            style: TextStyle(fontSize: 48, color: textColor),
          ),
          if (assistsChanges != null && assistsChanges != 0) ...[
            Text(
              intPlusIfPositive(assistsChanges),
              style: TextStyle(
                  fontSize: 16, color: textColor, fontWeight: FontWeight.w500),
            )
          ]
        ]
      ],
    );
  }

  bool _teamStats = true;

  static String intPlusIfPositive(int value) {
    return value > 0 ? '+$value' : value.toString();
  }

  static String formatDouble(double value,
      {int precision = 2, bool plusIfPositive = false}) {
    final formatted = value.toPrecision(precision).toString();
    return plusIfPositive && value > 0 ? '+$formatted' : formatted;
  }

  void _handleResetClick() async {
    await widget.engine.invalidateMatches();

    _showSnackbar(text: 'Invalidated');
  }

  void _showSnackbar({required String text, Duration? duration}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.green,
        duration: duration ?? const Duration(milliseconds: 2000),
        content: Text(
          text,
          style: const TextStyle(color: Colors.white),
        ),
      ));
    }
  }
}

extension Ex on double {
  double toPrecision(int n) => double.parse(toStringAsFixed(n));
}