import 'dart:io';

import 'package:tray_manager/tray_manager.dart' as tray;
import 'package:win32/win32.dart';

import 'window/window.dart';

tray.TrayIcon createTrayIcon(WinWindow window) {
  final icon =
      tray.TrayIcon.create() ??
      (throw StateError('Could not create the tray icon'));
  try {
    icon.icon =
        tray.ImageAsset.fromAsset('assets/icon.ico') ??
        (throw StateError('Could not load assets/icon.ico'));
    icon.setTooltip('Hunt: Stats');

    void showWindow() {
      if (IsIconic(window.handle)) window.restore();
      window.show();
    }

    final menu =
        tray.Menu.create() ??
        (throw StateError('Could not create the tray menu'));
    final showItem =
        tray.MenuItem.createWithLabelAndType(
          'Show',
          tray.MenuItemType.normal,
        ) ??
        (throw StateError('Could not create the Show menu item'));
    showItem.addListener((event) {
      if (event is tray.MenuItemClickedEvent) showWindow();
    });
    final exitItem =
        tray.MenuItem.createWithLabelAndType(
          'Exit',
          tray.MenuItemType.normal,
        ) ??
        (throw StateError('Could not create the Exit menu item'));
    exitItem.addListener((event) {
      if (event is tray.MenuItemClickedEvent) {
        icon.dispose();
        exit(0);
      }
    });
    menu.addItem(showItem);
    menu.addSeparator();
    menu.addItem(exitItem);
    icon.setContextMenu(menu);
    icon.setContextMenuTrigger(tray.ContextMenuTrigger.rightClicked);
    icon.addListener((event) {
      if (event is tray.TrayIconClickedEvent ||
          event is tray.TrayIconDoubleClickedEvent) {
        showWindow();
      }
    });
    if (!icon.setVisible(true)) {
      throw StateError('Could not show the tray icon');
    }
    return icon;
  } catch (_) {
    icon.dispose();
    rethrow;
  }
}
