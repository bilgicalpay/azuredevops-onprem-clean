#!/bin/bash

# Simple GitHub Actions watcher
# Monitors the CI/CD pipeline and reports status

REPO="bilgicalpay/azuredevops-server-mobile"
WORKFLOW_NAME="CI/CD + DevSecOps Pipeline"

echo "🔍 Monitoring GitHub Actions workflow: $WORKFLOW_NAME"
echo "Repository: $REPO"
echo ""

# Check if gh CLI is available
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) is not installed"
    echo "Install it with: brew install gh"
    exit 1
fi

# Check authentication
if ! gh auth status &> /dev/null; then
    echo "❌ GitHub CLI is not authenticated"
    echo "Run: gh auth login"
    exit 1
fi

# Get latest workflow runs
echo "📊 Latest workflow runs:"
gh run list --workflow="$WORKFLOW_NAME" --limit 5 --json status,conclusion,name,createdAt,headBranch --jq '.[] | "\(.status) | \(.conclusion // "running") | \(.name) | \(.headBranch) | \(.createdAt)"' || echo "Could not fetch workflow runs"

echo ""
echo "💡 To view detailed logs, run:"
echo "   gh run watch"
echo ""
echo "💡 To view a specific run:"
echo "   gh run view <run-id> --log"

