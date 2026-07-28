#!/bin/bash
APP_NAME=$1

# 1. Update CMakeLists.txt (under Dice.cpp entry)
echo "Updating CMakeLists.txt..."
CMAKE_FILE=$(find . -name "CMakeLists.txt" | grep -v "build" | head -n 1)
sed -i "/Dice.cpp/a \    displayapp/screens/${APP_NAME}.cpp" "$CMAKE_FILE"

# 2. Update Apps.h (target explicit enum structure instead of matching general comments)
echo "Updating Apps.h..."
APPS_H_FILE=$(find . -name "Apps.h" | head -n 1)
sed -i "/Dice/a \        ${APP_NAME}," "$APPS_H_FILE"

# 3. Update DisplayApp.cpp Include Headers
echo "Updating DisplayApp.cpp headers..."
DISPLAY_APP_FILE=$(find . -name "DisplayApp.cpp" | head -n 1)
sed -i "/#include \"displayapp\/screens\/Dice.h\"/a #include \"displayapp\/screens/${APP_NAME}.h\"" "$DISPLAY_APP_FILE"

# 4. Safely insert into the actual LoadScreen switch statement in DisplayApp.cpp
# This targets the specific case Apps::FlashLight block near the end of the switch statement.
echo "Updating DisplayApp.cpp switch statement..."
sed -i '/case Apps::FlashLight:/,/break;/ {
  /break;/a \ \n    case Apps::'$APP_NAME':\n      currentScreen = std::make_unique<Screens::'$APP_NAME'>(controllers.motionController, controllers.motorController, controllers.settingsController);\n      break;
}' "$DISPLAY_APP_FILE"

# 5. Update Apps.cpp Menu Array (under Dice entry)
echo "Updating Apps.cpp..."
APPS_CPP_FILE=$(find . -name "Apps.cpp" | head -n 1)
sed -i "/Apps::Dice/a \  {\"\u25A1\", Apps::${APP_NAME}, true}," "$APPS_CPP_FILE"

echo "Successfully injected code for ${APP_NAME}!"
