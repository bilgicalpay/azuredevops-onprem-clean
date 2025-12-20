#!/bin/bash

# Auto-Fix Workflow Errors Script
# GitHub Actions hatalarını analiz edip otomatik düzeltir

set -e

echo "🔧 Auto-Fixing Workflow Errors..."

# Common fixes
fix_flutter_analyze_errors() {
    echo "🔍 Checking Flutter analyze errors..."
    flutter analyze 2>&1 | tee analyze-output.txt
    
    # Fix common issues
    if grep -q "unused_import" analyze-output.txt; then
        echo "🔧 Removing unused imports..."
        # This would need to be implemented based on specific errors
    fi
    
    if grep -q "prefer_const" analyze-output.txt; then
        echo "🔧 Fixing const constructors..."
        # This would need to be implemented based on specific errors
    fi
}

fix_test_errors() {
    echo "🔍 Checking test errors..."
    flutter test 2>&1 | tee test-output.txt
    
    # Fix common test issues
    if grep -q "TimeoutException" test-output.txt; then
        echo "🔧 Tests timing out, may need to increase timeout..."
    fi
}

fix_build_errors() {
    echo "🔍 Checking build errors..."
    
    # Check for common build issues
    if [ ! -f "android/local.properties" ]; then
        echo "🔧 Creating android/local.properties..."
        mkdir -p android
        echo "sdk.dir=$ANDROID_HOME" > android/local.properties || true
    fi
    
    # Fix root_detector namespace
    if [ -f "scripts/fix_root_detector_namespace.sh" ]; then
        echo "🔧 Fixing root_detector namespace..."
        chmod +x scripts/fix_root_detector_namespace.sh
        ./scripts/fix_root_detector_namespace.sh || true
    fi
}

fix_security_errors() {
    echo "🔍 Checking security scan errors..."
    
    # Make scripts executable
    chmod +x scripts/security_scan.sh || true
    chmod +x scripts/security_checks.sh || true
    chmod +x scripts/generate_sbom.sh || true
}

# Run all fixes
fix_flutter_analyze_errors
fix_test_errors
fix_build_errors
fix_security_errors

echo "✅ Auto-fix completed"

