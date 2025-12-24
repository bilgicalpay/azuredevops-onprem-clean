#!/bin/bash

# Deploy to Android and iOS Simulator Script
# Her derleme sonrasında bu script çalıştırılır
# Android telefonuna ADB ile ve iOS simülatörüne deploy eder

set -e

echo "🚀 Starting deployment to Android and iOS devices..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Find Flutter
if command -v flutter &> /dev/null; then
    FLUTTER_CMD="flutter"
elif [ -f "$HOME/flutter/bin/flutter" ]; then
    FLUTTER_CMD="$HOME/flutter/bin/flutter"
elif [ -f "/usr/local/bin/flutter" ]; then
    FLUTTER_CMD="/usr/local/bin/flutter"
else
    echo -e "${RED}❌ Flutter not found. Please add Flutter to PATH or set FLUTTER_CMD${NC}"
    exit 1
fi

# Find ADB
if command -v adb &> /dev/null; then
    ADB_CMD="adb"
elif [ -f "$HOME/Library/Android/sdk/platform-tools/adb" ]; then
    ADB_CMD="$HOME/Library/Android/sdk/platform-tools/adb"
elif [ -f "$ANDROID_HOME/platform-tools/adb" ]; then
    ADB_CMD="$ANDROID_HOME/platform-tools/adb"
else
    echo -e "${YELLOW}⚠️  ADB not found. Android deployment will be skipped.${NC}"
    ADB_CMD=""
fi

# Get project directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

echo -e "${GREEN}📱 Checking devices...${NC}"

# Check Android device
ANDROID_DEVICE=""
if [ -n "$ADB_CMD" ]; then
    ANDROID_DEVICE=$($ADB_CMD devices | grep -v "List" | grep "device$" | head -1 | awk '{print $1}')
    if [ -z "$ANDROID_DEVICE" ]; then
        echo -e "${YELLOW}⚠️  No Android device connected via ADB${NC}"
    else
        echo -e "${GREEN}✅ Android device found: $ANDROID_DEVICE${NC}"
    fi
fi

# Check iOS Simulator
IOS_SIMULATOR=""
if command -v xcrun &> /dev/null; then
    # Get first available iOS simulator
    IOS_SIMULATOR=$(xcrun simctl list devices available | grep -i "iphone\|ipad" | grep -v "unavailable" | head -1 | sed 's/.*(\(.*\))/\1/' | tr -d ' ')
    if [ -z "$IOS_SIMULATOR" ]; then
        echo -e "${YELLOW}⚠️  No iOS simulator found${NC}"
    else
        echo -e "${GREEN}✅ iOS simulator found: $IOS_SIMULATOR${NC}"
    fi
fi

# Auto-increment build number
echo -e "${GREEN}📝 Auto-incrementing build number...${NC}"
source "$SCRIPT_DIR/auto_increment_build.sh"
echo -e "${GREEN}✅ Build number incremented: ${CURRENT_BUILD_NUMBER} -> ${NEW_BUILD_NUMBER}${NC}"
echo -e "${GREEN}📦 Version: ${VERSION_NAME}+${NEW_BUILD_NUMBER}${NC}"

# Build Android APK
if [ -n "$ANDROID_DEVICE" ]; then
    echo -e "${GREEN}📦 Building Android APK...${NC}"
    $FLUTTER_CMD build apk --release --build-name=${VERSION_NAME} --build-number=${NEW_BUILD_NUMBER} --dart-define=PRODUCTION=true
    
    APK_PATH="$PROJECT_DIR/build/app/outputs/flutter-apk/app-release.apk"
    
    if [ -f "$APK_PATH" ]; then
        echo -e "${GREEN}📲 Installing/Updating APK to Android device ($ANDROID_DEVICE) (will update if app exists)...${NC}"
        $ADB_CMD -s "$ANDROID_DEVICE" install -r "$APK_PATH"
        echo -e "${GREEN}✅ Android deployment completed!${NC}"
    else
        echo -e "${RED}❌ APK not found at $APK_PATH${NC}"
    fi
else
    echo -e "${YELLOW}⏭️  Skipping Android deployment (no device connected)${NC}"
fi

# Build and deploy to iOS Simulator
if [ -n "$IOS_SIMULATOR" ]; then
    echo -e "${GREEN}📦 Building iOS for Simulator...${NC}"
    
    # Open Simulator if not already open
    if ! pgrep -x "Simulator" > /dev/null; then
        echo -e "${GREEN}📱 Opening iOS Simulator...${NC}"
        open -a Simulator
        sleep 5  # Wait for simulator to start
    fi
    
    # Build for simulator
    $FLUTTER_CMD build ios --simulator --build-name=${VERSION_NAME} --build-number=${NEW_BUILD_NUMBER} --dart-define=PRODUCTION=true
    
    # Get the app bundle path
    APP_BUNDLE="$PROJECT_DIR/build/ios/iphonesimulator/Runner.app"
    
    if [ -d "$APP_BUNDLE" ]; then
        echo -e "${GREEN}📲 Installing to iOS Simulator...${NC}"
        
        # Get booted simulator UDID
        BOOTED_SIM=$(xcrun simctl list devices | grep "Booted" | head -1 | sed 's/.*(\(.*\))/\1/' | tr -d ' ')
        
        if [ -n "$BOOTED_SIM" ]; then
            xcrun simctl install "$BOOTED_SIM" "$APP_BUNDLE"
            echo -e "${GREEN}✅ iOS Simulator deployment completed!${NC}"
            
            # Launch the app
            echo -e "${GREEN}🚀 Launching app on iOS Simulator...${NC}"
            xcrun simctl launch "$BOOTED_SIM" com.higgscloud.azuredevops
        else
            # Boot the first available simulator
            echo -e "${GREEN}📱 Booting iOS Simulator...${NC}"
            FIRST_SIM=$(xcrun simctl list devices available | grep -i "iphone" | grep -v "unavailable" | head -1 | sed 's/.*(\(.*\))/\1/' | tr -d ' ')
            if [ -n "$FIRST_SIM" ]; then
                xcrun simctl boot "$FIRST_SIM"
                sleep 3
                xcrun simctl install "$FIRST_SIM" "$APP_BUNDLE"
                xcrun simctl launch "$FIRST_SIM" com.higgscloud.azuredevops
                echo -e "${GREEN}✅ iOS Simulator deployment completed!${NC}"
            fi
        fi
    else
        echo -e "${RED}❌ iOS app bundle not found at $APP_BUNDLE${NC}"
    fi
else
    echo -e "${YELLOW}⏭️  Skipping iOS deployment (no simulator found)${NC}"
fi

echo -e "${GREEN}✅ Deployment process completed!${NC}"

