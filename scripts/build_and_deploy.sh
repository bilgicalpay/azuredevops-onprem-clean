#!/bin/bash

# Script to build, bump version, tag, and deploy Android app
# Usage: ./scripts/build_and_deploy.sh [patch|minor|major]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_DIR"

# Bump version first
echo "📦 Bumping version..."
"$SCRIPT_DIR/bump_version.sh" "${1:-patch}"

# Get new version for tag
NEW_VERSION=$(grep '^version:' pubspec.yaml | sed 's/version: //' | tr -d ' ')
VERSION_NUMBER=$(echo $NEW_VERSION | cut -d'+' -f1)
NEW_TAG="v$VERSION_NUMBER"

echo ""
echo "🔨 Building Android APK..."
export JAVA_HOME=/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home
/Users/alpaybilgic/flutter/bin/flutter build apk --release

# Rename APK
if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
  mv build/app/outputs/flutter-apk/app-release.apk build/app/outputs/flutter-apk/azuredevops.apk
  echo "✅ APK renamed to azuredevops.apk"
fi

echo ""
echo "📱 Deploying to Android device..."
DEVICE_COUNT=$(/Users/alpaybilgic/Library/Android/sdk/platform-tools/adb devices | grep -c "device$" || true)

if [ "$DEVICE_COUNT" -gt 0 ]; then
  echo "📲 Installing APK to device..."
  /Users/alpaybilgic/Library/Android/sdk/platform-tools/adb install -r build/app/outputs/flutter-apk/azuredevops.apk
  echo "✅ APK installed successfully"
  
  echo "🚀 Launching app..."
  /Users/alpaybilgic/Library/Android/sdk/platform-tools/adb shell am start -n com.higgscloud.azuredevops/com.higgscloud.azuredevops.MainActivity
  echo "✅ App launched"
else
  echo "⚠️  No Android device connected. APK built but not deployed."
  echo "   APK location: build/app/outputs/flutter-apk/azuredevops.apk"
fi

echo ""
echo "🍎 Building iOS for Simulator..."
/Users/alpaybilgic/flutter/bin/flutter build ios --simulator

echo ""
echo "📱 Deploying to iOS Simulator..."
# Open Simulator if not already open
if ! pgrep -x "Simulator" > /dev/null; then
  echo "📱 Opening iOS Simulator..."
  open -a Simulator
  sleep 5  # Wait for simulator to start
fi

# Get booted simulator UDID
BOOTED_SIM=$(xcrun simctl list devices | grep "Booted" | head -1 | sed 's/.*(\(.*\))/\1/' | tr -d ' ')

if [ -z "$BOOTED_SIM" ]; then
  # Boot the first available iPhone simulator
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
    echo "✅ iOS app installed"
    
    echo "🚀 Launching app on iOS Simulator..."
    xcrun simctl launch "$BOOTED_SIM" com.higgscloud.azuredevops
    echo "✅ App launched on iOS Simulator"
  else
    echo "⚠️  iOS app bundle not found at $APP_BUNDLE"
  fi
else
  echo "⚠️  No iOS Simulator available"
fi

echo ""
echo "📤 Pushing to GitHub..."
git push origin main
git push origin "$NEW_TAG"

echo ""
echo "✅ Build, deploy, and push completed!"
echo "   Version: $NEW_VERSION"
echo "   Tag: $NEW_TAG"

