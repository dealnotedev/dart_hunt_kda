import 'package:win32_registry/win32_registry.dart';

class AppAutoLauncherImplWindows {
  final String appName;
  final String appPath;
  final List<String> args;

  AppAutoLauncherImplWindows({
    required this.appName,
    required this.appPath,
    required this.args,
  });

  RegistryKey get _regKey => Registry.openPath(
        RegistryHive.currentUser,
        path: r'Software\Microsoft\Windows\CurrentVersion\Run',
        desiredAccessRights: AccessRights.allAccess,
      );

  Future<bool> isEnabled() async {
    String? value = _regKey.getValueAsString(appName);
    return value == _fullPath;
  }

  String get _fullPath => '$appPath ${args.join(' ')}';

  Future<bool> enable() async {
    _regKey.createValue(RegistryValue(
      appName,
      RegistryValueType.string,
      _fullPath,
    ));
    return true;
  }

  Future<bool> disable() async {
    if (await isEnabled()) {
      _regKey.deleteValue(appName);
    }
    return true;
  }
}
