import 'dart:async';
import 'dart:io';

import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:bitsdojo_window_platform_interface/window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hunt_stats/auto_launcher_windows.dart';
import 'package:hunt_stats/border/corners.dart';
import 'package:hunt_stats/border/gradient_box_border.dart';
import 'package:hunt_stats/constants.dart';
import 'package:hunt_stats/db/entities.dart';
import 'package:hunt_stats/db/stats.dart';
import 'package:hunt_stats/db/stats_db.dart';
import 'package:hunt_stats/extensions.dart';
import 'package:hunt_stats/generated/assets.dart';
import 'package:hunt_stats/hunt_bundle.dart';
import 'package:hunt_stats/hunt_images.dart';
import 'package:hunt_stats/mmr.dart';
import 'package:hunt_stats/tracker.dart';
import 'package:morphable_shape/morphable_shape.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:system_tray/system_tray.dart' as tray;

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  await HuntImages.init();

  final db = StatsDb(predefinedProfileId: Constants.profileId);
  final tracker = TrackerEngine(db);

  //final data = await tracker
  //    .extractFromFile(File('examples/attributes_zoop_duo_win.xml'));
  //await File('json.json').writeAsString(json.encode(data));

  runApp(MyApp(engine: tracker));

  await tracker.start();

  doWhenWindowReady(() {
    final window = appWindow;

    const initialSize = Size(368, 320);
    window.minSize = initialSize;
    window.size = initialSize;
    window.alignment = Alignment.center;
    window.show();

    if (args.contains('-silent')) {
      window.close();
    } else {
      window.show();
    }

    _startSystemTray(window);
  });
}

final launcher = AppAutoLauncherImplWindows(
    appName: 'Hunt: Stats',
    appPath: Platform.resolvedExecutable,
    args: ['-silent']);

final _starupPublisher = StreamController<bool>.broadcast();

Stream<bool> _autostart() async* {
  final enabled = await launcher.isEnabled();
  yield enabled;

  yield* _starupPublisher.stream;
}

