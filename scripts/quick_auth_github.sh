#!/bin/bash

# Quick GitHub CLI Authentication Helper
# Interactive script to authenticate GitHub CLI

set -e

echo "🔐 GitHub CLI Authentication Helper"
echo ""

# Check if gh is installed
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) is not installed"
    echo ""
    echo "Install it with:"
    echo "  brew install gh"
    echo ""
    echo "Or visit: https://cli.github.com/"
    exit 1
fi

echo "✅ GitHub CLI is installed"
echo ""

# Check current status
echo "📊 Current authentication status:"
if gh auth status &> /dev/null; then
    echo "✅ Already authenticated!"
    gh auth status
    exit 0
fi

echo "❌ Not authenticated"
echo ""

# Interactive authentication
echo "🔑 Starting authentication process..."
echo ""
echo "You will be asked to:"
echo "  1. Choose GitHub.com"
echo "  2. Choose HTTPS"
echo "  3. Choose 'Login with a web browser'"
echo "  4. Copy the code and press Enter"
echo "  5. Authorize in your browser"
echo ""
read -p "Press Enter to continue..." 

gh auth login

# Verify authentication
if gh auth status &> /dev/null; then
    echo ""
    echo "✅ Authentication successful!"
    echo ""
    echo "You can now use:"
    echo "  ./scripts/monitor_and_fix_ci.sh"
    echo "  gh run list"
    echo "  gh run watch"
else
    echo ""
    echo "❌ Authentication failed. Please try again."
    exit 1
fi

