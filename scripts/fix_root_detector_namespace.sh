#!/bin/bash
# Fix root_detector package namespace issue
# This script patches the root_detector package's build.gradle file

set -e

# Find root_detector package in pub cache (try multiple versions)
ROOT_DETECTOR_PATHS=(
  "$HOME/.pub-cache/hosted/pub.dev/root_detector-0.0.6/android/build.gradle"
  "$HOME/.pub-cache/hosted/pub.dev/root_detector-0.0.2/android/build.gradle"
  "$HOME/.pub-cache/hosted/pub.dev/root_detector/android/build.gradle"
)

ROOT_DETECTOR_PATH=""
for path in "${ROOT_DETECTOR_PATHS[@]}"; do
  if [ -f "$path" ]; then
    ROOT_DETECTOR_PATH="$path"
    break
  fi
done

if [ -z "$ROOT_DETECTOR_PATH" ]; then
    echo "⚠️  root_detector package not found in pub cache"
    echo "   This is normal if package hasn't been fetched yet"
    echo "   Trying to find in current directory..."
    # Try to find in current project
    if [ -d ".dart_tool/pub/bin/root_detector" ] || [ -d "build/root_detector" ]; then
        echo "   Found root_detector in project, but namespace fix may not be needed"
    fi
    exit 0
fi

# Check if namespace is already set
if grep -q "namespace" "$ROOT_DETECTOR_PATH"; then
    echo "✅ root_detector already has namespace configured"
    exit 0
fi

# Add namespace to build.gradle
echo "🔧 Fixing root_detector namespace..."

# Create backup
cp "$ROOT_DETECTOR_PATH" "$ROOT_DETECTOR_PATH.bak"

# Add namespace after android block starts
if grep -q "android {" "$ROOT_DETECTOR_PATH"; then
    # Use platform-specific sed command
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' '/android {/a\
    namespace = "space.wisnuwiry.root_detector"
' "$ROOT_DETECTOR_PATH"
    else
        # Linux
        sed -i '/android {/a\    namespace = "space.wisnuwiry.root_detector"' "$ROOT_DETECTOR_PATH"
    fi
    echo "✅ Added namespace to root_detector build.gradle"
else
    echo "⚠️  Could not find android block in root_detector build.gradle"
    exit 1
fi

