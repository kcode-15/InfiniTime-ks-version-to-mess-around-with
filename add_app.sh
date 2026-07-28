#!/bin/bash
APP_NAME=$1

# 1. Find and update CMakeLists.txt (under Dice.cpp entry)
CMAKE_FILE=$(find . -name "CMakeLists.txt" | grep -v "build" | head -n 1)
sed -i "/Dice.cpp/a \    displayapp/screens/${APP_NAME}.cpp" "$CMAKE_FILE"

# 2. Find and update Apps.h (under Dice, enumeration)
APPS_H_FILE=$(find . -name "Apps.h" | head -n 1)
sed -i "/Dice,/a \        ${APP_NAME}," "$APPS_H_FILE"

# 3. Find and update DisplayApp.cpp Include Headers
DISPLAY_APP_FILE=$(find . -name "DisplayApp.cpp" | head -n 1)
sed -i "/#include \"displayapp\/screens\/Dice.h\"/a #include \"displayapp\/screens/${APP_NAME}.h\"" "$DISPLAY_APP_FILE"

# 4. Safely insert the Switch Case block into DisplayApp.cpp right above the default: case
sed -i "/default:/i \    case Apps::${APP_NAME}:\n      currentScreen = std::make_unique<Screens::${APP_NAME}>(controllers.motionController, controllers.motorController, controllers.settingsController);\n      break;" "$DISPLAY_APP_FILE"

# 5. Find and update Apps.cpp Menu Array (under Dice entry)
APPS_CPP_FILE=$(find . -name "Apps.cpp" | head -n 1)
sed -i "/Apps::Dice/a \  {\"\u25A1\", Apps::${APP_NAME}, true}," "$APPS_CPP_FILE"

echo "Successfully injected code for ${APP_NAME}!"
