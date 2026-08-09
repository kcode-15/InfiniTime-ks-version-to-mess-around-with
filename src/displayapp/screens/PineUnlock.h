#pragma once
#include <cstring>
#include "lvgl/lvgl.h"
#include "displayapp/screens/Screen.h"

namespace Pinetime {
  namespace Applications {
    namespace Screens {
      class PineUnlock : public Screen {
      private:
        bool isConfigured = false;
        bool isLocked = true;
        uint8_t targetPin[4] = {0};
        uint8_t enteredPin[4] = {0};
        uint8_t pinDigitCount = 0;
        
        lv_obj_t* numpadContainer = nullptr;
        lv_obj_t* statusLabel = nullptr;
        lv_obj_t* btnMatrix = nullptr;
        
        static const char* btnmapData[];
        
        void CreatePinSetupUI();
        void CreateLockScreenUI();
        void HandlePinInput(uint8_t number);
        void CheckUnlockSuccess();
        static void BtnMatrixEventHandler(lv_obj_t* obj, lv_event_t event);
        
      public:
        PineUnlock(DisplayApp* app);
        ~PineUnlock() override;
        bool OnTouchEvent(TouchEvents event) override;
      };
    }
  }
}
