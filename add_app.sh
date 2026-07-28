#!/bin/bash
APP_NAME=$1

echo "Finding files..."
CMAKE_FILE=$(find . -name "CMakeLists.txt" | grep -v "build" | head -n 1)
APPS_H_FILE=$(find . -name "Apps.h" | head -n 1)
DISPLAY_APP_FILE=$(find . -name "DisplayApp.cpp" | head -n 1)
APPS_CPP_FILE=$(find . -name "Apps.cpp" | head -n 1)

echo "Injecting into CMakeLists.txt..."
python3 -c "
with open('$CMAKE_FILE', 'r') as f: content = f.read()
if 'screens/$APP_NAME.cpp' not in content:
    content = content.replace('screens/Dice.cpp', 'screens/Dice.cpp\n    screens/$APP_NAME.cpp')
    with open('$CMAKE_FILE', 'w') as f: f.write(content)
"

echo "Injecting into Apps.h..."
python3 -c "
with open('$APPS_H_FILE', 'r') as f: content = f.read()
if '$APP_NAME,' not in content:
    content = content.replace('    Dice,', '    Dice,\n        $APP_NAME,')
    with open('$APPS_H_FILE', 'w') as f: f.write(content)
"

echo "Injecting into DisplayApp.cpp..."
python3 -c "
with open('$DISPLAY_APP_FILE', 'r') as f: content = f.read()
if 'displayapp/screens/$APP_NAME.h' not in content:
    content = content.replace('#include \"displayapp/screens/Dice.h\"', '#include \"displayapp/screens/Dice.h\"\n#include \"displayapp/screens/$APP_NAME.h\"')
if 'case Apps::$APP_NAME:' not in content:
    old_block = '    case Apps::FlashLight:\n      currentScreen = std::make_unique<Screens::FlashLight>(*systemTask, brightnessController);\n      break;'
    new_block = old_block + '\n\n    case Apps::$APP_NAME:\n      currentScreen = std::make_unique<Screens::$APP_NAME>(controllers.motionController, controllers.motorController, controllers.settingsController);\n      break;'
    content = content.replace(old_block, new_block)
    with open('$DISPLAY_APP_FILE', 'w') as f: f.write(content)
"

echo "Injecting into Apps.cpp..."
python3 -c "
with open('$APPS_CPP_FILE', 'r') as f: content = f.read()
if 'Apps::$APP_NAME' not in content:
    content = content.replace('{Symbols::dice, Apps::Dice, true},', '{Symbols::dice, Apps::Dice, true},\n  {\"\u25A1\", Apps::$APP_NAME, true},')
    with open('$APPS_CPP_FILE', 'w') as f: f.write(content)
"

echo "Successfully injected code for $APP_NAME!"
