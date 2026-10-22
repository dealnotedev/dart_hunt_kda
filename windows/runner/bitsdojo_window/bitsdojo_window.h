#ifndef BITSDOJO_WINDOW_H_
#define BITSDOJO_WINDOW_H_
#include <windows.h>
#include <commctrl.h>

#define BDW_CUSTOM_FRAME 0x1
#define BDW_HIDE_ON_STARTUP 0x2

namespace bitsdojo_window {
    int configure(unsigned int flags);
    typedef bool (*TIsBitsdojoWindowLoaded)();
    bool isBitsdojoWindowLoaded();
    
    typedef void (*TSetWindowCanBeShown)(bool);
    void setWindowCanBeShown(bool value);

    bool dragAppWindow();

    typedef HWND (*TGetAppWindow)();
    HWND getAppWindow();

    typedef void (*TSetMinSize)(int, int);
    void setMinSize(int width, int height);

    typedef void (*TSetMaxSize)(int, int);
    void setMaxSize(int width, int height);

    typedef void (*TSetWindowCutOnMaximize)(int);
    void setWindowCutOnMaximize(int value);
    
    typedef bool (*TIsDPIAware)();
    bool isDPIAware();
}
#endif
