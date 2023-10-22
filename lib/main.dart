import 'dart:async';
import 'dart:io';

import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:bitsdojo_window_platform_interface/window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hunt_stats/auto_launcher_windows.dart';
import 'package:hunt_stats/constants.dart';
import 'package:hunt_stats/db/entities.dart';
import 'package:hunt_stats/db/stats_db.dart';
import 'package:hunt_stats/extensions.dart';
import 'package:hunt_stats/generated/assets.dart';
import 'package:hunt_stats/hunt_bundle.dart';
import 'package:hunt_stats/hunt_images.dart';
import 'package:hunt_stats/mmr.dart';
import 'package:hunt_stats/tracker.dart';
import 'package:morphable_shape/morphable_shape.dart';
import 'package:system_tray/system_tray.dart' as tray;

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  await HuntImages.init();

  final db = StatsDb(predefinedProfileId: Constants.profileId);
  final tracker = TrackerEngine(db, listenGameLog: true);

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
    return Scaffold(
      backgroundColor: backgroundColor,
      body: _createContentWidget(context),
    );
  }

  Widget _createContentWidget(BuildContext context) {
    const textColor = Colors.white;
    final size = MediaQuery.of(context).size;

    return StreamBuilder<HuntBundle?>(
      initialData: widget.engine.lastBundle,
      stream: widget.engine.lastMatch,
      builder: (cntx, snapshot) {
        final bundle = snapshot.data;

        if (bundle == null) {
          return Container();
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SimplePlayerWidget(player: bundle.me, textColor: textColor, bgColor: _blockColor,),
            const Expanded(child: SizedBox.shrink()),
            Container(
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.only(left: 8, right: 16),
              color: _blockColor,
              child: Row(
                children: [
                  Image.asset(Assets.assetsIcKda, width: 48, height: 48,),
                  const SizedBox(width: 4,),
                  ... _createMyKdaWidgets(bundle, textColor: textColor)
                ],
              ),
            ),
            if (size.height > 486) ...[
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
          Row(mainAxisSize: MainAxisSize.min, children: [
            ElevatedButton(
                onPressed: _handleResetAllClick,
                child: Text(context.localizations.button_reset_all)),
          ]),
        ],
      ),
    );
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
      Text(
        'KDA',
        style: TextStyle(
            color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
      ),
      const SizedBox(width: 8,),
      Expanded(
          child:
              Text('(${context.localizations.matches_count(stats.matches)})',
                  style: const TextStyle(
                      color: _colorBlue, fontSize: 14, fontWeight: FontWeight.w500)
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

  Decoration _createBlockDecoration() {
    return _createConcaveDecoration(color: _blockColor, radius: 8);
  }

  Color get _blockColor => const Color(0xFF090909);

  static String formatDouble(double value,
      {int precision = 2, bool plusIfPositive = false}) {
    if (value.isNaN) {
      return '';
    }
    if (value.isInfinite) {
      return value.isNegative ? '-∞' : '∞';
    }
    final formatted = value.toPrecision(precision).toString();
    return plusIfPositive && value > 0 ? '+$formatted' : formatted;
  }

  void _handleResetAllClick() async {
    await widget.engine.invalidateMatches();

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

const _colorBlue = Color(0xFF1592E4);
const _colorRed = Color(0xFFAC2F30);

Widget _createChangesWidget(int value, {bool positive = true}) {
  return Text(value.toString(),
      style: TextStyle(
          color: positive ? _colorBlue : _colorRed,
          fontSize: 14,
          fontWeight: FontWeight.bold));
}

extension Ex on double {
  double toPrecision(int n) => double.parse(toStringAsFixed(n));
}

class SimplePlayerWidget extends StatelessWidget {

  final Color? bgColor;
  final PlayerEntity? player;
  final Color? textColor;

  const SimplePlayerWidget({super.key, this.player, this.textColor, this.bgColor});

  @override
  Widget build(BuildContext context) {
    final mmr = player?.mmr ?? -1;
    return Container(
      color: bgColor,
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(player?.username ?? context.localizations.me,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              )),
          const Expanded(child: SizedBox.shrink()),
          _createStarWidget(Mmr.star1.getFilled(mmr)),
          _createStarWidget(Mmr.star2.getFilled(mmr)),
          _createStarWidget(Mmr.star3.getFilled(mmr)),
          _createStarWidget(Mmr.star4.getFilled(mmr)),
          _createStarWidget(Mmr.star5.getFilled(mmr)),
          _createStarWidget(Mmr.star6.getFilled(mmr))
        ],
      ),
    );
  }
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