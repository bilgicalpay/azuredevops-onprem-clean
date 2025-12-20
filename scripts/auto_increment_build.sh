#!/bin/bash

# Auto-increment build number script
# Reads current version from pubspec.yaml and increments build number

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Get current version (must be in project directory)
cd "$PROJECT_DIR"
CURRENT_VERSION_LINE=$(grep "^version:" pubspec.yaml)
CURRENT_VERSION=$(echo "$CURRENT_VERSION_LINE" | sed 's/version: //')
VERSION_NAME=$(echo "$CURRENT_VERSION" | sed 's/+.*//')
CURRENT_BUILD_NUMBER=$(echo "$CURRENT_VERSION" | sed 's/.*+//')

# Increment build number
NEW_BUILD_NUMBER=$((CURRENT_BUILD_NUMBER + 1))

# Update pubspec.yaml
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' "s/^version: .*/version: ${VERSION_NAME}+${NEW_BUILD_NUMBER}/" pubspec.yaml
else
    # Linux
    sed -i "s/^version: .*/version: ${VERSION_NAME}+${NEW_BUILD_NUMBER}/" pubspec.yaml
fi

echo "✅ Build number incremented: ${CURRENT_BUILD_NUMBER} -> ${NEW_BUILD_NUMBER}"
echo "📦 Version: ${VERSION_NAME}+${NEW_BUILD_NUMBER}"

# Export for use in build commands
export VERSION_NAME
export NEW_BUILD_NUMBER

