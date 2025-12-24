#!/bin/bash

# Quick Deploy Script - Her derleme sonrasında çalıştırılır
# Android telefonuna ADB ile ve iOS simülatörüne deploy eder
# Build yapmadan sadece deploy eder (build zaten yapılmış olmalı)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_DIR"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}🚀 Quick Deploy - Deploying to Android and iOS...${NC}"

# Android deployment
echo ""
echo -e "${GREEN}📱 Deploying to Android device...${NC}"
DEVICE_COUNT=$(/Users/alpaybilgic/Library/Android/sdk/platform-tools/adb devices | grep -c "device$" || true)

if [ "$DEVICE_COUNT" -gt 0 ]; then
  APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
  if [ -f "$APK_PATH" ]; then
    echo "📲 Installing APK..."
    /Users/alpaybilgic/Library/Android/sdk/platform-tools/adb install -r "$APK_PATH"
    echo -e "${GREEN}✅ Android deployment completed!${NC}"
    
    echo "🚀 Launching app..."
    /Users/alpaybilgic/Library/Android/sdk/platform-tools/adb shell am start -n com.higgscloud.azuredevops/com.higgscloud.azuredevops.MainActivity
  else
    echo -e "${YELLOW}⚠️  APK not found. Run 'flutter build apk --release' first.${NC}"
  fi
else
  echo -e "${YELLOW}⚠️  No Android device connected${NC}"
fi

# iOS deployment
echo ""
echo -e "${GREEN}🍎 Deploying to iOS Simulator...${NC}"

# Open Simulator if not already open
if ! pgrep -x "Simulator" > /dev/null; then
  echo "📱 Opening iOS Simulator..."
  open -a Simulator
  sleep 5
fi

# Get booted simulator
BOOTED_SIM=$(xcrun simctl list devices | grep "Booted" | head -1 | sed 's/.*(\(.*\))/\1/' | tr -d ' ')

if [ -z "$BOOTED_SIM" ]; then
  # Boot first available iPhone
  FIRST_SIM=$(xcrun simctl list devices available | grep -i "iphone" | grep -v "unavailable" | head -1 | sed 's/.*(\(.*\))/\1/' | tr -d ' ')
  if [ -n "$FIRST_SIM" ]; then
    echo "📱 Booting iOS Simulator: $FIRST_SIM"
    xcrun simctl boot "$FIRST_SIM"
    sleep 3
    BOOTED_SIM="$FIRST_SIM"
  fi
fi

if [ -n "$BOOTED_SIM" ]; then
  APP_BUNDLE="build/ios/iphonesimulator/Runner.app"
  if [ -d "$APP_BUNDLE" ]; then
    echo "📲 Installing to iOS Simulator..."
    xcrun simctl install "$BOOTED_SIM" "$APP_BUNDLE"
    echo -e "${GREEN}✅ iOS deployment completed!${NC}"
    
    echo "🚀 Launching app..."
    xcrun simctl launch "$BOOTED_SIM" com.higgscloud.azuredevops
  else
    echo -e "${YELLOW}⚠️  iOS app bundle not found. Run 'flutter build ios --simulator' first.${NC}"
  fi
else
  echo -e "${YELLOW}⚠️  No iOS Simulator available${NC}"
fi

echo ""
echo -e "${GREEN}✅ Quick deploy completed!${NC}"

