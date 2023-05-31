import 'dart:async';
import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:bitsdojo_window_platform_interface/window.dart';
import 'package:flutter/material.dart';
import 'package:hunt_stats/border/corners.dart';
import 'package:hunt_stats/border/gradient_box_border.dart';
import 'package:hunt_stats/db/entities.dart';
import 'package:hunt_stats/db/stats.dart';
import 'package:hunt_stats/db/stats_db.dart';
import 'package:hunt_stats/generated/assets.dart';
import 'package:hunt_stats/hunt_bundle.dart';
import 'package:hunt_stats/hunt_images.dart';
import 'package:hunt_stats/mmr.dart';
import 'package:hunt_stats/tracker.dart';
import 'package:morphable_shape/morphable_shape.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:system_tray/system_tray.dart' as tray;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await HuntImages.init();

  final db = StatsDb();
  final tracker = TrackerEngine(db);

  runApp(MyApp(engine: tracker));

  await tracker.start();

  doWhenWindowReady(() {
    final window = appWindow;

    const initialSize = Size(362, 320);
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

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PlayersPager(
                  teammates: teammates,
                  me: bundle.me,
                  textColor: textColor,
                  enemies: bundle.enemyStats,
                  cardColor: _getBlockColor()),
              _createIconifiedContaner(
                  icon: Assets.assetsIcKda,
                  children: _createMyKdaWidgets(bundle, textColor: textColor)),
              _createIconifiedContaner(
                  icon: Assets.assetsIcKd,
                  children: _createTeamKdWidgets(bundle, textColor: textColor)),
              if (size.height > 440) ...[
                const SizedBox(
                  height: 32,
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Dale Style',
                      style: TextStyle(color: textColor, fontSize: 16),
                    ),
                    Switch(
                        value: _zupaman,
                        onChanged: (checked) {
                          setState(() {
                            _zupaman = checked;
                          });
                        }),
                    const Text(
                      'Zupaman',
                      style: TextStyle(color: textColor, fontSize: 16),
                    )
                  ],
                ),
                const SizedBox(
                  height: 16,
                ),
                ElevatedButton(
                    onPressed: _handleResetClick, child: const Text('Reset')),
                const SizedBox(
                  height: 16,
                )
              ]
            ],
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
                color: kdChanges != null && kdChanges != 0
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
                color: kdaChanges != null && kdaChanges != 0
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

  bool _zupaman = true;

  Decoration _createBlockDecoration() {
    if (_zupaman) {
      return BoxDecoration(
        color: const Color(0xFF282B31),
        border: GradientBoxBorder(
          corners: Corners(
              topRight: HuntImages.cornerTopRight,
              bottomRight: HuntImages.cornerBottomRight),
          gradient: LinearGradient(colors: [
            const Color(0xFF595A5C).withOpacity(0.1),
            const Color(0xFFE7E7E7),
            const Color(0xFF595A5C),
          ]),
          width: 2,
        ),
      );
    } else {
      return _createConcaveDecoration(color: _getBlockColor(), radius: 8);
    }
  }

  Color _getBlockColor() {
    if (_zupaman) {
      return const Color(0xFF282B31);
    } else {
      return const Color(0xFF090909);
    }
  }

  Widget _createIconifiedContaner(
      {required String icon, required List<Widget> children}) {
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
              decoration: _createBlockDecoration(),
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
          padding: const EdgeInsets.all(size * .1),
          height: size,
          width: size,
          decoration: ShapeDecoration(shape: border, color: _getBlockColor()),
          child: Image.asset(
            icon,
            filterQuality: FilterQuality.medium,
          ),
        ),
      ],
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

class MyTeamWidget extends StatelessWidget {
  final Iterable<HuntPlayer> teammates;
  final Color? textColor;
  final Color cardColor;

  const MyTeamWidget(
      {super.key,
      required this.teammates,
      required this.textColor,
      required this.cardColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: _createConcaveDecoration(color: cardColor, radius: 8),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          const SizedBox(
            width: 4,
          ),
          ...teammates.map((e) => Expanded(
                  child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: PlayerWidget(
                  player: e,
                  textColor: textColor,
                ),
              ))),
          const SizedBox(
            width: 4,
          )
        ],
      ),
    );
  }
}

class _PlayersPager extends StatefulWidget {
  final Iterable<HuntPlayer> teammates;
  final HuntPlayer? me;
  final List<EnemyStats> enemies;
  final Color cardColor;
  final Color? textColor;

  const _PlayersPager(
      {required this.enemies,
      required this.cardColor,
      required this.teammates,
      required this.me,
      this.textColor});

  @override
  State<StatefulWidget> createState() => _PlayersState();
}

const _colorBlue = Color(0xFF1592E4);
const _colorRed = Color(0xFFAC2F30);

