import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:hunt_stats/tray.dart';
import 'package:hunt_stats/window/window.dart';
import 'package:tray_manager/tray_manager.dart' as tray;

// Run with: flutter run -d windows --release --no-resident -t tool/window_smoke.dart
Future<void> main() async {
  final results = <String>[];
  final report = File('.dart_tool/window_smoke_result.json');
  tray.TrayIcon? trayIcon;
  try {
    WidgetsFlutterBinding.ensureInitialized();
    runApp(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox.shrink(),
      ),
    );
    await doWhenWindowReady(() {
      final window = appWindow;
      results.add('native FFI initialization');
      window.minSize = const Size(200, 100);
      window.maxSize = const Size(800, 600);
      window.size = const Size(400, 180);
      window.alignment = Alignment.center;
      window.title = 'Hunt — Statistics';
    });
    final window = appWindow;
    trayIcon = createTrayIcon(window);
    _check(trayIcon.isVisible(), 'tray icon visibility');
    _check(trayIcon.getTooltip() == 'Hunt: Stats', 'tray tooltip');
    _check(trayIcon.icon != null, 'bundled tray icon');
    _check(
      trayIcon.getContextMenuTrigger() == tray.ContextMenuTrigger.rightClicked,
      'right-click context menu',
    );
    final menu = trayIcon.getContextMenu();
    _check(menu?.itemCount == 3, 'tray menu item count');
    _check(menu?.getItemAt(0)?.label == 'Show', 'Show menu item');
    _check(menu?.getItemAt(2)?.label == 'Exit', 'Exit menu item');
    results.add('tray icon, tooltip, Show/Exit menu, right-click trigger');
    await _settle();
    _checkSize(window.size, const Size(400, 180));
    results.add('aligned size and Unicode title');

    window.alignment = null;
    window.size = const Size(420, 200);
    await _settle();
    _checkSize(window.size, const Size(420, 200));
    results.add('DPI-scaled size without alignment');

    window.size = const Size(50, 50);
    await _settle();
    _checkSize(window.size, const Size(200, 100));
    window.minSize = null;
    window.maxSize = null;
    window.size = const Size(400, 180);
    await _settle();
    results.add('size limits and resetting limits');

    window.show();
    await _settle();
    _check(window.isVisible, 'show');
    window.maximize();
    await _settle();
    _check(window.isMaximized, 'maximize');
    window.restore();
    await _settle();
    _check(!window.isMaximized, 'restore');
    window.minimize();
    await _settle();
    window.restore();
    await _settle();
    window.hide();
    await _settle();
    _check(!window.isVisible, 'hide');
    results.add('show, maximize, restore, minimize, hide');

    window.close();
    await _settle();
    _check(!window.isVisible, 'close to tray');
    _check(trayIcon.isVisible(), 'tray stays visible after closing the window');
    results.add('close to tray');
    trayIcon.dispose();
    trayIcon = null;
    results.add('tray disposal');
    await report.writeAsString(jsonEncode({'passed': results}));
    exit(0);
  } catch (error, stack) {
    trayIcon?.dispose();
    await report.writeAsString(
      jsonEncode({
        'passed': results,
        'error': error.toString(),
        'stack': stack.toString(),
      }),
    );
    exit(1);
  }
}

Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 150));

void _check(bool condition, String operation) {
  if (!condition) throw StateError('Window operation failed: $operation');
}

void _checkSize(Size actual, Size expected) {
  _check(
    (actual.width - expected.width).abs() <= 1 &&
        (actual.height - expected.height).abs() <= 1,
    'size ${actual.width}x${actual.height} != ${expected.width}x${expected.height}',
  );
}
