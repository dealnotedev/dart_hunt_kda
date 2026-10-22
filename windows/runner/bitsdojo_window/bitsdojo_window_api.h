#ifndef BITSDOJO_WINDOW_API_H
#define BITSDOJO_WINDOW_API_H

#include "./bitsdojo_window.h"

namespace bitsdojo_window {

    typedef struct _BDWPublicAPI {
        TIsBitsdojoWindowLoaded isBitsdojoWindowLoaded;
        TGetAppWindow getAppWindow;
        TSetWindowCanBeShown setWindowCanBeShown;
        TSetMinSize setMinSize;
        TSetMaxSize setMaxSize;
        TSetWindowCutOnMaximize setWindowCutOnMaximize;
        TIsDPIAware isDPIAware;
    } BDWPublicAPI;

}

extern "C" __declspec(dllexport) bitsdojo_window::BDWPublicAPI* bitsdojo_window_api();
#endif
