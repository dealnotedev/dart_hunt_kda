import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

class RingtonePlayer {
  void playAudio() {}

  static void play(String asset) async {
    final directory = File(Platform.resolvedExecutable).parent.path;
    final file = File('$directory\\data\\flutter_assets\\$asset');

    if (await file.exists()) {
      using((arena) {
        PlaySound(
          PCWSTR(file.path.toNativeUtf16(allocator: arena)),
          null,
          SND_FILENAME | SND_ASYNC,
        );
      });
    }
  }

  static Future<bool> isAssetExists(String asset) async {
    final directory = File(Platform.resolvedExecutable).parent.path;
    final file = File('$directory\\data\\flutter_assets\\$asset');

    return file.exists();
  }
}
