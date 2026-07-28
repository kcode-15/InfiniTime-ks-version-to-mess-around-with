#!/bin/bash
APP_NAME=$1

echo "=== FINDING FILES ==="
CMAKE_FILE=$(find . -name "CMakeLists.txt" | grep -v "build" | head -n 1)
APPS_H_FILE=$(find . -name "Apps.h" | head -n 1)
DISPLAY_APP_FILE=$(find . -name "DisplayApp.cpp" | head -n 1)
APPS_CPP_FILE=$(find . -name "Apps.cpp" | head -n 1)

echo "Found Apps.h at: $APPS_H_FILE"

echo "=== PRINTING APPS.H CONTENTS FOR DEBUGGING ==="
cat "$APPS_H_FILE"
echo "============================================="

# 1. Injecting into CMakeLists.txt
python3 -c "
with open('$CMAKE_FILE', 'r') as f: lines = f.readlines()
if not any('screens/$APP_NAME.cpp' in l for l in lines):
    for i, line in enumerate(lines):
        if 'screens/Clock.cpp' in line or 'screens/Launcher.cpp' in line:
            lines.insert(i + 1, '    displayapp/screens/$APP_NAME.cpp\n')
            break
    with open('$CMAKE_FILE', 'w') as f: f.writelines(lines)
"

# 2. Injecting into Apps.h (Fallback to injecting right after 'Clock,' or 'Launcher,')
python3 -c "
with open('$APPS_H_FILE', 'r') as f: lines = f.readlines()
if not any('$APP_NAME' in l for l in lines):
    for i, line in enumerate(lines):
        if 'Clock' in line or 'Launcher' in line:
            indent = line[:len(line)-len(line.lstrip())] if line.lstrip() else '        '
            lines.insert(i + 1, f'{indent}$APP_NAME,\n')
            break
    with open('$APPS_H_FILE', 'w') as f: f.writelines(lines)
"

# 3. Injecting into DisplayApp.cpp
python3 -c "
with open('$DISPLAY_APP_FILE', 'r') as f: content = f.read()
if 'displayapp/screens/$APP_NAME.h' not in content:
    content = content.replace('#include \"displayapp/screens/Clock.h\"', '#include \"displayapp/screens/Clock.h\"\n#include \"displayapp/screens/$APP_NAME.h\"')

if 'case Apps::$APP_NAME:' not in content:
    import re
    pattern = r'(case\s+Apps::FlashLight:.*?break;)'
    if 'Apps::FlashLight' not in content:
        pattern = r'(case\s+Apps::Clock:.*?break;)'
    replacement = r'\1\n\n    case Apps::$APP_NAME:\n      currentScreen = std::make_unique<Screens::$APP_NAME>(controllers.motionController, controllers.motorController, controllers.settingsController);\n      break;'
    content = re.sub(pattern, replacement, content, flags=re.DOTALL)
    with open('$DISPLAY_APP_FILE', 'w') as f: f.write(content)
"

# 4. Injecting into Apps.cpp
python3 -c "
with open('$APPS_CPP_FILE', 'r') as f: lines = f.readlines()
if not any('Apps::$APP_NAME' in l for l in lines):
    for i, line in enumerate(lines):
        if 'Apps::Clock' in line or 'Apps::Launcher' in line:
            lines.insert(i + 1, '  {\"\u25A1\", Apps::$APP_NAME, true},\n')
            break
    with open('$APPS_CPP_FILE', 'w') as f: f.writelines(lines)
"

echo "Done running debug script."
