#!/bin/bash

# CI/CD Build Monitor and Auto-Fix Script
# GitHub Actions build'lerini izler ve hataları otomatik düzeltir
# Cursor tarafından otomatik çalıştırılır

set -e

REPO="bilgicalpay/azuredevops-server-mobile"
BRANCH="main"
MAX_RETRIES=3
RETRY_COUNT=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}🔍 Monitoring CI/CD Pipeline for $REPO (branch: $BRANCH)${NC}"

# Function to check workflow status
check_workflow_status() {
    echo -e "${YELLOW}📊 Checking workflow status...${NC}"
    
    # Get latest workflow run
    WORKFLOW_RUN=$(gh run list --workflow="CI/CD + DevSecOps Pipeline" --branch="$BRANCH" --limit 1 --json databaseId,status,conclusion --jq '.[0]' 2>/dev/null || echo '{"status":"unknown"}')
    
    if [ "$WORKFLOW_RUN" == '{"status":"unknown"}' ] || [ -z "$WORKFLOW_RUN" ]; then
        echo -e "${YELLOW}⚠️  Could not fetch workflow status. Make sure GitHub CLI is authenticated.${NC}"
        return 1
    fi
    
    STATUS=$(echo "$WORKFLOW_RUN" | jq -r '.status' 2>/dev/null || echo "unknown")
    CONCLUSION=$(echo "$WORKFLOW_RUN" | jq -r '.conclusion' 2>/dev/null || echo "unknown")
    RUN_ID=$(echo "$WORKFLOW_RUN" | jq -r '.databaseId' 2>/dev/null || echo "")
    
    echo "Status: $STATUS, Conclusion: $CONCLUSION, Run ID: $RUN_ID"
    
    if [ "$STATUS" == "completed" ] && [ "$CONCLUSION" == "success" ]; then
        echo -e "${GREEN}✅ Build completed successfully!${NC}"
        return 0
    elif [ "$STATUS" == "completed" ] && [ "$CONCLUSION" != "success" ]; then
        echo -e "${RED}❌ Build failed with conclusion: $CONCLUSION${NC}"
        return 2
    elif [ "$STATUS" == "in_progress" ] || [ "$STATUS" == "queued" ]; then
        echo -e "${YELLOW}⏳ Build is still running...${NC}"
        return 1
    else
        echo -e "${YELLOW}ℹ️  Build status: $STATUS${NC}"
        return 1
    fi
}

# Function to get workflow logs
get_workflow_logs() {
    RUN_ID=$1
    if [ -z "$RUN_ID" ] || [ "$RUN_ID" == "null" ]; then
        echo -e "${YELLOW}⚠️  No run ID available${NC}"
        return
    fi
    
    echo -e "${YELLOW}📋 Fetching workflow logs for run $RUN_ID...${NC}"
    gh run view "$RUN_ID" --log 2>/dev/null | tail -100 || echo "Could not fetch logs"
}

# Function to analyze and fix errors
analyze_and_fix() {
    RUN_ID=$1
    LOGS=$(get_workflow_logs "$RUN_ID")
    
    echo -e "${YELLOW}🔍 Analyzing errors...${NC}"
    
    # Common error patterns and fixes
    if echo "$LOGS" | grep -q "Flutter analyze failed"; then
        echo -e "${RED}❌ Flutter analyze errors detected${NC}"
        echo -e "${YELLOW}🔧 Running flutter analyze locally to see errors...${NC}"
        flutter analyze || true
        return 1
    fi
    
    if echo "$LOGS" | grep -q "Tests failed"; then
        echo -e "${RED}❌ Test failures detected${NC}"
        echo -e "${YELLOW}🔧 Running tests locally to see errors...${NC}"
        flutter test || true
        return 1
    fi
    
    if echo "$LOGS" | grep -q "build failed"; then
        echo -e "${RED}❌ Build errors detected${NC}"
        return 1
    fi
    
    if echo "$LOGS" | grep -q "SBOM generation failed"; then
        echo -e "${RED}❌ SBOM generation failed${NC}"
        echo -e "${YELLOW}🔧 Checking SBOM script...${NC}"
        chmod +x scripts/generate_sbom.sh
        ./scripts/generate_sbom.sh || true
        return 1
    fi
    
    if echo "$LOGS" | grep -q "Security scan failed"; then
        echo -e "${RED}❌ Security scan failed${NC}"
        echo -e "${YELLOW}🔧 Running security scan locally...${NC}"
        chmod +x scripts/security_scan.sh
        ./scripts/security_scan.sh || true
        return 1
    fi
    
    echo -e "${YELLOW}⚠️  Unknown error pattern. Manual review needed.${NC}"
    return 1
}

