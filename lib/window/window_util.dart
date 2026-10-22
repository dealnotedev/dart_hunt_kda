import 'dart:ffi' hide Size;

import 'package:ffi/ffi.dart';
import 'package:flutter/painting.dart';
import 'package:win32/win32.dart';

// Must match windows/runner/bitsdojo_window/window_util.h.
const wmBdwAction = 0x7FFE;
const bdwSetWindowPos = 1;
const bdwSetWindowText = 2;
const bdwForceChildRefresh = 3;

final class SWPParam extends Struct {
  @Int32()
  external int x;
  @Int32()
  external int y;
  @Int32()
  external int cx;
  @Int32()
  external int cy;
  @Uint32()
  external int uFlags;
}

void setWindowPos(
  HWND handle,
  int x,
  int y,
  int width,
  int height,
  SET_WINDOW_POS_FLAGS flags,
) {
  final param = calloc<SWPParam>();
  param.ref
    ..x = x
    ..y = y
    ..cx = width
    ..cy = height
    ..uFlags = flags;
  // On success the UI thread owns this allocation and uses CoTaskMemFree.
  if (!PostMessage(
    handle,
    wmBdwAction,
    const WPARAM(bdwSetWindowPos),
    LPARAM(param.address),
  ).value) {
    calloc.free(param);
  }
}

final class SWTParam extends Struct {
  external Pointer<Utf16> text;
}

void setWindowText(HWND handle, String text) {
  final param = calloc<SWTParam>();
  try {
    param.ref.text = text.toNativeUtf16();
  } catch (_) {
    calloc.free(param);
    rethrow;
  }
  if (!PostMessage(
    handle,
    wmBdwAction,
    const WPARAM(bdwSetWindowText),
    LPARAM(param.address),
  ).value) {
    calloc.free(param.ref.text);
    calloc.free(param);
  }
}

void forceChildRefresh(HWND handle) {
  PostMessage(
    handle,
    wmBdwAction,
    const WPARAM(bdwForceChildRefresh),
    const LPARAM(0),
  );
}

Rect getRectOnScreen(Size size, Alignment alignment, Rect screen) {
  return alignment.inscribe(size, screen);
}
