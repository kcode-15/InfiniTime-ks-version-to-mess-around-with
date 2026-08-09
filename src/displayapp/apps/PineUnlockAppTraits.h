#pragma once
#include "displayapp/apps/Apps.h"
#include "displayapp/screens/PineUnlock.h"

namespace Pinetime::Applications {
  template <>
  struct AppTraits<Apps::PineUnlock> {
    static constexpr Apps app = Apps::PineUnlock;
    static constexpr const char* icon = "P";
    
    static Screens::Screen* Create(AppControllers& controllers) {
      return new Screens::PineUnlock(controllers.displayApp);
    }
    
    static bool IsAvailable(Controllers::FS& fs) {
      return true;
    }
  };
}
