import 'dart:ffi' hide Size;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hunt_stats/window/icons/icons.dart';
import 'package:hunt_stats/window/native_api.dart';
import 'package:hunt_stats/window/widgets/mouse_state_builder.dart';
import 'package:hunt_stats/window/window_util.dart';
import 'package:win32/win32.dart';

void main() {
  test('FFI payload layouts match the C++ definitions', () {
    expect(sizeOf<SWPParam>(), 20);
    expect(sizeOf<SWTParam>(), sizeOf<Pointer<Void>>());
    expect(sizeOf<BDWPublicAPI>(), 7 * sizeOf<Pointer<Void>>());
  });

  test(
    'window alignment uses monitor coordinates, including negative origins',
    () {
      const screen = Rect.fromLTWH(-1920, -200, 1920, 1080);
      const size = Size(368, 56);
      expect(
        getRectOnScreen(size, Alignment.topLeft, screen),
        const Rect.fromLTWH(-1920, -200, 368, 56),
      );
      expect(
        getRectOnScreen(size, Alignment.bottomLeft, screen),
        const Rect.fromLTWH(-1920, 824, 368, 56),
      );
      expect(
        getRectOnScreen(size, Alignment.bottomRight, screen),
        const Rect.fromLTWH(-368, 824, 368, 56),
      );
      expect(
        getRectOnScreen(size, Alignment.center, screen),
        const Rect.fromLTWH(-1144, 312, 368, 56),
      );
      expect(
        getRectOnScreen(size, const Alignment(0.5, -0.5), screen),
        const Rect.fromLTWH(-756, 56, 368, 56),
      );
    },
  );

  test('failed posts to an invalid window do not crash', () {
    final invalid = HWND(Pointer.fromAddress(-1));
    expect(IsWindow(invalid), isFalse);
    for (var i = 0; i < 100; i++) {
      setWindowPos(invalid, 0, 0, 368, 56, SWP_NOZORDER);
      setWindowText(invalid, 'Hunt — Statistics');
    }
  }, skip: !Platform.isWindows);

  for (final (name, icon) in <(String, Widget Function(Color))>[
    ('maximize', (color) => MaximizeIcon(color: color)),
    ('minimize', (color) => MinimizeIcon(color: color)),
    ('restore', (color) => RestoreIcon(color: color)),
  ]) {
    testWidgets('$name icon repaints when its color changes', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: icon(Colors.red),
        ),
      );
      final previous = tester
          .widget<CustomPaint>(find.byType(CustomPaint))
          .painter!;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: icon(Colors.blue),
        ),
      );
      final current = tester
          .widget<CustomPaint>(find.byType(CustomPaint))
          .painter!;
      expect(current.shouldRepaint(previous), isTrue);
    });
  }

  testWidgets('disposed mouse builder does not invoke a deferred action', (
    tester,
  ) async {
    var clicks = 0;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MouseStateBuilder(
          onPressed: () => clicks++,
          builder: (_, _) => const SizedBox.expand(),
        ),
      ),
    );
    await tester.tap(find.byType(MouseStateBuilder));
    await tester.pumpWidget(const SizedBox.shrink());
    expect(clicks, 0);
    expect(tester.takeException(), isNull);
  });
}
