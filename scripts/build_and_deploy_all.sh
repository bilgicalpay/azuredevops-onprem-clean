#!/bin/bash

# Build and Deploy All - Her derleme sonrasında otomatik deploy
# Android ve iOS için build yapar ve her iki cihaza da deploy eder

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_DIR"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}🚀 Build and Deploy All - Android & iOS${NC}"

# Set Flutter path
export JAVA_HOME=/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home
FLUTTER_CMD="/Users/alpaybilgic/flutter/bin/flutter"
ADB_CMD="/Users/alpaybilgic/Library/Android/sdk/platform-tools/adb"

# Auto-increment build number
echo ""
echo -e "${GREEN}📝 Auto-incrementing build number...${NC}"
source "$SCRIPT_DIR/auto_increment_build.sh"
echo -e "${GREEN}✅ Build number incremented: ${CURRENT_BUILD_NUMBER} -> ${NEW_BUILD_NUMBER}${NC}"
echo -e "${GREEN}📦 Version: ${VERSION_NAME}+${NEW_BUILD_NUMBER}${NC}"

# Build Android
echo ""
echo -e "${GREEN}📦 Building Android APK...${NC}"
$FLUTTER_CMD build apk --release --build-name=${VERSION_NAME} --build-number=${NEW_BUILD_NUMBER} --dart-define=PRODUCTION=true

# Deploy Android
echo ""
echo -e "${GREEN}📱 Deploying to Android device...${NC}"
DEVICE_COUNT=$($ADB_CMD devices | grep -c "device$" || true)

if [ "$DEVICE_COUNT" -gt 0 ]; then
  APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
  if [ -f "$APK_PATH" ]; then
    echo "📲 Installing/Updating APK (will update if app exists)..."
    $ADB_CMD install -r "$APK_PATH"
    echo -e "${GREEN}✅ Android deployment completed!${NC}"
    
    echo "🚀 Launching app..."
    $ADB_CMD shell am start -n com.higgscloud.azuredevops/com.higgscloud.azuredevops.MainActivity
  fi
else
  echo -e "${YELLOW}⚠️  No Android device connected${NC}"
fi

# Build iOS
echo ""
echo -e "${GREEN}🍎 Building iOS for Simulator...${NC}"
$FLUTTER_CMD build ios --simulator --build-name=${VERSION_NAME} --build-number=${NEW_BUILD_NUMBER} --dart-define=PRODUCTION=true

# Deploy iOS
echo ""
echo -e "${GREEN}📱 Deploying to iOS Simulator...${NC}"

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
  fi
else
  echo -e "${YELLOW}⚠️  No iOS Simulator available${NC}"
fi

echo ""
echo -e "${GREEN}✅ Build and deploy completed!${NC}"

