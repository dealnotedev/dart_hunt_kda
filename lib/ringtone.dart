import 'dart:io';

import 'package:win32/win32.dart';

class RingtonePlayer {
  void playAudio() {}

  static void play(String asset) async {
    final directory = File(Platform.resolvedExecutable).parent.path;
    final file = File('$directory\\data\\flutter_assets\\$asset');

    if (await file.exists()) {
      PlaySound(TEXT(file.path), NULL, SND_FILENAME | SND_ASYNC);
    }
  }

  static Future<bool> isAssetExists(String asset) async {
    final directory = File(Platform.resolvedExecutable).parent.path;
    final file = File('$directory\\data\\flutter_assets\\$asset');

    return file.exists();
  }
}
