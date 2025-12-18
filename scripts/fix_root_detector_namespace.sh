#!/bin/bash
# Fix root_detector package namespace issue
# This script patches the root_detector package's build.gradle file

set -e

ROOT_DETECTOR_PATH="$HOME/.pub-cache/hosted/pub.dev/root_detector-0.0.6/android/build.gradle"

if [ ! -f "$ROOT_DETECTOR_PATH" ]; then
    echo "⚠️  root_detector package not found at $ROOT_DETECTOR_PATH"
    echo "   This is normal if package hasn't been fetched yet"
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
    # Add namespace line after android {
    sed -i.bak '/android {/a\
    namespace = "space.wisnuwiry.root_detector"
' "$ROOT_DETECTOR_PATH"
    echo "✅ Added namespace to root_detector build.gradle"
else
    echo "⚠️  Could not find android block in root_detector build.gradle"
    exit 1
fi

