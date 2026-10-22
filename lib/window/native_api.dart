import 'dart:ffi';

final DynamicLibrary _appExecutable = DynamicLibrary.executable();

// isBitsdojoWindowLoaded
typedef TIsBitsdojoWindowLoaded = Bool Function();
typedef DTIsBitsdojoWindowLoaded = bool Function();
final DTIsBitsdojoWindowLoaded _isBitsdojoWindowLoaded = _publicAPI
    .ref
    .isBitsdojoWindowLoaded
    .asFunction();

bool isBitsdojoWindowLoaded() {
  return _isBitsdojoWindowLoaded();
}

// getAppWindow
typedef TGetAppWindow = IntPtr Function();
typedef DGetAppWindow = int Function();
final DGetAppWindow getAppWindow = _publicAPI.ref.getAppWindow.asFunction();

// isDPIAware
typedef TIsDPIAware = Bool Function();
typedef DIsDPIAware = bool Function();
final DIsDPIAware _isDPIAware = _publicAPI.ref.isDPIAware.asFunction();
bool isDPIAware() => _isDPIAware();

// setWindowCanBeShown
typedef TSetWindowCanBeShown = Void Function(Bool value);
typedef DSetWindowCanBeShown = void Function(bool value);
final DSetWindowCanBeShown _setWindowCanBeShown = _publicAPI
    .ref
    .setWindowCanBeShown
    .asFunction();
void setWindowCanBeShown(bool value) => _setWindowCanBeShown(value);

// setMinSize
typedef TSetMinSize = Void Function(Int32 width, Int32 height);
typedef DSetMinSize = void Function(int width, int height);
final DSetMinSize setMinSize = _publicAPI.ref.setMinSize.asFunction();

// setMaxSize
typedef TSetMaxSize = Void Function(Int32 width, Int32 height);
typedef DSetMaxSize = void Function(int width, int height);
final DSetMaxSize setMaxSize = _publicAPI.ref.setMaxSize.asFunction();

// setWindowCutOnMaximize
typedef TSetWindowCutOnMaximize = Void Function(Int32 width);
typedef DSetWindowCutOnMaximize = void Function(int width);
final DSetWindowCutOnMaximize setWindowCutOnMaximize = _publicAPI
    .ref
    .setWindowCutOnMaximize
    .asFunction();

final class BDWPublicAPI extends Struct {
  external Pointer<NativeFunction<TIsBitsdojoWindowLoaded>>
  isBitsdojoWindowLoaded;
  external Pointer<NativeFunction<TGetAppWindow>> getAppWindow;
  external Pointer<NativeFunction<TSetWindowCanBeShown>> setWindowCanBeShown;
  external Pointer<NativeFunction<TSetMinSize>> setMinSize;
  external Pointer<NativeFunction<TSetMaxSize>> setMaxSize;
  external Pointer<NativeFunction<TSetWindowCutOnMaximize>>
  setWindowCutOnMaximize;
  external Pointer<NativeFunction<TIsDPIAware>> isDPIAware;
}

typedef TBitsdojoWindowAPI = Pointer<BDWPublicAPI> Function();

final TBitsdojoWindowAPI bitsdojoWindowAPI = _appExecutable
    .lookup<NativeFunction<TBitsdojoWindowAPI>>("bitsdojo_window_api")
    .asFunction();

final Pointer<BDWPublicAPI> _publicAPI = bitsdojoWindowAPI();
