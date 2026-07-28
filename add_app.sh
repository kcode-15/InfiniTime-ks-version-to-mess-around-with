#!/bin/bash
APP_NAME=$1

echo "Finding files..."
CMAKE_FILE=$(find . -name "CMakeLists.txt" | grep -v "build" | head -n 1)
APPS_H_FILE=$(find . -name "Apps.h" | head -n 1)
DISPLAY_APP_FILE=$(find . -name "DisplayApp.cpp" | head -n 1)
APPS_CPP_FILE=$(find . -name "Apps.cpp" | head -n 1)

echo "Injecting into CMakeLists.txt..."
python3 -c "
with open('$CMAKE_FILE', 'r') as f: lines = f.readlines()
if not any('screens/$APP_NAME.cpp' in l for l in lines):
    for i, line in enumerate(lines):
        if 'screens/Dice.cpp' in line:
            lines.insert(i + 1, '    displayapp/screens/$APP_NAME.cpp\n')
            break
    with open('$CMAKE_FILE', 'w') as f: f.writelines(lines)
"

echo "Injecting into Apps.h..."
python3 -c "
with open('$APPS_H_FILE', 'r') as f: lines = f.readlines()
if not any('$APP_NAME' in l for l in lines):
    for i, line in enumerate(lines):
        if 'Dice' in line and ('{' not in line and '}' not in line):
            # Extract the exact indentation used by the current file
            indent = line_indent = line[''[:len(line)-len(line.lstrip())]] if line.lstrip() else '        '
            lines.insert(i + 1, f'{indent}$APP_NAME,\n')
            break
    with open('$APPS_H_FILE', 'w') as f: f.writelines(lines)
"

echo "Injecting into DisplayApp.cpp..."
python3 -c "
with open('$DISPLAY_APP_FILE', 'r') as f: content = f.read()
if 'displayapp/screens/$APP_NAME.h' not in content:
    content = content.replace('#include \"displayapp/screens/Dice.h\"', '#include \"displayapp/screens/Dice.h\"\n#include \"displayapp/screens/$APP_NAME.h\"')

# Flexible matching for FlashLight block regardless of formatting specifics
if 'case Apps::$APP_NAME:' not in content:
    import re
    pattern = r'(case\s+Apps::FlashLight:.*?break;)'
    replacement = r'\1\n\n    case Apps::$APP_NAME:\n      currentScreen = std::make_unique<Screens::$APP_NAME>(controllers.motionController, controllers.motorController, controllers.settingsController);\n      break;'
    content = re.sub(pattern, replacement, content, flags=re.DOTALL)
    with open('$DISPLAY_APP_FILE', 'w') as f: f.write(content)
"

echo "Injecting into Apps.cpp..."
python3 -c "
with open('$APPS_CPP_FILE', 'r') as f: lines = f.readlines()
if not any('Apps::$APP_NAME' in l for l in lines):
    for i, line in enumerate(lines):
        if 'Apps::Dice' in line:
            # Match the exact array style used
            lines.insert(i + 1, '  {\"\u25A1\", Apps::$APP_NAME, true},\n')
            break
    with open('$APPS_CPP_FILE', 'w') as f: f.writelines(lines)
"

echo "Successfully injected code for $APP_NAME!"