void _setStartupEnabled(bool enabled) async {
  if (enabled) {
    await launcher.enable();
  } else {
    await launcher.disable();
  }
  _starupPublisher.add(enabled);
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
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
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
            return Center(
              child: Text(
                context.localizations.stats_empty_text,
                style: const TextStyle(color: textColor, fontSize: 48),
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
                  cardColor: _blockColor),
              _createIconifiedContaner(
                  icon: _zupaman ? Assets.assetsIcKdaV2 : Assets.assetsIcKda,
                  children: _createMyKdaWidgets(bundle, textColor: textColor)),
              _createIconifiedContaner(
                  icon: _zupaman ? Assets.assetsIcKdV2 : Assets.assetsIcKd,
                  children: _createTeamKdWidgets(bundle, textColor: textColor)),
              if (size.height > 484) ...[
                const SizedBox(
                  height: 16,
                ),
                _createSettingsWidget(context,
                    bundle: bundle, textColor: textColor),
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

  Widget _createSettingsWidget(BuildContext context,
      {Color? textColor, required HuntBundle bundle}) {
    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: _createBlockDecoration(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.localizations.style_dale_title,
                style: TextStyle(color: textColor, fontSize: 16),
              ),
              Switch(
                  value: _zupaman,
                  onChanged: (checked) {
                    setState(() {
                      _zupaman = checked;
                    });
                  }),
              Text(
                context.localizations.style_zupaman,
                style: TextStyle(color: textColor, fontSize: 16),
              )
            ],
          ),
          StreamBuilder<bool>(
              stream: _autostart(),
              builder: (cnxt, snapshot) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.localizations.startup_off_text,
                      style: TextStyle(color: textColor, fontSize: 16),
                    ),
                    Switch(
                        value: snapshot.data ?? false,
                        onChanged: _setStartupEnabled),
                    Text(
                      context.localizations.startup_on_text,
                      style: TextStyle(color: textColor, fontSize: 16),
                    )
                  ],
                );
              }),
          const SizedBox(
            height: 16,
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                  onPressed: _handleResetAllClick,
                  child: Text(context.localizations.button_reset_all)),
              const SizedBox(
                width: 8,
              ),
              ElevatedButton(
                  onPressed: () => _handleResetTeamClick(bundle.teamId),
                  child: Text(context.localizations.button_reset_team))
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _createTeamKdWidgets(HuntBundle bundle,
      {required Color textColor}) {
    final textStyle = TextStyle(color: textColor, fontSize: 18);

    final stats = bundle.teamStats;
    final kdChanges = bundle.teamKdChanges;
    final killsChanges = bundle.teamKillsChanges;
    final deathsChanges = bundle.teamDeathsChanges;

    final kdStyle = TextStyle(
        color: kdChanges != null && kdChanges != 0
            ? (kdChanges > 0 ? _colorBlue : _colorRed)
            : textColor,
        fontWeight: FontWeight.w500,
        fontSize: 20);

    return [
      Expanded(
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.localizations.team_kd_title,
            style: TextStyle(
                color: textColor, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          Text(context.localizations.matches_count(stats.matches),
              style: const TextStyle(
                  color: _colorBlue, fontSize: 14, fontWeight: FontWeight.w500))
        ],
      )),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (stats.kd.isFinite) ...[
            AnimatedFlipCounter(
              value: stats.kd,
              fractionDigits: 2,
              textStyle: kdStyle,
              duration: const Duration(seconds: 1),
            )
          ] else ...[
            Text(
              formatDouble(stats.kd),
              style: kdStyle,
            )
          ],
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
          if (killsChanges != null) ...[
            _createChangesWidget(killsChanges, positive: true)
          ],
          Text(_spacedSlash(trimLeft: killsChanges != null), style: textStyle),
          Text(stats.teamDeaths.toString(), style: textStyle),
          if (deathsChanges != null) ...[
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

    final hasDirectionIcon = kdaChanges != null && kdaChanges != 0;
    final kdaStyle = TextStyle(
        color: kdaChanges != null && kdaChanges != 0
            ? (kdaChanges > 0 ? _colorBlue : _colorRed)
            : textColor,
        fontWeight: FontWeight.w500,
        fontSize: 20);

    return [
      Expanded(
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.localizations.my_kda_title,
            style: TextStyle(
                color: textColor, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          Text(context.localizations.matches_count(stats.matches),
              style: const TextStyle(
                  color: _colorBlue, fontSize: 14, fontWeight: FontWeight.w500))
        ],
      )),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (stats.kda.isFinite) ...[
            AnimatedFlipCounter(
              value: stats.kda,
              fractionDigits: 2,
              duration: const Duration(seconds: 1),
              textStyle: kdaStyle,
            )
          ] else ...[
            Text(
              formatDouble(stats.kda),
              style: kdaStyle,
            )
          ],
          if (hasDirectionIcon) ...[
            _createDirectionIcon(positive: kdaChanges > 0)
          ]
        ],
      ),
      SizedBox(
        width: hasDirectionIcon ? 8 : 16,
      ),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(stats.ownKills.toString(), style: textStyle),
          if (killsChanges != null) ...[
            _createChangesWidget(killsChanges, positive: true)
          ],
          Text(_spacedSlash(trimLeft: killsChanges != null), style: textStyle),
          Text(stats.ownDeaths.toString(), style: textStyle),
          if (deathsChanges != null) ...[
            _createChangesWidget(deathsChanges, positive: false)
          ],
          Text(_spacedSlash(trimLeft: deathsChanges != null), style: textStyle),
          Text(stats.ownAssists.toString(), style: textStyle),
          if (assistsChanges != null) ...[
            _createChangesWidget(assistsChanges, positive: true)
          ]
        ],
      ),
      const SizedBox(
        width: 16,
      )
    ];
  }

  static String _spacedSlash({
    bool trimRight = false,
    bool trimLeft = false,
  }) =>
      '${trimLeft ? '' : ' '}/${trimRight ? '' : ' '}';

  Widget _createDirectionIcon({required bool positive}) {
    return Image.asset(
      positive ? Assets.assetsIcValueUp : Assets.assetsIcValueDown,
      filterQuality: FilterQuality.medium,
      width: 12,
      height: 12,
      color: positive ? _colorBlue : _colorRed,
    );
  }

  bool _zupaman = false;

  Decoration _createBlockDecoration() {
    if (_zupaman) {
      return BoxDecoration(
        color: _blockColor,
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
      return _createConcaveDecoration(color: _blockColor, radius: 8);
    }
  }

  Color get _blockColor => const Color(0xFF090909);

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
          decoration: ShapeDecoration(shape: border, color: _blockColor),
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

  void _handleResetAllClick() async {
    await widget.engine.invalidateMatches();

    if (mounted) {
      _showSnackbar(context, text: context.localizations.toast_invalidated);
    }
  }

  void _handleResetTeamClick(String teamId) async {
    await widget.engine.invalidateTeam(teamId);

    if (mounted) {
      _showSnackbar(context, text: context.localizations.toast_invalidated);
    }
  }

  void _showSnackbar(BuildContext context,
      {required String text, Duration? duration}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      backgroundColor: _colorRed,
      duration: duration ?? const Duration(milliseconds: 2000),
      content: Text(
        text,
        style: const TextStyle(color: Colors.white),
      ),
    ));
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
  final Iterable<PlayerEntity> teammates;
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
  final Iterable<PlayerEntity> teammates;
  final PlayerEntity? me;
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
  final PlayerEntity? me;
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
                _spacedHyphen(trimLeft: stats.killedMeLastMatch > 0),
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
        Tooltip(
          message: context.localizations.matches_count(stats.matches),
          textStyle: TextStyle(color: textColor),
          child: Image.asset(
            Assets.assetsCornerEnemy,
            height: 72,
            width: 72,
            filterQuality: FilterQuality.medium,
          ),
        )
      ],
    );
  }

  static String _spacedHyphen({
    bool trimRight = false,
    bool trimLeft = false,
  }) =>
      '${trimLeft ? '' : ' '}/${trimRight ? '' : ' '}';
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
  final PlayerEntity? player;
  final Color? textColor;

  const PlayerWidget({super.key, required this.player, this.textColor});

  @override
  Widget build(BuildContext context) {
    final mmr = player?.mmr ?? -1;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(player?.username ?? context.localizations.me,
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
        Tooltip(
          message: player?.mmr.toString() ?? context.localizations.no_mmr_text,
          child: Container(
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
          ),
        )
      ],
    );
  }

  Widget _createStarWidget(double fill, {double size = 16}) {
    return Container(
      padding: const EdgeInsets.all(1),
      height: size,
      width: size,
      child: Stack(
        children: [
          Image.asset(
            Assets.assetsCrossWhite20dp,
            width: size,
            height: size,
            filterQuality: FilterQuality.medium,
            color: const Color(0xFF939598).withOpacity(0.5),
          ),
          SizedBox(
            height: size,
            width: size * fill,
            child: Image.asset(
              Assets.assetsCrossWhite20dp,
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
