#pragma once

#include <cstdint>
#include <memory>
#include <random>
#include "displayapp/screens/Screen.h"
#include "components/settings/Settings.h"
#include "components/motor/MotorController.h"
#include "components/motion/MotionController.h"
#include "lvgl/lvgl.h"

namespace Pinetime {
  namespace Applications {
    namespace Screens {

      class Bored : public Screen {
      public:
        Bored(Controllers::MotionController& motionController,
              Controllers::MotorController& motorController,
              Controllers::Settings& settingsController);
        ~Bored() override;

        void Roll();

      private:
        Controllers::MotorController& motorController;
        Controllers::MotionController& motionController;
        Controllers::Settings& settingsController;

        bool openingRoll = true;
        bool enableShakeForDice = false;

        static constexpr uint8_t rollHysteresis = 10;
        uint8_t currentRollHysteresis = 0;

        std::size_t currentColorIndex = 0;

        std::mt19937 gen;

        lv_obj_t* resultTotalLabel;
        lv_obj_t* btnRoll;
        lv_obj_t* btnRollLabel;

        lv_task_t* refreshTask;

        void Refresh();
        void NextColor();

        static void RefreshTaskCallback(lv_task_t* task) {
          auto* screen = static_cast<Bored*>(task->user_data);
          screen->Refresh();
        }
      };
    }
  }
}
