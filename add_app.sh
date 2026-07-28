#!/bin/bash
APP_NAME=$1

echo "Finding system files..."
CMAKE_FILE=$(find . -name "CMakeLists.txt" | grep -v "build" | head -n 1)
APPS_H_FILE=$(find . -name "Apps.h" | head -n 1)
DISPLAY_APP_FILE=$(find . -name "DisplayApp.cpp" | head -n 1)
APPS_CPP_FILE=$(find . -name "Apps.cpp" | head -n 1)

# --- 1. GENERATE THE APP SOURCE FILES ON THE FLY ---
echo "Generating src/displayapp/screens/${APP_NAME}.h..."
cat << 'EOF' > "src/displayapp/screens/${APP_NAME}.h"
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
        Bored(bool, Controllers::MotionController&, Controllers::MotorController&, Controllers::Settings&);
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
EOF

# Rename the class inside the generated header dynamically if app_name is not "Bored"
if [ "$APP_NAME" != "Bored" ]; then
    sed -i "s/Bored/${APP_NAME}/g" "src/displayapp/screens/${APP_NAME}.h"
fi

echo "Generating src/displayapp/screens/${APP_NAME}.cpp..."
cat << 'EOF' > "src/displayapp/screens/${APP_NAME}.cpp"
#include "displayapp/screens/Bored.h"
#include "displayapp/screens/Screen.h"
#include "displayapp/screens/Symbols.h"
#include "components/settings/Settings.h"
#include "components/motor/MotorController.h"
#include "components/motion/MotionController.h"

using namespace Pinetime::Applications::Screens;

namespace {
  lv_obj_t* MakeLabel(lv_font_t* font, lv_color_t color, lv_label_long_mode_t longMode,
                      uint8_t width, lv_label_align_t labelAlignment, const char* text,
                      lv_obj_t* reference, lv_align_t alignment, int8_t x, int8_t y) {
    lv_obj_t* label = lv_label_create(lv_scr_act(), nullptr);
    lv_obj_set_style_local_text_font(label, LV_LABEL_PART_MAIN, LV_STATE_DEFAULT, font);
    lv_obj_set_style_local_text_color(label, LV_LABEL_PART_MAIN, LV_STATE_DEFAULT, color);
    lv_label_set_long_mode(label, longMode);
    if (width != 0) lv_obj_set_width(label, width);
    lv_label_set_align(label, labelAlignment);
    lv_label_set_text(label, text);
    lv_obj_align(label, reference, alignment, x, y);
    return label;
  }

  void btnRollEventHandler(lv_obj_t* obj, lv_event_t event) {
    auto* screen = static_cast<Bored*>(obj->user_data);
    if (event == LV_EVENT_CLICKED) screen->Roll();
  }
}

// Support both constructor signatures across different InfiniTime API versions
Bored::Bored(bool, Controllers::MotionController& motion, Controllers::MotorController& motor, Controllers::Settings& settings)
  : Bored(motion, motor, settings) {}

Bored::Bored(Controllers::MotionController& motionController,
           Controllers::MotorController& motorController,
           Controllers::Settings& settingsController)
  : motorController {motorController}, motionController {motionController}, settingsController {settingsController} {
  
  std::seed_seq sseq {static_cast<uint32_t>(xTaskGetTickCount()),
                      static_cast<uint32_t>(motionController.X()),
                      static_cast<uint32_t>(motionController.Y()),
                      static_cast<uint32_t>(motionController.Z())};
  gen.seed(sseq);

  lv_obj_t* nCounterLabel = MakeLabel(&jetbrains_mono_bold_20, LV_COLOR_WHITE, LV_LABEL_LONG_EXPAND, 0, LV_LABEL_ALIGN_CENTER, "Items", lv_scr_act(), LV_ALIGN_IN_TOP_LEFT, 0, 0);
  resultTotalLabel = MakeLabel(&jetbrains_mono_42, LV_COLOR_WHITE, LV_LABEL_LONG_BREAK, 220, LV_LABEL_ALIGN_CENTER, "Tap Roll", lv_scr_act(), LV_ALIGN_CENTER, 0, 0);

  btnRoll = lv_btn_create(lv_scr_act(), nullptr);
  btnRoll->user_data = this;
  lv_obj_set_event_cb(btnRoll, btnRollEventHandler);
  lv_obj_set_size(btnRoll, 240, 50);
  lv_obj_align(btnRoll, lv_scr_act(), LV_ALIGN_IN_BOTTOM_MID, 0, 0);
  MakeLabel(&jetbrains_mono_bold_20, LV_COLOR_WHITE, LV_LABEL_LONG_EXPAND, 0, LV_LABEL_ALIGN_CENTER, "ROLL", btnRoll, LV_ALIGN_CENTER, 0, 0);

  enableShakeForDice = !settingsController.isWakeUpModeOn(Pinetime::Controllers::Settings::WakeUpMode::Shake);
  if (enableShakeForDice) settingsController.setWakeUpMode(Pinetime::Controllers::Settings::WakeUpMode::Shake, true);
  
  refreshTask = lv_task_create(RefreshTaskCallback, LV_DISP_DEF_REFR_PERIOD, LV_TASK_PRIO_MID, this);
}

