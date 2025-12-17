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
echo "📱 Checking for connected devices..."
DEVICE_COUNT=$(/Users/alpaybilgic/Library/Android/sdk/platform-tools/adb devices | grep -c "device$" || true)

if [ "$DEVICE_COUNT" -gt 0 ]; then
  echo "📲 Installing APK to device..."
  /Users/alpaybilgic/Library/Android/sdk/platform-tools/adb install -r build/app/outputs/flutter-apk/azuredevops.apk
  echo "✅ APK installed successfully"
  
  echo "🚀 Launching app..."
  /Users/alpaybilgic/Library/Android/sdk/platform-tools/adb shell am start -n io.purplesoft.azuredevops_onprem/io.purplesoft.azuredevops_onprem.MainActivity
  echo "✅ App launched"
else
  echo "⚠️  No device connected. APK built but not deployed."
  echo "   APK location: build/app/outputs/flutter-apk/azuredevops.apk"
fi

echo ""
echo "📤 Pushing to GitHub..."
git push origin main
git push origin "$NEW_TAG"

echo ""
echo "✅ Build, deploy, and push completed!"
echo "   Version: $NEW_VERSION"
echo "   Tag: $NEW_TAG"

