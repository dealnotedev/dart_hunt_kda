import 'dart:io';

import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:bitsdojo_window_platform_interface/window.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hunt_stats/auto_launcher_windows.dart';
import 'package:hunt_stats/extensions.dart';
import 'package:hunt_stats/generated/assets.dart';
import 'package:hunt_stats/hunt_bundle.dart';
import 'package:hunt_stats/l10n/app_localizations.dart';
import 'package:hunt_stats/mmr.dart';
import 'package:hunt_stats/tracker.dart';
import 'package:system_tray/system_tray.dart' as tray;

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  final tracker =
      TrackerEngine(updateInterval: const Duration(seconds: 1), mapSounds: true)
        ..startTracking();

  runApp(MyApp(engine: tracker));

  doWhenWindowReady(() {
    final window = appWindow;

    const initialSize = Size(368, 56);
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
      home: MyHomePage(engine: engine),
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
      backgroundColor: const Color(0xFF090909),
      body: MoveWindow(
        child: _createContentWidget(context),
      ),
    );
  }

  Widget _createContentWidget(BuildContext context) {
    const textColor = Colors.white;

    return StreamBuilder<HuntBundle>(
      initialData: widget.engine.bundle.current,
      stream: widget.engine.bundle.changes,
      builder: (cntx, snapshot) {
        final bundle = snapshot.requireData;

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              alignment: Alignment.center,
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.only(left: 8, right: 16),
              color: _blockColor,
              width: double.infinity,
              child: Row(
                children: [
                  const Gap(8),
                  ..._createMyKdaWidgets(bundle, textColor: textColor)
                ],
              ),
            )
          ],
        );
      },
    );
  }

  Widget _createDotsWidget(HuntBundle bundle, {required Color textColor}) {
    final history = <bool?>[];
    history.addAll(bundle.history);

    if (history.length < 10) {
      final add = 10 - history.length;
      for (int i = 0; i < add; i++) {
        history.add(null);
      }
    }

    return Wrap(
      spacing: 2,
      runSpacing: 2,
      children: [...history.map((r) => _createMatchResult(r))],
    );
  }

  Widget _createMatchResult(bool? success) {
    return Container(
      width: 8,
      height: 5,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        color: success != null
            ? (success ? _colorBlue : _colorRed)
            : Colors.white.withValues(alpha: 0.15),
      ),
    );
  }

  List<Widget> _createMyKdaWidgets(HuntBundle bundle,
      {required Color textColor}) {
    final textStyle = TextStyle(color: textColor, fontSize: 20);

    final kdaChanges = bundle.kdaChanges;
    final killsChanges = bundle.killsChanges;
    final deathsChanges = bundle.deatchChanges;
    //final assistsChanges = bundle.assistsChanges;

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
          Row(
            children: [
              Text(
                'K/D',
                style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              const Gap(8),
              Expanded(
                  child: Text(
                      '(${context.localizations.matches_count(bundle.matches)})',
                      style: const TextStyle(
                          color: _colorBlue,
                          fontSize: 14,
                          fontWeight: FontWeight.w500))),
            ],
          ),
          const Gap(2),
          _createDotsWidget(bundle, textColor: textColor)
        ],
      )),
      const Gap(8),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (bundle.kda.isFinite) ...[
            AnimatedFlipCounter(
              value: bundle.kda,
              fractionDigits: 2,
              duration: const Duration(seconds: 1),
              textStyle: kdaStyle,
            )
          ] else ...[
            Text(
              formatDouble(bundle.kda),
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
          Text(bundle.totalKills.toString(), style: textStyle),
          if (killsChanges != null) ...[
            _createChangesWidget(killsChanges, positive: true)
          ],
          Text(_spacedSlash(trimLeft: killsChanges != null), style: textStyle),
          Text(bundle.totalDeaths.toString(), style: textStyle),
          if (deathsChanges != null) ...[
            _createChangesWidget(deathsChanges, positive: false)
          ],
          /*Text(_spacedSlash(trimLeft: deathsChanges != null), style: textStyle),
          Text(bundle.totalAssists.toString(), style: textStyle),
          if (assistsChanges != null) ...[
            _createChangesWidget(assistsChanges, positive: true)
          ]*/
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
  final int mmr;
  final Color? textColor;

  const SimplePlayerWidget(
      {super.key, required this.mmr, this.textColor, this.bgColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: bgColor,
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text('dealnote.dev',
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
          color: const Color(0xFF939598).withValues(alpha: 0.5),
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
