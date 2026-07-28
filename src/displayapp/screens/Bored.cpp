#include "displayapp/screens/Bored.h"
#include "displayapp/screens/Screen.h"
#include "displayapp/screens/Symbols.h"
#include "components/settings/Settings.h"
#include "components/motor/MotorController.h"
#include "components/motion/MotionController.h"

using namespace Pinetime::Applications::Screens;

namespace {
  // Helper to create labels with specific styling
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
    auto* screen = static_cast<Dice*>(obj->user_data);
    if (event == LV_EVENT_CLICKED) screen->Roll();
  }
}

Dice::Dice(Controllers::MotionController& motionController,
           Controllers::MotorController& motorController,
           Controllers::Settings& settingsController)
  : motorController {motorController}, motionController {motionController}, settingsController {settingsController} {
  
  // Seed RNG
  std::seed_seq sseq {static_cast<uint32_t>(xTaskGetTickCount()),
                      static_cast<uint32_t>(motionController.X()),
                      static_cast<uint32_t>(motionController.Y()),
                      static_cast<uint32_t>(motionController.Z())};
  gen.seed(sseq);

  // Setup UI Labels
  lv_obj_t* nCounterLabel = MakeLabel(&jetbrains_mono_bold_20, LV_COLOR_WHITE, LV_LABEL_LONG_EXPAND, 0, LV_LABEL_ALIGN_CENTER, "Items", lv_scr_act(), LV_ALIGN_IN_TOP_LEFT, 0, 0);
  
  // Display result
  resultTotalLabel = MakeLabel(&jetbrains_mono_42, LV_COLOR_WHITE, LV_LABEL_LONG_BREAK, 220, LV_LABEL_ALIGN_CENTER, "Tap Roll", lv_scr_act(), LV_ALIGN_CENTER, 0, 0);

  // Roll Button
  btnRoll = lv_btn_create(lv_scr_act(), nullptr);
  btnRoll->user_data = this;
  lv_obj_set_event_cb(btnRoll, btnRollEventHandler);
  lv_obj_set_size(btnRoll, 240, 50);
  lv_obj_align(btnRoll, lv_scr_act(), LV_ALIGN_IN_BOTTOM_MID, 0, 0);
  MakeLabel(&jetbrains_mono_bold_20, LV_COLOR_WHITE, LV_LABEL_LONG_EXPAND, 0, LV_LABEL_ALIGN_CENTER, "ROLL", btnRoll, LV_ALIGN_CENTER, 0, 0);

  // Enable Shake
  enableShakeForDice = !settingsController.isWakeUpModeOn(Pinetime::Controllers::Settings::WakeUpMode::Shake);
  if (enableShakeForDice) settingsController.setWakeUpMode(Pinetime::Controllers::Settings::WakeUpMode::Shake, true);
  
  refreshTask = lv_task_create(RefreshTaskCallback, LV_DISP_DEF_REFR_PERIOD, LV_TASK_PRIO_MID, this);
}

Dice::~Dice() {
  if (enableShakeForDice) settingsController.setWakeUpMode(Pinetime::Controllers::Settings::WakeUpMode::Shake, false);
  lv_task_del(refreshTask);
  lv_obj_clean(lv_scr_act());
}

void Dice::Refresh() {
  if (motionController.CurrentShakeSpeed() >= settingsController.GetShakeThreshold()) {
    if (currentRollHysteresis <= 0) {
      lv_disp_get_next(NULL)->last_activity_time = lv_tick_get();
      Roll();
    }
  } else if (currentRollHysteresis > 0) --currentRollHysteresis;
}

// --- CORE MODIFICATION: 6 Custom Items ---
void Dice::Roll() {
  const char* customItems[] = {
    "Read a book (one piece,james herriot, etc)", "Do some coding", "Hang with your fish",
    "Play a board game with finn", "Chill on the sofa", "Listen to some music and do some painting"
  };

  std::uniform_int_distribution<> distrib(0, 5); // 0 to 5 (6 items)
  lv_label_set_text(resultTotalLabel, customItems[distrib(gen)]);

  if (openingRoll == false) {
    motorController.RunForDuration(30);
    currentRollHysteresis = rollHysteresis;
  }
}
