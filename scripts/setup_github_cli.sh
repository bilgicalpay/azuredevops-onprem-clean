#!/bin/bash

# GitHub CLI Setup Script
# Helps authenticate GitHub CLI for monitoring workflows

echo "🔐 GitHub CLI Authentication Setup"
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

# Check current auth status
echo "📊 Current authentication status:"
gh auth status 2>&1 || echo "Not authenticated"

echo ""
echo "🔑 To authenticate GitHub CLI, run:"
echo "   gh auth login"
echo ""
echo "Then select:"
echo "   1. GitHub.com"
echo "   2. HTTPS"
echo "   3. Login with a web browser"
echo "   4. Follow the prompts"
echo ""
echo "Or use token authentication:"
echo "   gh auth login --with-token < token.txt"

