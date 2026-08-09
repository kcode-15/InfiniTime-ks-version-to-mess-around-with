#include "displayapp/screens/PineUnlock.h"
#include "displayapp/DisplayApp.h"

using namespace Pinetime::Applications::Screens;

const char* PineUnlock::btnmapData[] = {
    "1", "2", "3", "\n",
    "4", "5", "6", "\n",
    "7", "8", "9", "\n",
    "", "0", "", ""
};

PineUnlock::PineUnlock(DisplayApp* app) : Screen(app) {
  if (!isConfigured) {
    CreatePinSetupUI();
  } else {
    CreateLockScreenUI();
  }
}

PineUnlock::~PineUnlock() {
  lv_obj_clean(lv_scr_act());
}

bool PineUnlock::OnTouchEvent(TouchEvents event) {
  return false;
}

void PineUnlock::CreatePinSetupUI() {
  numpadContainer = lv_cont_create(lv_scr_act(), nullptr);
  lv_obj_set_size(numpadContainer, 240, 240);
  lv_cont_set_layout(numpadContainer, LV_LAYOUT_COL_MID);
  
  statusLabel = lv_label_create(numpadContainer, nullptr);
  lv_label_set_text(statusLabel, "Enter PIN");
  
  btnMatrix = lv_btnmatrix_create(numpadContainer, nullptr);
  lv_btnmatrix_set_map(btnMatrix, btnmapData);
  lv_obj_set_size(btnMatrix, 180, 150);
  lv_obj_set_event_cb(btnMatrix, BtnMatrixEventHandler);
  lv_obj_set_user_data(btnMatrix, this);
}

void PineUnlock::CreateLockScreenUI() {
  numpadContainer = lv_cont_create(lv_scr_act(), nullptr);
  lv_obj_set_size(numpadContainer, 240, 240);
  lv_cont_set_layout(numpadContainer, LV_LAYOUT_COL_MID);
  
  statusLabel = lv_label_create(numpadContainer, nullptr);
  lv_label_set_text(statusLabel, "Enter PIN to Unlock");
  
  btnMatrix = lv_btnmatrix_create(numpadContainer, nullptr);
  lv_btnmatrix_set_map(btnMatrix, btnmapData);
  lv_obj_set_size(btnMatrix, 180, 150);
  lv_obj_set_event_cb(btnMatrix, BtnMatrixEventHandler);
  lv_obj_set_user_data(btnMatrix, this);
}

void PineUnlock::BtnMatrixEventHandler(lv_obj_t* obj, lv_event_t event) {
  if (event == LV_EVENT_VALUE_CHANGED) {
    uint16_t btnId = lv_btnmatrix_get_active_btn(obj);
    if (btnId != LV_BTNMATRIX_BTN_NONE) {
      const char* btnText = lv_btnmatrix_get_active_btn_text(obj);
      if (btnText && btnText[0] != '\0') {
        uint8_t digit = btnText[0] - '0';
        PineUnlock* pThis = (PineUnlock*)lv_obj_get_user_data(obj);
        if (pThis) {
          pThis->HandlePinInput(digit);
        }
      }
    }
  }
}

void PineUnlock::HandlePinInput(uint8_t number) {
  if (pinDigitCount >= 4) return;
  
  if (!isConfigured) {
    targetPin[pinDigitCount] = number;
  } else {
    enteredPin[pinDigitCount] = number;
  }
  pinDigitCount++;
  
  if (pinDigitCount == 4) {
    if (!isConfigured) {
      isConfigured = true;
      isLocked = false;
      pinDigitCount = 0;
      lv_label_set_text(statusLabel, "PIN Set");
    } else {
      CheckUnlockSuccess();
    }
  }
}

void PineUnlock::CheckUnlockSuccess() {
  if (std::memcmp(targetPin, enteredPin, 4) == 0) {
    isLocked = false;
    lv_label_set_text(statusLabel, "Unlocked");
    lv_obj_set_hidden(numpadContainer, true);
  } else {
    std::memset(enteredPin, 0, 4);
    pinDigitCount = 0;
    lv_label_set_text(statusLabel, "Wrong PIN");
  }
}
