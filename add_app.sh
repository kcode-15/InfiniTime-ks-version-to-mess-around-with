#!/bin/bash
APP_NAME=$1

# 1. Add to CMakeLists.txt (under Dice.cpp)
sed -i "/displayapp\/screens\/Dice.cpp/a \        displayapp/screens/${APP_NAME}.cpp" CMakeLists.txt

# 2. Add to Apps.h (under Dice,)
sed -i "/Dice,/a \        ${APP_NAME}," src/displayapp/apps/Apps.h

# 3. Add to DisplayApp.cpp Header Include (under Dice.h)
sed -i "/#include \"displayapp\/screens\/Dice.h\"/a #include \"displayapp\/screens/${APP_NAME}.h\"" src/displayapp/DisplayApp.cpp

# 4. Add to DisplayApp.cpp Switch Case (under FlashLight)
sed -i "/case Apps::FlashLight:/,/break;/ {
  /break;/a \ \n    case Apps::${APP_NAME}:\n      currentScreen = std::make_unique<Screens::${APP_NAME}>(controllers.motionController, controllers.motorController, controllers.settingsController);\n      break;
}" src/displayapp/DisplayApp.cpp

# 5. Add to Apps.cpp Menu Array (under Dice entry)
sed -i "/{Symbols::dice, Apps::Dice/,/},/ {
  /},/a \  {\"\u25A1\", Apps::${APP_NAME}, true}," src/displayapp/apps/Apps.cpp