# Main monitoring loop
monitor_build() {
    while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
        check_workflow_status
        STATUS_CODE=$?
        
        if [ $STATUS_CODE -eq 0 ]; then
            echo -e "${GREEN}✅ Build successful! Pipeline completed.${NC}"
            exit 0
        elif [ $STATUS_CODE -eq 2 ]; then
            # Build failed, get run ID and analyze
            WORKFLOW_RUN=$(gh run list --workflow="CI/CD + DevSecOps Pipeline" --branch="$BRANCH" --limit 1 --json databaseId,status,conclusion --jq '.[0]' 2>/dev/null || echo '{}')
            RUN_ID=$(echo "$WORKFLOW_RUN" | jq -r '.databaseId' 2>/dev/null || echo "")
            
            echo -e "${RED}❌ Build failed. Analyzing errors...${NC}"
            analyze_and_fix "$RUN_ID"
            
            RETRY_COUNT=$((RETRY_COUNT + 1))
            if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
                echo -e "${YELLOW}🔄 Waiting 30 seconds before retry ($RETRY_COUNT/$MAX_RETRIES)...${NC}"
                sleep 30
            fi
        else
            # Still running or unknown status
            echo -e "${YELLOW}⏳ Waiting 60 seconds before next check...${NC}"
            sleep 60
        fi
    done
    
    if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then
        echo -e "${RED}❌ Maximum retries reached. Manual intervention needed.${NC}"
        exit 1
    fi
}

# Check if GitHub CLI is installed and authenticated
if ! command -v gh &> /dev/null; then
    echo -e "${RED}❌ GitHub CLI (gh) is not installed${NC}"
    echo -e "${YELLOW}Install it with: brew install gh${NC}"
    echo -e "${YELLOW}Or visit: https://cli.github.com/${NC}"
    echo ""
    echo -e "${YELLOW}Alternative: Check workflow status manually at:${NC}"
    echo -e "${YELLOW}https://github.com/$REPO/actions${NC}"
    exit 1
fi

if ! gh auth status &> /dev/null; then
    echo -e "${RED}❌ GitHub CLI is not authenticated${NC}"
    echo ""
    echo -e "${YELLOW}To authenticate, run:${NC}"
    echo -e "${YELLOW}  gh auth login${NC}"
    echo ""
    echo -e "${YELLOW}Then select:${NC}"
    echo -e "${YELLOW}  1. GitHub.com${NC}"
    echo -e "${YELLOW}  2. HTTPS${NC}"
    echo -e "${YELLOW}  3. Login with a web browser${NC}"
    echo ""
    echo -e "${YELLOW}Or check workflow status manually at:${NC}"
    echo -e "${YELLOW}https://github.com/$REPO/actions${NC}"
    echo ""
    read -p "Do you want to authenticate now? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        gh auth login
        if gh auth status &> /dev/null; then
            echo -e "${GREEN}✅ Authentication successful!${NC}"
        else
            echo -e "${RED}❌ Authentication failed${NC}"
            exit 1
        fi
    else
        exit 1
    fi
fi

# Start monitoring
monitor_build

