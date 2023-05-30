import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:hunt_stats/generated/assets.dart';

class HuntImages {
  static late final ui.Image cornerTopRight;
  static late final ui.Image cornerBottomRight;

  static Future<void> init() async {
    cornerTopRight = await _imageFromAssets(Assets.assetsIcFrameCorner);
    cornerBottomRight =
        await _imageFromAssets(Assets.assetsIcFrameCornerBottom);
  }

  static Future<ui.Image> _imageFromAssets(String asset) async {
    final data = (await rootBundle.load(asset)).buffer;
    return decodeImageFromList(Uint8List.view(data));
  }
}
