#!/bin/bash

# Check GitHub Actions Workflow Syntax
# Validates YAML syntax and basic structure

set -e

WORKFLOW_FILE=".github/workflows/ci-cd-devsecops.yml"

echo "🔍 Checking workflow syntax: $WORKFLOW_FILE"
echo ""

# Check if file exists
if [ ! -f "$WORKFLOW_FILE" ]; then
    echo "❌ Workflow file not found: $WORKFLOW_FILE"
    exit 1
fi

# Check YAML syntax with Python
if command -v python3 &> /dev/null; then
    echo "📋 Validating YAML syntax..."
    if python3 -c "import yaml; yaml.safe_load(open('$WORKFLOW_FILE'))" 2>/dev/null; then
        echo "✅ YAML syntax is valid"
    else
        echo "❌ YAML syntax error"
        python3 -c "import yaml; yaml.safe_load(open('$WORKFLOW_FILE'))" 2>&1
        exit 1
    fi
else
    echo "⚠️  Python3 not found, skipping YAML validation"
fi

# Check for common issues
echo ""
echo "🔍 Checking for common issues..."

# Check for deprecated actions
if grep -q "actions/checkout@v3" "$WORKFLOW_FILE"; then
    echo "⚠️  Found deprecated checkout action v3, consider upgrading to v4"
fi

# Check for required fields
if ! grep -q "name:" "$WORKFLOW_FILE"; then
    echo "❌ Missing 'name' field"
    exit 1
fi

if ! grep -q "on:" "$WORKFLOW_FILE"; then
    echo "❌ Missing 'on' field"
    exit 1
fi

if ! grep -q "jobs:" "$WORKFLOW_FILE"; then
    echo "❌ Missing 'jobs' field"
    exit 1
fi

echo "✅ Basic structure looks good"
echo ""
echo "💡 To validate on GitHub, push to a branch and check Actions tab"
echo "💡 Or use: act (local GitHub Actions runner) for local testing"

