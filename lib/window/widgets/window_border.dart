import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../window.dart';

class WindowBorder extends StatelessWidget {
  final Widget child;
  final Color color;
  final double? width;

  const WindowBorder({
    super.key,
    required this.child,
    required this.color,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    bool isWindowsApp =
        (!kIsWeb) && (defaultTargetPlatform == TargetPlatform.windows);
    if (!isWindowsApp) {
      return child;
    }

    var borderWidth = width ?? 1;
    var topBorderWidth = width ?? 1;

    appWindow.setWindowCutOnMaximize(borderWidth.ceil());

    if (isWindowsApp) {
      topBorderWidth += 1 / appWindow.scaleFactor;
    }
    final topBorderSide = BorderSide(color: color, width: topBorderWidth);
    final borderSide = BorderSide(color: color, width: borderWidth);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: topBorderSide,
          left: borderSide,
          right: borderSide,
          bottom: borderSide,
        ),
      ),
      child: child,
    );
  }
}
