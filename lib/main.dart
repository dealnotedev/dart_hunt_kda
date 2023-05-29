import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:bitsdojo_window_platform_interface/window.dart';
import 'package:flutter/material.dart';
import 'package:hunt_stats/db/entities.dart';
import 'package:hunt_stats/db/stats_db.dart';
import 'package:hunt_stats/generated/assets.dart';
import 'package:hunt_stats/hunt_bundle.dart';
import 'package:hunt_stats/mmr.dart';
import 'package:hunt_stats/tracker.dart';
import 'package:morphable_shape/morphable_shape.dart';
import 'package:system_tray/system_tray.dart' as tray;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final db = StatsDb();
  final tracker = TrackerEngine(db);

  runApp(MyApp(engine: tracker));

  await tracker.start();

  doWhenWindowReady(() {
    final window = appWindow;

    const initialSize = Size(360, 360);
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

          final teammates =
              bundle.match.players.where((element) => element.teammate);

          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  decoration: _createConcaveDecoration(
                      color: const Color(0xFF090909), radius: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 4,
                      ),
                      ...teammates.map((e) => Flexible(
                              child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: _createPlayerWidget(e, textColor: textColor),
                          ))),
                      const SizedBox(
                        width: 4,
                      )
                    ],
                  ),
                ),
                const SizedBox(
                  height: 16,
                ),
                _createIconifiedContaner(
                    icon: Assets.assetsIcKda,
                    children: _createMyKdaWidgets(bundle, textColor: textColor),
                    color: const Color(0xFF090909)),
                _createIconifiedContaner(
                    icon: Assets.assetsIcKd,
                    children:
                        _createTeamKdWidgets(bundle, textColor: textColor),
                    color: const Color(0xFF090909)),
                if (size.height > 480) ...[
                  const SizedBox(
                    height: 64,
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

  List<Widget> _createTeamKdWidgets(HuntBundle bundle,
      {required Color textColor}) {
    final textStyle = TextStyle(color: textColor, fontSize: 18);

    final stats = bundle.teamStats;
    final kdChanges = bundle.teamKdChanges;
    final killsChanges = bundle.totalKillsChanges;
    final deathsChanges = bundle.totalDeathsChanges;

    return [
      Expanded(
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Team KD',
            style: TextStyle(
                color: textColor, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          Text('${stats.matches} matches',
              style: const TextStyle(
                  color: _colorBlue, fontSize: 14, fontWeight: FontWeight.w500))
        ],
      )),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            formatDouble(stats.kd),
            style: TextStyle(
                color: kdChanges != null
                    ? (kdChanges > 0 ? _colorBlue : _colorRed)
                    : textColor,
                fontWeight: FontWeight.w500,
                fontSize: 20),
          ),
          if (kdChanges != null && kdChanges != 0) ...[
            _createDirectionIcon(positive: kdChanges > 0)
          ]
        ],
      ),
      const SizedBox(
        width: 16,
      ),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(stats.teamKills.toString(), style: textStyle),
          if (killsChanges != null && killsChanges > 0) ...[
            _createChangesWidget(killsChanges, positive: true)
          ],
          Text(' / ', style: textStyle),
          Text(stats.teamDeaths.toString(), style: textStyle),
          if (deathsChanges != null && deathsChanges > 0) ...[
            _createChangesWidget(deathsChanges, positive: false)
          ]
        ],
      ),
      const SizedBox(
        width: 16,
      )
    ];
  }

  List<Widget> _createMyKdaWidgets(HuntBundle bundle,
      {required Color textColor}) {
    final textStyle = TextStyle(color: textColor, fontSize: 20);
    final stats = bundle.ownStats;

    final kdaChanges = bundle.kdaChanges;
    final killsChanges = bundle.ownKillsChanges;
    final deathsChanges = bundle.ownDeatchChanges;
    final assistsChanges = bundle.ownAssistsChanges;
    return [
      Expanded(
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My KDA',
            style: TextStyle(
                color: textColor, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          Text('${stats.matches} matches',
              style: const TextStyle(
                  color: _colorBlue, fontSize: 14, fontWeight: FontWeight.w500))
        ],
      )),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            formatDouble(stats.kda),
            style: TextStyle(
                color: kdaChanges != null
                    ? (kdaChanges > 0 ? _colorBlue : _colorRed)
                    : textColor,
                fontWeight: FontWeight.w500,
                fontSize: 20),
          ),
          if (kdaChanges != null && kdaChanges != 0) ...[
            _createDirectionIcon(positive: kdaChanges > 0)
          ]
        ],
      ),
      const SizedBox(
        width: 16,
      ),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(stats.ownKills.toString(), style: textStyle),
          if (killsChanges != null && killsChanges > 0) ...[
            _createChangesWidget(killsChanges, positive: true)
          ],
          Text(' / ', style: textStyle),
          Text(stats.ownDeaths.toString(), style: textStyle),
          if (deathsChanges != null && deathsChanges > 0) ...[
            _createChangesWidget(deathsChanges, positive: false)
          ],
          Text(' / ', style: textStyle),
          Text(stats.ownAssists.toString(), style: textStyle),
          if (assistsChanges != null && assistsChanges > 0) ...[
            _createChangesWidget(assistsChanges, positive: true)
          ]
        ],
      ),
      const SizedBox(
        width: 16,
      )
    ];
  }

  Widget _createDirectionIcon({required bool positive}) {
    return Image.asset(
      positive ? Assets.assetsIcValueUp : Assets.assetsIcValueDown,
      filterQuality: FilterQuality.medium,
      width: 12,
      height: 12,
      color: positive ? _colorBlue : _colorRed,
    );
  }

  Widget _createChangesWidget(int value, {bool positive = true}) {
    return Text(value.toString(),
        style: TextStyle(
            color: positive ? _colorBlue : _colorRed,
            fontSize: 14,
            fontWeight: FontWeight.bold));
  }

  static const _colorBlue = Color(0xFF1592E4);
  static const _colorRed = Color(0xFFAC2F30);

  Widget _createIconifiedContaner(
      {required String icon,
      required List<Widget> children,
      required Color color}) {
    const cornerStyles = RectangleCornerStyles.all(CornerStyle.straight);

    const border = RectangleShapeBorder(
      borderRadius: DynamicBorderRadius.all(
          DynamicRadius.circular(Length(50, unit: LengthUnit.percent))),
      cornerStyles: cornerStyles,
    );

    const size = 84.0;
    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        Row(
          children: [
            const SizedBox(
              width: size / 2,
            ),
            Expanded(
                child: Container(
              constraints: const BoxConstraints(minHeight: 56),
              decoration: _createConcaveDecoration(color: color, radius: 8),
              child: Row(
                children: [
                  const SizedBox(
                    width: size / 2,
                  ),
                  ...children
                ],
              ),
            ))
          ],
        ),
        Container(
          padding: const EdgeInsets.all(size * .05),
          height: size,
          width: size,
          decoration: ShapeDecoration(shape: border, color: color),
          child: Image.asset(
            icon,
            filterQuality: FilterQuality.medium,
          ),
        ),
      ],
    );
  }

  ShapeDecoration _createConcaveDecoration(
      {required Color color, required double radius}) {
    const cornerStyles = RectangleCornerStyles.all(CornerStyle.concave);

    final border = RectangleShapeBorder(
      borderRadius:
          DynamicBorderRadius.all(DynamicRadius.circular(Length(radius))),
      cornerStyles: cornerStyles,
    );

    return ShapeDecoration(shape: border, color: color);
  }

  Widget _createPlayerWidget(HuntPlayer player, {Color? textColor}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(player.username,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            )),
        const SizedBox(
          height: 4,
        ),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(
              image: DecorationImage(
                  image: AssetImage(Assets.assetsBgMmr),
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.medium)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _createStarWidget(Mmr.star1.getFilled(player.mmr)),
              _createStarWidget(Mmr.star2.getFilled(player.mmr)),
              _createStarWidget(Mmr.star3.getFilled(player.mmr)),
              _createStarWidget(Mmr.star4.getFilled(player.mmr)),
              _createStarWidget(Mmr.star5.getFilled(player.mmr)),
              _createStarWidget(Mmr.star6.getFilled(player.mmr))
            ],
          ),
        )
      ],
    );
  }

  Widget _createStarWidget(double fill, {double size = 16}) {
    return SizedBox(
      height: size,
      width: size,
      child: Stack(
        children: [
          Image.asset(
            Assets.assetsCrossWhite24dp,
            width: size,
            height: size,
            filterQuality: FilterQuality.medium,
            color: Colors.black,
          ),
          SizedBox(
            height: size,
            width: size * fill,
            child: Image.asset(
              Assets.assetsCrossWhite24dp,
              alignment: Alignment.centerLeft,
              fit: BoxFit.fitHeight,
              height: size,
              filterQuality: FilterQuality.medium,
              width: size * fill,
              color: const Color(0xFFCEB379),
            ),
          )
        ],
      ),
    );
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
