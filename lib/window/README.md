# Windows window code

The window implementation is part of this application. It is adapted from
[bitsdojo/bitsdojo_window](https://github.com/bitsdojo/bitsdojo_window):
`bitsdojo_window` 0.1.6, its Windows implementation 0.1.6, and the shared
window geometry from platform interface 0.1.2. The MIT license is retained
beside both the Dart and C++ sources.

All shared caption widgets and Windows functionality are included. There are
no local packages, platform interfaces, plugin registrars, or macOS/Linux
implementations. `WinWindow` calls the native API directly; dragging uses a
method channel registered in `FlutterWindow::OnCreate` to run on the UI thread.
The C++ files are compiled into the runner by `windows/runner/CMakeLists.txt`.
The runner explicitly disables Impeller through `DartProject` so Windows builds
use Skia, including when the release executable is launched directly.

Changes made during validation:

- Updated Dart FFI types and Win32 calls for Dart 3.13 and win32 6.4.
- Paired Dart allocations with `CoTaskMemFree` in C++; freed monitor info,
  failed message payloads, and queued payloads on window destruction.
- Forwarded the CBT hook chain and handled integer window class atoms.
- Initialized native code explicitly on the runner thread and cleared destroyed
  window handles. Synchronized settings accessed from Dart and the UI thread.
- Fixed DPI scaling when no alignment is set, bottom-left alignment and custom
  alignment values, and resetting size limits to null.
- Restored readiness state after callback failures; prevented deferred button
  actions after disposal and repainted caption icons when their color changes.

Validation commands (CMake must be available, e.g. from a Visual Studio shell):

```powershell
flutter analyze
flutter test
cmake -S windows/tests -B build/window_tests
cmake --build build/window_tests --config Release
ctest --test-dir build/window_tests -C Release --output-on-failure
flutter run -d windows --release --no-resident -t tool/window_smoke.dart
flutter build windows --release
```

The smoke app exits automatically and writes `.dart_tool/window_smoke_result.json`.
It exercises the actual Flutter runner and FFI exports, window sizes, visibility,
and minimize/maximize/restore/close operations. It also checks tray icon loading,
the tooltip and menu, the right-click trigger, visibility after closing the
window, and disposal. Windows CMake bundles the DLLs produced by Dart build hooks.

All direct hosted dependencies were updated to the latest stable versions on
2026-10-22. `material_color_utilities` and `test_api` are pinned by Flutter 3.47.7.
Their newer releases cannot be selected without changing those SDK constraints.
The tray uses `tray_manager` 0.8.0's native API, retaining the icon for the app's
lifetime and disposing it on exit. The old `system_tray` and `uuid` dependencies
have been removed.