Widget _createChangesWidget(int value, {bool positive = true}) {
  return Text(value.toString(),
      style: TextStyle(
          color: positive ? _colorBlue : _colorRed,
          fontSize: 14,
          fontWeight: FontWeight.bold));
}

class EnemyCardWidget extends StatelessWidget {
  final HuntPlayer? me;
  final EnemyStats stats;
  final Color? textColor;
  final Color cardColor;

  const EnemyCardWidget(
      {super.key,
      required this.me,
      required this.stats,
      required this.textColor,
      required this.cardColor});

  @override
  Widget build(BuildContext context) {
    final bigTextStyle = TextStyle(fontSize: 20, color: textColor);
    return Stack(
      alignment: AlignmentDirectional.bottomEnd,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          height: double.infinity,
          decoration: _createConcaveDecoration(color: cardColor, radius: 8),
          child: Row(
            children: [
              const SizedBox(
                width: 4,
              ),
              Expanded(
                child: PlayerWidget(
                  player: stats.player,
                  textColor: textColor,
                ),
              ),
              const SizedBox(
                width: 4,
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stats.killedMe.toString(),
                    style: bigTextStyle,
                  ),
                  if (stats.killedMeLastMatch > 0) ...[
                    _createChangesWidget(stats.killedMeLastMatch)
                  ]
                ],
              ),
              Text(
                ' - ',
                style: bigTextStyle,
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stats.killedByMe.toString(),
                    style: bigTextStyle,
                  ),
                  if (stats.killedByMeLastMatch > 0) ...[
                    _createChangesWidget(stats.killedByMeLastMatch)
                  ]
                ],
              ),
              const SizedBox(
                width: 4,
              ),
              Expanded(
                child: PlayerWidget(
                  player: me,
                  textColor: textColor,
                ),
              ),
              const SizedBox(
                width: 4,
              ),
            ],
          ),
        ),
        Image.asset(
          Assets.assetsCornerEnemy,
          height: 72,
          width: 72,
          filterQuality: FilterQuality.medium,
        )
      ],
    );
  }
}

class _PlayersState extends State<_PlayersPager> {
  late final PageController _controller;
  late final Timer _timer;

  int _pageIndex = 0;

  @override
  void initState() {
    _controller = PageController(keepPage: true, initialPage: _pageIndex);

    _timer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (_pages == 0) return;

      final current = _pageIndex;

      if (current == _pages - 1) {
        _controller.animateToPage(0,
            duration: const Duration(milliseconds: 250), curve: Curves.easeIn);
      } else {
        _controller.nextPage(
            duration: const Duration(milliseconds: 250), curve: Curves.easeIn);
      }
    });

    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer.cancel();
    super.dispose();
  }

  int get _pages => widget.enemies.length + 1;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      width: double.infinity,
      child: Column(
        children: [
          Expanded(
              child: PageView(
            controller: _controller,
            onPageChanged: (index) => _pageIndex = index,
            children: [
              MyTeamWidget(
                  teammates: widget.teammates,
                  textColor: widget.textColor,
                  cardColor: widget.cardColor),
              ...widget.enemies
                  .map((e) => EnemyCardWidget(
                        stats: e,
                        cardColor: widget.cardColor,
                        textColor: widget.textColor,
                        me: widget.me,
                      ))
                  .toList()
            ],
          )),
          if (_pages > 1) ...[
            const SizedBox(
              height: 8,
            ),
            SmoothPageIndicator(
                controller: _controller, // PageController
                count: _pages,
                onDotClicked: (index) => _controller.animateToPage(index,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeIn),
                effect: const WormEffect(
                    dotColor: Colors.white,
                    dotHeight: 8,
                    dotWidth: 8,
                    spacing: 4,
                    activeDotColor: Color(0xFFCEB379))),
          ] else ...[
            const SizedBox(
              height: 16,
            ),
          ]
        ],
      ),
    );
  }
}

extension Ex on double {
  double toPrecision(int n) => double.parse(toStringAsFixed(n));
}

class PlayerWidget extends StatelessWidget {
  final HuntPlayer? player;
  final Color? textColor;

  const PlayerWidget({super.key, required this.player, this.textColor});

  @override
  Widget build(BuildContext context) {
    final mmr = player?.mmr ?? -1;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(player?.username ?? 'Me',
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _createStarWidget(Mmr.star1.getFilled(mmr)),
              _createStarWidget(Mmr.star2.getFilled(mmr)),
              _createStarWidget(Mmr.star3.getFilled(mmr)),
              _createStarWidget(Mmr.star4.getFilled(mmr)),
              _createStarWidget(Mmr.star5.getFilled(mmr)),
              _createStarWidget(Mmr.star6.getFilled(mmr))
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
            color: const Color(0xFF939598).withOpacity(0.5),
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
}
