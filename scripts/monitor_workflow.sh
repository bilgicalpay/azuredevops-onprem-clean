#!/bin/bash

# GitHub Actions Workflow Monitor
# Monitors workflow runs and reports status

set -e

REPO="bilgicalpay/azuredevops-server-mobile"
WORKFLOW_NAME="CI/CD + DevSecOps Pipeline"
MAX_CHECKS=60
CHECK_INTERVAL=30

echo "🔍 Monitoring GitHub Actions Workflow"
echo "Repository: $REPO"
echo "Workflow: $WORKFLOW_NAME"
echo ""

# Function to get latest workflow run
get_latest_run() {
    if command -v gh &> /dev/null && gh auth status &> /dev/null; then
        gh run list --workflow="$WORKFLOW_NAME" --limit 1 --json databaseId,status,conclusion,name,createdAt,headBranch,url --jq '.[0]' 2>/dev/null
    else
        echo "{}"
    fi
}

# Function to get run logs
get_run_logs() {
    RUN_ID=$1
    if [ -n "$RUN_ID" ] && [ "$RUN_ID" != "null" ] && command -v gh &> /dev/null; then
        gh run view "$RUN_ID" --log 2>/dev/null | tail -50 || echo "Could not fetch logs"
    fi
}

# Function to check for errors in logs
check_errors() {
    LOGS=$1
    if echo "$LOGS" | grep -qi "error\|failed\|❌"; then
        echo "⚠️  Errors detected in logs"
        echo "$LOGS" | grep -i "error\|failed\|❌" | head -10
        return 1
    fi
    return 0
}

# Monitor loop
CHECK_COUNT=0
LAST_STATUS=""

while [ $CHECK_COUNT -lt $MAX_CHECKS ]; do
    CHECK_COUNT=$((CHECK_COUNT + 1))
    
    echo "[$CHECK_COUNT/$MAX_CHECKS] Checking workflow status..."
    
    RUN_INFO=$(get_latest_run)
    
    if [ "$RUN_INFO" == "{}" ] || [ -z "$RUN_INFO" ]; then
        echo "⚠️  Could not fetch workflow status"
        echo "💡 Check manually at: https://github.com/$REPO/actions"
        sleep $CHECK_INTERVAL
        continue
    fi
    
    STATUS=$(echo "$RUN_INFO" | jq -r '.status' 2>/dev/null || echo "unknown")
    CONCLUSION=$(echo "$RUN_INFO" | jq -r '.conclusion // "running"' 2>/dev/null || echo "unknown")
    RUN_ID=$(echo "$RUN_INFO" | jq -r '.databaseId' 2>/dev/null || echo "")
    URL=$(echo "$RUN_INFO" | jq -r '.url' 2>/dev/null || echo "")
    BRANCH=$(echo "$RUN_INFO" | jq -r '.headBranch' 2>/dev/null || echo "")
    
    echo "Status: $STATUS | Conclusion: $CONCLUSION | Branch: $BRANCH"
    
    if [ "$STATUS" != "$LAST_STATUS" ]; then
        echo "📊 Status changed: $LAST_STATUS -> $STATUS"
        LAST_STATUS=$STATUS
    fi
    
    if [ "$STATUS" == "completed" ]; then
        if [ "$CONCLUSION" == "success" ]; then
            echo ""
            echo "✅ Workflow completed successfully!"
            echo "🔗 View run: $URL"
            exit 0
        else
            echo ""
            echo "❌ Workflow failed with conclusion: $CONCLUSION"
            echo "🔗 View run: $URL"
            
            if [ -n "$RUN_ID" ] && [ "$RUN_ID" != "null" ]; then
                echo ""
                echo "📋 Fetching error logs..."
                LOGS=$(get_run_logs "$RUN_ID")
                check_errors "$LOGS"
            fi
            
            exit 1
        fi
    elif [ "$STATUS" == "in_progress" ] || [ "$STATUS" == "queued" ]; then
        echo "⏳ Workflow is $STATUS..."
        if [ -n "$URL" ]; then
            echo "🔗 View run: $URL"
        fi
    else
        echo "ℹ️  Workflow status: $STATUS"
    fi
    
    sleep $CHECK_INTERVAL
done

echo ""
echo "⏱️  Maximum checks reached. Workflow may still be running."
echo "💡 Check manually at: https://github.com/$REPO/actions"
exit 0

