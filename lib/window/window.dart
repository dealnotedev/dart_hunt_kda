import 'dart:ffi' hide Size;

import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:win32/win32.dart';

import 'native_api.dart' as native;
import 'win32_plus.dart';
import 'window_util.dart';

final appWindow = WinWindow();
const _windowChannel = MethodChannel('bitsdojo/window');
bool _isInsideWindowReady = false;

Future<void> doWhenWindowReady(VoidCallback callback) async {
  await WidgetsBinding.instance.waitUntilFirstFrameRasterized;
  _isInsideWindowReady = true;
  try {
    native.setWindowCanBeShown(true);
    callback();
  } finally {
    _isInsideWindowReady = false;
  }
}

Rect getScreenRectForWindow(HWND handle) {
  final monitor = MonitorFromWindow(handle, MONITOR_DEFAULTTONEAREST);
  final info = calloc<MONITORINFO>()..ref.cbSize = sizeOf<MONITORINFO>();
  try {
    if (!GetMonitorInfo(monitor, info)) return Rect.zero;
    return info.ref.rcWork.toRect;
  } finally {
    calloc.free(info);
  }
}

class WinWindow {
  WinWindow() : handle = HWND(Pointer.fromAddress(native.getAppWindow())) {
    if (!native.isBitsdojoWindowLoaded() || handle.isNull) {
      throw StateError('Windows window has not been initialized');
    }
  }

  final HWND handle;
  Size? _minSize;
  Size? _maxSize;
  Size? _sizeSetFromDart;
  Alignment? _alignment = Alignment.center;

  bool get _hasWindow => !handle.isNull && IsWindow(handle);

  void setWindowCutOnMaximize(int value) {
    native.setWindowCutOnMaximize(value);
  }

  Rect get rect {
    if (!_hasWindow) return Rect.zero;
    final value = calloc<RECT>();
    try {
      return GetWindowRect(handle, value).value ? value.ref.toRect : Rect.zero;
    } finally {
      calloc.free(value);
    }
  }

  set rect(Rect value) {
    if (!_hasWindow) return;
    setWindowPos(
      handle,
      value.left.toInt(),
      value.top.toInt(),
      value.width.toInt(),
      value.height.toInt(),
      SWP_NOZORDER | SWP_NOACTIVATE,
    );
  }

  Size get size => getLogicalSize(rect.size);

  Size get sizeOnScreen {
    if (_isInsideWindowReady && _sizeSetFromDart != null) {
      return getSizeOnScreen(_sizeSetFromDart!);
    }
    return rect.size;
  }

  double systemMetric(SYSTEM_METRICS_INDEX metric, {int dpiToUse = 0}) {
    return native.isDPIAware()
        ? GetSystemMetricsForDpi(
            metric,
            dpiToUse == 0 ? dpi : dpiToUse,
          ).value.toDouble()
        : GetSystemMetrics(metric).toDouble();
  }

  double get borderSize => systemMetric(SM_CXBORDER);

  int get dpi {
    if (!native.isDPIAware() || !_hasWindow) return 96;
    final value = GetDpiForWindow(handle);
    return value == 0 ? 96 : value;
  }

  double get scaleFactor => dpi / 96.0;

  double get titleBarHeight =>
      systemMetric(SM_CYSIZEFRAME) / scaleFactor +
      systemMetric(SM_CYCAPTION) / scaleFactor +
      (systemMetric(SM_CXPADDEDBORDER) / scaleFactor).ceilToDouble();

  Size get titleBarButtonSize => Size(
    systemMetric(SM_CYCAPTION) / scaleFactor * 2,
    titleBarHeight - borderSize,
  );

  Size getSizeOnScreen(Size value) => value * scaleFactor;
  Size getLogicalSize(Size value) => value / scaleFactor;

  Alignment? get alignment => _alignment;

  set alignment(Alignment? value) {
    _alignment = value;
    if (value != null && _hasWindow) {
      rect = getRectOnScreen(
        sizeOnScreen,
        value,
        getScreenRectForWindow(handle),
      );
    }
  }

  set minSize(Size? value) {
    _minSize = value;
    native.setMinSize(value?.width.toInt() ?? 0, value?.height.toInt() ?? 0);
  }

  set maxSize(Size? value) {
    _maxSize = value;
    native.setMaxSize(value?.width.toInt() ?? 0, value?.height.toInt() ?? 0);
  }

  set size(Size value) {
    if (!_hasWindow) return;
    final logicalSize = Size(
      value.width.clamp(
        _minSize?.width ?? 0,
        _maxSize?.width ?? double.infinity,
      ),
      value.height.clamp(
        _minSize?.height ?? 0,
        _maxSize?.height ?? double.infinity,
      ),
    );
    _sizeSetFromDart = logicalSize;
    final physicalSize = getSizeOnScreen(logicalSize);
    if (_alignment == null) {
      setWindowPos(
        handle,
        0,
        0,
        physicalSize.width.toInt(),
        physicalSize.height.toInt(),
        SWP_NOMOVE | SWP_NOZORDER | SWP_NOACTIVATE,
      );
    } else {
      rect = getRectOnScreen(
        physicalSize,
        _alignment!,
        getScreenRectForWindow(handle),
      );
    }
  }

  bool get isMaximized => _hasWindow && IsZoomed(handle);
  bool get isVisible => _hasWindow && IsWindowVisible(handle);

  @Deprecated('use isVisible instead')
  bool get visible => isVisible;

  @Deprecated('use show()/hide() instead')
  set visible(bool value) => value ? show() : hide();

  Offset get position => rect.topLeft;

  set position(Offset value) {
    if (!_hasWindow) return;
    setWindowPos(
      handle,
      value.dx.toInt(),
      value.dy.toInt(),
      0,
      0,
      SWP_NOSIZE | SWP_NOZORDER | SWP_NOACTIVATE,
    );
  }

  void show() {
    if (!_hasWindow) return;
    setWindowPos(handle, 0, 0, 0, 0, SWP_NOSIZE | SWP_NOMOVE | SWP_SHOWWINDOW);
    forceChildRefresh(handle);
  }

  void hide() {
    if (!_hasWindow) return;
    setWindowPos(
      handle,
      0,
      0,
      0,
      0,
      SWP_NOSIZE | SWP_NOMOVE | SWP_NOZORDER | SWP_NOACTIVATE | SWP_HIDEWINDOW,
    );
  }

  void close() => _sendCommand(SC_CLOSE);
  void minimize() => _sendCommand(SC_MINIMIZE);
  void maximize() => _sendCommand(SC_MAXIMIZE);
  void restore() => _sendCommand(SC_RESTORE);
  void maximizeOrRestore() => isMaximized ? restore() : maximize();

  void _sendCommand(int command) {
    if (_hasWindow) {
      PostMessage(handle, WM_SYSCOMMAND, WPARAM(command), const LPARAM(0));
    }
  }

  set title(String value) {
    if (_hasWindow) setWindowText(handle, value);
  }

  Future<void> startDragging() async {
    await _windowChannel.invokeMethod<void>('dragAppWindow');
  }
}
