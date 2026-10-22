#include <windows.h>
#include <objbase.h>

#include <cstdlib>
#include <iostream>
#include <string>

#include "../runner/bitsdojo_window/bitsdojo_window_api.h"
#include "../runner/bitsdojo_window/window_util.h"

namespace {
int observed_creations = 0;

void Check(bool condition, const char* message) {
  if (!condition) {
    std::cerr << "FAILED: " << message << " (Win32 " << GetLastError() << ")\n";
    std::exit(EXIT_FAILURE);
  }
}

LRESULT CALLBACK ObserveWindows(int code, WPARAM wparam, LPARAM lparam) {
  if (code == HCBT_CREATEWND) ++observed_creations;
  return CallNextHookEx(nullptr, code, wparam, lparam);
}

ATOM RegisterWindow(const wchar_t* name) {
  WNDCLASS klass{};
  klass.lpfnWndProc = DefWindowProc;
  klass.hInstance = GetModuleHandle(nullptr);
  klass.lpszClassName = name;
  const auto atom = RegisterClass(&klass);
  Check(atom != 0, "register test window class");
  return atom;
}

void PumpMessages() {
  MSG message;
  while (PeekMessage(&message, nullptr, 0, 0, PM_REMOVE)) {
    TranslateMessage(&message);
    DispatchMessage(&message);
  }
}

void PostTitle(HWND window, const wchar_t* title) {
  auto param = static_cast<SWTParam*>(CoTaskMemAlloc(sizeof(SWTParam)));
  Check(param != nullptr, "allocate title payload");
  const auto bytes = (wcslen(title) + 1) * sizeof(wchar_t);
  auto text = static_cast<wchar_t*>(CoTaskMemAlloc(bytes));
  Check(text != nullptr, "allocate Unicode title");
  memcpy(text, title, bytes);
  param->text = text;
  Check(PostMessage(window, WM_BDW_ACTION, BDW_SETWINDOWTEXT,
                    reinterpret_cast<LPARAM>(param)) != FALSE, "post title");
}

void PostRect(HWND window, int width, int height) {
  auto param = static_cast<SWPParam*>(CoTaskMemAlloc(sizeof(SWPParam)));
  Check(param != nullptr, "allocate rectangle payload");
  *param = {0, 0, width, height, SWP_NOMOVE | SWP_NOZORDER | SWP_NOACTIVATE};
  Check(PostMessage(window, WM_BDW_ACTION, BDW_SETWINDOWPOS,
                    reinterpret_cast<LPARAM>(param)) != FALSE, "post rectangle");
}
}  // namespace

int main() {
  static_assert(sizeof(SWPParam) == 20, "Dart rectangle payload ABI");
  static_assert(sizeof(SWTParam) == sizeof(void*), "Dart title payload ABI");
  static_assert(sizeof(bitsdojo_window::BDWPublicAPI) == 7 * sizeof(void*),
                "Dart public API ABI");
  Check(SUCCEEDED(CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED)), "COM init");
  const auto observer = SetWindowsHookEx(WH_CBT, ObserveWindows, nullptr, GetCurrentThreadId());
  Check(observer != nullptr, "install observer hook");
  Check(bitsdojo_window::configure(BDW_CUSTOM_FRAME | BDW_HIDE_ON_STARTUP) != 0,
        "configure native window handling");
  auto api = bitsdojo_window_api();
  Check(api->isBitsdojoWindowLoaded(), "public API initialized");
  Check(!bitsdojo_window::dragAppWindow(), "drag without a window fails safely");

  const auto atom = RegisterWindow(L"UNRELATED_TEST_WINDOW");
  const auto unrelated = CreateWindow(MAKEINTATOM(atom), L"", WS_OVERLAPPEDWINDOW,
                                     0, 0, 100, 100, nullptr, nullptr, nullptr, nullptr);
  Check(unrelated != nullptr, "create a window using an integer class atom");
  DestroyWindow(unrelated);
  RegisterWindow(L"FLUTTER_RUNNER_WIN32_WINDOW");
  RegisterWindow(L"FLUTTERVIEW");
  const auto window = CreateWindow(L"FLUTTER_RUNNER_WIN32_WINDOW", L"test",
      WS_OVERLAPPEDWINDOW | WS_VISIBLE, 0, 0, 368, 100,
      nullptr, nullptr, GetModuleHandle(nullptr), nullptr);
  Check(window != nullptr && api->getAppWindow() == window, "capture parent window");
  Check(!IsWindowVisible(window), "hide on startup blocks premature show");
  const auto child = CreateWindow(L"FLUTTERVIEW", L"", WS_CHILD, 0, 0, 368, 100,
      window, nullptr, GetModuleHandle(nullptr), nullptr);
  Check(child != nullptr, "capture child window without creation parameters");
  Check(observed_creations >= 3, "window hook forwards to the next hook");
  api->setWindowCanBeShown(true);
  SetWindowPos(window, nullptr, 0, 0, 0, 0,
               SWP_SHOWWINDOW | SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE);
  Check(IsWindowVisible(window) != FALSE, "allow explicit show after readiness");
  ShowWindow(window, SW_HIDE);

  api->setMinSize(200, 100);
  api->setMaxSize(800, 600);
  MINMAXINFO limits{};
  SendMessage(window, WM_GETMINMAXINFO, 0, reinterpret_cast<LPARAM>(&limits));
  const auto scale = api->isDPIAware() ? GetDpiForWindow(window) / 96.0 : 1.0;
  Check(limits.ptMinTrackSize.x == static_cast<int>(200 * scale) &&
        limits.ptMinTrackSize.y == static_cast<int>(100 * scale), "DPI-scaled minimum size");
  Check(limits.ptMaxTrackSize.x == static_cast<int>(800 * scale) &&
        limits.ptMaxTrackSize.y == static_cast<int>(600 * scale), "DPI-scaled maximum size");
  api->setMinSize(0, 0);
  api->setMaxSize(0, 0);
  limits.ptMinTrackSize = {123, 456};
  limits.ptMaxTrackSize = {789, 900};
  SendMessage(window, WM_GETMINMAXINFO, 0, reinterpret_cast<LPARAM>(&limits));
  Check(limits.ptMinTrackSize.x == 123 && limits.ptMaxTrackSize.y == 900,
        "clearing size limits restores default handling");

  for (int i = 0; i < 1000; ++i) {
    PostRect(window, 400, 180);
    PostTitle(window, L"Hunt \u2014 Statistics");
    PumpMessages();
  }
  wchar_t title[100]{};
  GetWindowText(window, title, 100);
  Check(std::wstring(title) == L"Hunt \u2014 Statistics",
        "Unicode title survives cross-thread payload handling");
  RECT rectangle;
  GetWindowRect(window, &rectangle);
  Check(rectangle.right - rectangle.left == 400 && rectangle.bottom - rectangle.top == 180,
        "posted size is applied");

  PostTitle(window, L"queued at shutdown");
  PostRect(window, 400, 180);
  DestroyWindow(window);
  MSG pending;
  Check(!PeekMessage(&pending, window, WM_BDW_ACTION, WM_BDW_ACTION, PM_REMOVE),
        "shutdown drains queued allocations");
  Check(api->getAppWindow() == nullptr && !bitsdojo_window::dragAppWindow(),
        "destroyed window handle is cleared");
  UnhookWindowsHookEx(observer);
  CoUninitialize();
  std::cout << "PASS: startup, hook chaining, DPI limits, Unicode, 2000 payloads, shutdown\n";
  return EXIT_SUCCESS;
}
