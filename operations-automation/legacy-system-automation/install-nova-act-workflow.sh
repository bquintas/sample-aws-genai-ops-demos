#!/bin/bash
# AI-Powered Legacy System Automation - Setup Script
# Installs Nova Act SDK and creates the workflow definition

set -e

echo "============================================="
echo "AI-Powered Legacy System Automation Setup"
echo "============================================="

# Step 1: Check Python
echo ""
echo "[1/3] Checking Python..."
PYTHON_VERSION=$(python3 --version 2>&1 || python --version 2>&1)
if [[ $PYTHON_VERSION =~ Python\ ([0-9]+)\.([0-9]+) ]]; then
    MAJOR=${BASH_REMATCH[1]}
    MINOR=${BASH_REMATCH[2]}
    if [ "$MAJOR" -ge 3 ] && [ "$MINOR" -ge 10 ]; then
        echo "      ✓ $PYTHON_VERSION"
    else
        echo "      ❌ Python 3.10+ required (found $PYTHON_VERSION)"
        exit 1
    fi
else
    echo "      ❌ Python not found"
    exit 1
fi

# Step 2: Install Nova Act SDK
echo ""
echo "[2/3] Installing Nova Act SDK..."
pip install nova-act --quiet
echo "      ✓ Nova Act SDK installed"

# Step 3: Create workflow definition
echo ""
echo "[3/3] Creating Nova Act workflow definition..."

WORKFLOW_NAME="legacy-system-automation"

# Check region
CURRENT_REGION=$(aws configure get region 2>/dev/null)
if [ "$CURRENT_REGION" != "us-east-1" ]; then
    echo "      Setting region to us-east-1 (Nova Act requirement)..."
    aws configure set region us-east-1
fi

# Check if workflow exists
if aws nova-act list-workflow-definitions --region us-east-1 2>/dev/null | grep -q "\"name\": \"$WORKFLOW_NAME\""; then
    echo "      ✓ Workflow '$WORKFLOW_NAME' already exists"
else
    if aws nova-act create-workflow-definition --name "$WORKFLOW_NAME" --region us-east-1 2>/dev/null; then
        echo "      ✓ Workflow '$WORKFLOW_NAME' created"
    else
        echo "      ⚠ Could not create workflow (check AWS credentials)"
    fi
fi

# Done
echo ""
echo "============================================="
echo "Setup Complete!"
echo "============================================="
echo ""
echo "Run the phpMyAdmin demo:"
echo "  python -m scenarios.phpmyadmin_create_database --cleanup"
echo ""
