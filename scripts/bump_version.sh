#!/bin/bash

# Script to automatically bump version and create git tag
# Usage: ./scripts/bump_version.sh [patch|minor|major]

set -e

# Get current version from pubspec.yaml
CURRENT_VERSION=$(grep '^version:' pubspec.yaml | sed 's/version: //' | tr -d ' ')
VERSION_NUMBER=$(echo $CURRENT_VERSION | cut -d'+' -f1)
BUILD_NUMBER=$(echo $CURRENT_VERSION | cut -d'+' -f2)

echo "Current version: $CURRENT_VERSION"
echo "Version number: $VERSION_NUMBER"
echo "Build number: $BUILD_NUMBER"

# Determine version bump type (default: patch)
BUMP_TYPE=${1:-patch}

# Parse version components
MAJOR=$(echo $VERSION_NUMBER | cut -d'.' -f1)
MINOR=$(echo $VERSION_NUMBER | cut -d'.' -f2)
PATCH=$(echo $VERSION_NUMBER | cut -d'.' -f3)

# Bump version based on type
case $BUMP_TYPE in
  major)
    NEW_MAJOR=$((MAJOR + 1))
    NEW_MINOR=0
    NEW_PATCH=0
    ;;
  minor)
    NEW_MAJOR=$MAJOR
    NEW_MINOR=$((MINOR + 1))
    NEW_PATCH=0
    ;;
  patch)
    NEW_MAJOR=$MAJOR
    NEW_MINOR=$MINOR
    NEW_PATCH=$((PATCH + 1))
    ;;
  *)
    echo "Invalid bump type: $BUMP_TYPE. Use patch, minor, or major."
    exit 1
    ;;
esac

# Increment build number
NEW_BUILD_NUMBER=$((BUILD_NUMBER + 1))

# Create new version strings
NEW_VERSION_NUMBER="$NEW_MAJOR.$NEW_MINOR.$NEW_PATCH"
NEW_VERSION="$NEW_VERSION_NUMBER+$NEW_BUILD_NUMBER"
NEW_TAG="v$NEW_VERSION_NUMBER"

echo "New version: $NEW_VERSION"
echo "New tag: $NEW_TAG"

# Update pubspec.yaml
if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS
  sed -i '' "s/^version: .*/version: $NEW_VERSION/" pubspec.yaml
else
  # Linux
  sed -i "s/^version: .*/version: $NEW_VERSION/" pubspec.yaml
fi

echo "✅ Updated pubspec.yaml to version $NEW_VERSION"

# Git operations
git add pubspec.yaml
git commit -m "chore(release): Bump version to $NEW_VERSION [skip ci]"
git tag -a "$NEW_TAG" -m "Release $NEW_TAG"

echo "✅ Created git commit and tag $NEW_TAG"
echo ""
echo "To push changes and tags, run:"
echo "  git push origin main"
echo "  git push origin $NEW_TAG"

