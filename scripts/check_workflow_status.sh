#!/bin/bash

# Simple workflow status checker
# Works without GitHub CLI by using GitHub API directly

REPO="bilgicalpay/azuredevops-server-mobile"
WORKFLOW_FILE="ci-cd-devsecops.yml"

echo "🔍 Checking GitHub Actions Workflow Status"
echo "Repository: $REPO"
echo "Workflow: $WORKFLOW_FILE"
echo ""

# Try GitHub CLI first
if command -v gh &> /dev/null && gh auth status &> /dev/null; then
    echo "✅ Using GitHub CLI"
    echo ""
    gh run list --workflow="$WORKFLOW_FILE" --limit 5 --json status,conclusion,name,createdAt,headBranch,url --jq '.[] | "\(.status) | \(.conclusion // "running") | \(.name) | \(.headBranch) | \(.createdAt) | \(.url)"' 2>/dev/null || echo "Could not fetch runs"
    echo ""
    echo "💡 View latest run: gh run watch"
    exit 0
fi

# Fallback: Direct GitHub API (requires GITHUB_TOKEN or manual check)
echo "⚠️  GitHub CLI not authenticated"
echo ""
echo "Option 1: Authenticate GitHub CLI"
echo "   Run: gh auth login"
echo ""
echo "Option 2: Check manually on GitHub"
echo "   Visit: https://github.com/$REPO/actions"
echo ""
echo "Option 3: Use GitHub API with token"
echo "   export GITHUB_TOKEN=your_token"
echo "   Then run this script again"
echo ""

# If GITHUB_TOKEN is set, use API
if [ -n "$GITHUB_TOKEN" ]; then
    echo "📡 Using GitHub API..."
    curl -s -H "Authorization: token $GITHUB_TOKEN" \
        "https://api.github.com/repos/$REPO/actions/workflows/$WORKFLOW_FILE/runs?per_page=5" \
        | jq -r '.workflow_runs[] | "\(.status) | \(.conclusion // "running") | \(.name) | \(.head_branch) | \(.created_at) | \(.html_url)"' 2>/dev/null || \
    echo "API call failed. Check your token permissions."
fi