Bored::~Bored() {
  if (enableShakeForDice) settingsController.setWakeUpMode(Pinetime::Controllers::Settings::WakeUpMode::Shake, false);
  lv_task_del(refreshTask);
  lv_obj_clean(lv_scr_act());
}

void Bored::Refresh() {
  if (motionController.CurrentShakeSpeed() >= settingsController.GetShakeThreshold()) {
    if (currentRollHysteresis <= 0) {
      lv_disp_get_next(NULL)->last_activity_time = lv_tick_get();
      Roll();
    }
  } else if (currentRollHysteresis > 0) --currentRollHysteresis;
}

void Bored::Roll() {
  const char* customItems[] = { "Pizza", "Burgers", "Tacos", "Salad", "Sushi", "Pasta" };
  std::uniform_int_distribution<> distrib(0, 5);
  lv_label_set_text(resultTotalLabel, customItems[distrib(gen)]);
  if (openingRoll == false) {
    motorController.RunForDuration(30);
    currentRollHysteresis = rollHysteresis;
  }
}
EOF

if [ "$APP_NAME" != "Bored" ]; then
    sed -i "s/Bored/${APP_NAME}/g" "src/displayapp/screens/${APP_NAME}.cpp"
fi


# --- 2. PYTHON INJECTION SYSTEM ---
echo "Injecting into CMakeLists.txt..."
python3 -c "
with open('$CMAKE_FILE', 'r') as f: content = f.read()
if 'screens/$APP_NAME.cpp' not in content:
    content = content.replace('displayapp/screens/Screen.cpp', 'displayapp/screens/Screen.cpp\n        displayapp/screens/$APP_NAME.cpp')
    with open('$CMAKE_FILE', 'w') as f: f.write(content)
"

echo "Injecting into Apps.h..."
python3 -c "
with open('$APPS_H_FILE', 'r') as f: content = f.read()
if '$APP_NAME' not in content:
    # Target the end of the enum definition list cleanly
    content = content.replace('};', '    $APP_NAME,\n      };')
    with open('$APPS_H_FILE', 'w') as f: f.write(content)
"

echo "Injecting into DisplayApp.cpp..."
python3 -c "
with open('$DISPLAY_APP_FILE', 'r') as f: content = f.read()
if 'displayapp/screens/$APP_NAME.h' not in content:
    content = '#include \"displayapp/screens/$APP_NAME.h\"\n' + content

if 'case Apps::$APP_NAME:' not in content:
    import re
    pattern = r'(case\s+Apps::FlashLight:.*?break;)'
    replacement = r'\1\n\n    case Apps::$APP_NAME:\n      currentScreen = std::make_unique<Screens::$APP_NAME>(controllers.motionController, controllers.motorController, controllers.settingsController);\n      break;'
    content = re.sub(pattern, replacement, content, flags=re.DOTALL)
    with open('$DISPLAY_APP_FILE', 'w') as f: f.write(content)
"

echo "Injecting into Apps.cpp..."
python3 -c "
with open('$APPS_CPP_FILE', 'r') as f: content = f.read()
if 'Apps::$APP_NAME' not in content:
    content = content.replace('};', '  {\"\u25A1\", Apps::$APP_NAME, true},\n};')
    with open('$APPS_CPP_FILE', 'w') as f: f.write(content)
"

echo "Successfully completed code generation and system injection for $APP_NAME!"
