#include <windows.h>
#include <iostream>
#include <string>
#include "../../../windows/runner/bitsdojo_window/bitsdojo_window_api.h"
#include "../../../windows/runner/bitsdojo_window/window_util.h"

namespace bitsdojo_window { extern BOOL during_minimize; }
namespace {
int child_sizes = 0;
int synthetic_dpi_notifications = 0;
int child_sizes_before_parent_dpi = -1;
bool minimize_flag_seen = false;

LRESULT CALLBACK HostProc(HWND hwnd, UINT message, WPARAM wp, LPARAM lp) {
  if (message == WM_SYSCOMMAND && (wp & 0xFFF0) == SC_MINIMIZE) {
    minimize_flag_seen = bitsdojo_window::during_minimize != FALSE;
    return 0;  // Observe the real subclass without minimizing a desktop window.
  }
  if (message == WM_DPICHANGED) {
    child_sizes_before_parent_dpi = child_sizes;
    const auto r = reinterpret_cast<RECT*>(lp);
    SetWindowPos(hwnd, nullptr, r->left, r->top, r->right-r->left,
                 r->bottom-r->top, SWP_NOZORDER | SWP_NOACTIVATE);
    return 0;
  }
  return DefWindowProc(hwnd, message, wp, lp);
}

LRESULT CALLBACK ChildProc(HWND hwnd, UINT message, WPARAM wp, LPARAM lp) {
  if (message == WM_SIZE) ++child_sizes;
  if (message == 0x02E2) ++synthetic_dpi_notifications;
  return DefWindowProc(hwnd, message, wp, lp);
}

void Register(const wchar_t* name, WNDPROC proc) {
  WNDCLASSW c{};
  c.lpfnWndProc = proc;
  c.hInstance = GetModuleHandleW(nullptr);
  c.lpszClassName = name;
  if (!RegisterClassW(&c)) std::exit(10);
}

void Pump() {
  MSG m;
  while (PeekMessageW(&m, nullptr, 0, 0, PM_REMOVE)) {
    TranslateMessage(&m);
    DispatchMessageW(&m);
  }
}
}

int main(int argc, char** argv) {
  SetProcessDpiAwarenessContext(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2);
  CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);
  if (!bitsdojo_window::configure(BDW_CUSTOM_FRAME | BDW_HIDE_ON_STARTUP)) return 11;
  Register(L"FLUTTER_RUNNER_WIN32_WINDOW", HostProc);
  Register(L"FLUTTERVIEW", ChildProc);
  const auto host = CreateWindowW(L"FLUTTER_RUNNER_WIN32_WINDOW", L"native audit probe",
      WS_OVERLAPPEDWINDOW, 20, 20, 400, 180, nullptr, nullptr,
      GetModuleHandleW(nullptr), nullptr);
  const auto child = CreateWindowW(L"FLUTTERVIEW", L"", WS_CHILD,
      0, 0, 400, 180, host, nullptr, GetModuleHandleW(nullptr), nullptr);
  if (!host || !child) return 12;
  const auto api = bitsdojo_window_api();
  std::cout << "awareness=" << GetAwarenessFromDpiAwarenessContext(
      GetWindowDpiAwarenessContext(host)) << " dpi=" << GetDpiForWindow(host) << '\n';
  const std::string mode = argc > 1 ? argv[1] : "commands";
  bool defective = false;
  if (mode == "commands") {
    SendMessageW(host, WM_SYSCOMMAND, SC_MINIMIZE, 0);
    const auto plain = minimize_flag_seen;
    SendMessageW(host, WM_SYSCOMMAND, SC_MINIMIZE | 2, 0);
    std::cout << "plain_minimize_flag=" << plain
              << " low_bits_minimize_flag=" << minimize_flag_seen << '\n';
    defective = plain && !minimize_flag_seen;
  } else if (mode == "dpi_order") {
    std::cout << "synthetic_beforeparent_at_child_create=" << synthetic_dpi_notifications << '\n';
    child_sizes = 0;
    RECT suggested{20, 20, 620, 290};
    SendMessageW(host, WM_DPICHANGED, MAKELONG(144, 144),
                 reinterpret_cast<LPARAM>(&suggested));
    std::cout << "child_resizes_before_parent_applies_suggested_rect="
              << child_sizes_before_parent_dpi << '\n';
    defective = child_sizes_before_parent_dpi >= 2;
  } else if (mode == "offscreen_show") {
    api->setWindowCanBeShown(true);
    const int x = GetSystemMetrics(SM_XVIRTUALSCREEN) + GetSystemMetrics(SM_CXVIRTUALSCREEN) + 4000;
    SetWindowPos(host, nullptr, x, 20, 400, 180, SWP_NOZORDER | SWP_NOACTIVATE);
    auto p = static_cast<SWPParam*>(CoTaskMemAlloc(sizeof(SWPParam)));
    *p = {0, 0, 0, 0, SWP_NOSIZE | SWP_NOMOVE | SWP_SHOWWINDOW | SWP_NOACTIVATE};
    PostMessageW(host, WM_BDW_ACTION, BDW_SETWINDOWPOS, reinterpret_cast<LPARAM>(p));
    Pump();
    const auto intersects_monitor = MonitorFromWindow(host, MONITOR_DEFAULTTONULL) != nullptr;
    std::cout << "visible=" << IsWindowVisible(host)
              << " intersects_monitor=" << intersects_monitor << '\n';
    defective = IsWindowVisible(host) && !intersects_monitor;
  } else if (mode == "max_limit") {
    api->setMaxSize(800, 600);
    MINMAXINFO limits{};
    limits.ptMaxSize = {3000, 1800};
    SendMessageW(host, WM_GETMINMAXINFO, 0, reinterpret_cast<LPARAM>(&limits));
    std::cout << "max_tracking=" << limits.ptMaxTrackSize.x << 'x' << limits.ptMaxTrackSize.y
              << " maximize_size=" << limits.ptMaxSize.x << 'x' << limits.ptMaxSize.y << '\n';
    defective = limits.ptMaxTrackSize.x < limits.ptMaxSize.x;
  } else if (mode == "hidden_start") {
    ShowWindow(host, SW_SHOWNOACTIVATE);
    std::cout << "visible_before_readiness=" << IsWindowVisible(host) << '\n';
    defective = !IsWindowVisible(host);
  }
  DestroyWindow(host);
  CoUninitialize();
  std::cout << (defective ? "OBSERVED\n" : "NOT_OBSERVED\n");
  return defective ? 3 : 0;
}

