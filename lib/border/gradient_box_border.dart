import 'package:flutter/widgets.dart';
import 'package:hunt_stats/border/corners.dart';

class GradientBoxBorder extends BoxBorder {
  final Corners corners;

  GradientBoxBorder(
      {required this.corners, required this.gradient, this.width = 1.0});

  final Gradient gradient;

  final double width;

  @override
  BorderSide get bottom => BorderSide.none;

  @override
  BorderSide get top => BorderSide.none;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  bool get isUniform => true;

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    TextDirection? textDirection,
    BoxShape shape = BoxShape.rectangle,
    BorderRadius? borderRadius,
  }) {
    switch (shape) {
      case BoxShape.circle:
        assert(
          borderRadius == null,
          'A borderRadius can only be given for rectangular boxes.',
        );
        _paintCircle(canvas, rect);
        break;
      case BoxShape.rectangle:
        if (borderRadius != null) {
          _paintRRect(canvas, rect, borderRadius);
          return;
        }
        _paintRect(canvas, rect);
        break;
    }
  }

  final _imgPaint = Paint()
    ..colorFilter = const ColorFilter.mode(Color(0xFF595A5C), BlendMode.srcIn);

  void _paintRect(Canvas canvas, Rect rect) {
    canvas.drawRect(rect.deflate(width / 2), _getPaint(rect));

    canvas.drawImageRect(
        corners.topRight,
        Rect.fromLTWH(0, 0, corners.topRight.width.toDouble(),
            corners.topRight.height.toDouble()),
        Rect.fromLTWH(rect.right - 16, rect.top, 16, 16),
        _imgPaint);

    canvas.drawImageRect(
        corners.bottomRight,
        Rect.fromLTWH(0, 0, corners.bottomRight.width.toDouble(),
            corners.bottomRight.height.toDouble()),
        Rect.fromLTWH(rect.right - 16, rect.bottom - 16, 16, 16),
        _imgPaint);
  }

  void _paintRRect(Canvas canvas, Rect rect, BorderRadius borderRadius) {
    final rrect = borderRadius.toRRect(rect).deflate(width / 2);
    canvas.drawRRect(rrect, _getPaint(rect));
  }

  void _paintCircle(Canvas canvas, Rect rect) {
    final paint = _getPaint(rect);
    final radius = (rect.shortestSide - width) / 2.0;
    canvas.drawCircle(rect.center, radius, paint);
  }

  @override
  ShapeBorder scale(double t) {
    return this;
  }

  Paint _getPaint(Rect rect) {
    return Paint()
      ..strokeWidth = width
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke;
  }
}
