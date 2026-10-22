cmake_minimum_required(VERSION 3.15)
project(window_tests LANGUAGES CXX)

add_executable(window_tests
  window_test.cpp
  ../runner/bitsdojo_window/bitsdojo_window.cpp
  ../runner/bitsdojo_window/bitsdojo_window_api.cpp
)
target_compile_features(window_tests PRIVATE cxx_std_17)
target_compile_definitions(window_tests PRIVATE UNICODE _UNICODE NOMINMAX)
target_compile_options(window_tests PRIVATE /W4 /WX /wd4100 /EHsc)
target_link_libraries(window_tests PRIVATE user32 dwmapi comctl32 ole32)

enable_testing()
add_test(NAME window_tests COMMAND window_tests)
