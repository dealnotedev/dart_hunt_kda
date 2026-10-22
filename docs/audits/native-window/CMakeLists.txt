cmake_minimum_required(VERSION 3.15)
project(native_window_audit LANGUAGES CXX)
add_executable(native_window_audit probe.cpp
  ../../../windows/runner/bitsdojo_window/bitsdojo_window.cpp
  ../../../windows/runner/bitsdojo_window/bitsdojo_window_api.cpp)
target_compile_features(native_window_audit PRIVATE cxx_std_17)
target_compile_definitions(native_window_audit PRIVATE UNICODE _UNICODE NOMINMAX)
target_link_libraries(native_window_audit PRIVATE user32 dwmapi comctl32 ole32)

