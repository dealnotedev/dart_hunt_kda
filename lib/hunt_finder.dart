import 'dart:convert';
import 'dart:io';

import 'package:hunt_stats/vdf.dart';
import 'package:win32_registry/win32_registry.dart';

class HuntFinder {
  static const _vdfCodec = VdfCodec();

  static final _regKey = Registry.openPath(
    RegistryHive.localMachine,
    path: r'SOFTWARE\Wow6432Node\Valve\Steam',
    desiredAccessRights: AccessRights.readOnly,
  );

  Future<File> findHuntAttributes() async {
    final steamDirectory = await _findSteamPath();
    final found = <File>[];

    if (steamDirectory != null) {
      final libraryFoldersFile =
          File('${steamDirectory.path}\\config\\libraryfolders.vdf');

      if (await libraryFoldersFile.exists()) {
        final vdf = await libraryFoldersFile.readAsString();
        final json = _vdfCodec.decode(vdf);

        for (int i = 0;; i++) {
          final lib = json['libraryfolders'][i.toString()];
          if (lib != null) {
            final libPath = lib['path'] as String;
            final file = File(
                '$libPath\\steamapps\\common\\Hunt Showdown\\user\\profiles\\default\\attributes.xml');

            if (await file.exists()) {
              found.add(file);
            }
          } else {
            break;
          }
        }
      }
    }

    final newwest = _getNewest(found);
    if (newwest != null) {
      return newwest;
    }

    return _awaitManualHuntDirectory();
  }

  static File? _getNewest(Iterable<File> files) {
    switch (files.length) {
      case 0:
        return null;
      case 1:
        return files.first;
      default:
        final sorted = List<File>.from(files, growable: true)
          ..sort(
              (l, r) => r.statSync().modified.compareTo(l.statSync().modified));
        return sorted.first;
    }
  }

  Future<File> _awaitManualHuntDirectory() async {
    while (true) {
      final settings = File('settings.json');

      try {
        final data = json.decode(await settings.readAsString());
        final directory = Directory(data['hunt_path']);

        final file =
            File('$directory\\user\\profiles\\default\\attributes.xml');

        if (await file.exists()) {
          return file;
        } else {
          await Future.delayed(const Duration(seconds: 5));
        }
      } catch (_) {}
    }
  }

  Future<Directory?> _findSteamPath() async {
    final registryInstallPath = _regKey.getValueAsString('InstallPath');

    if (registryInstallPath != null && registryInstallPath.isNotEmpty) {
      final directory = Directory(registryInstallPath);
      if (await directory.exists()) {
        return directory;
      }
    }

    return null;
  }
}
