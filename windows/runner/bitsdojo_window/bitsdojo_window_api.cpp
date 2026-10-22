#include "bitsdojo_window_api.h"
#include "bitsdojo_window.h"

namespace bitsdojo_window {
    BDWPublicAPI publicAPI = {
        isBitsdojoWindowLoaded,
        getAppWindow,
        setWindowCanBeShown,
        setMinSize,
        setMaxSize,
        setWindowCutOnMaximize,
        isDPIAware,
    };
}

bitsdojo_window::BDWPublicAPI* bitsdojo_window_api(){
    return &bitsdojo_window::publicAPI;
}
