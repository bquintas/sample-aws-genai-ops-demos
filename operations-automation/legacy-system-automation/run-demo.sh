#!/bin/bash
# AI-Powered Legacy System Automation - Demo Runner
# One-click setup and demo execution

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKIP_SETUP=false
CLEANUP=false
HEADLESS=false
DB_NAME=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-setup)
            SKIP_SETUP=true
            shift
            ;;
        --cleanup)
            CLEANUP=true
            shift
            ;;
        --headless)
            HEADLESS=true
            shift
            ;;
        --db-name)
            DB_NAME="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --skip-setup        Skip prerequisite checks and setup"
            echo "  --cleanup           Delete database after creation"
            echo "  --headless          Run browser in headless mode"
            echo "  --db-name <name>    Custom database name (default: auto-generated)"
            echo "  -h, --help          Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

echo ""
echo "============================================================"
echo "  AI-Powered Legacy System Automation with Nova Act"
echo "============================================================"
echo ""

# ============================================================
# STEP 1: Setup (unless skipped)
# ============================================================
if [ "$SKIP_SETUP" = false ]; then
    echo "[SETUP] Checking prerequisites..."
    echo ""
    
    # Check Python
    echo "  Checking Python..."
    PYTHON_VERSION=$(python3 --version 2>&1 || python --version 2>&1 || echo "not found")
    if [[ "$PYTHON_VERSION" =~ Python\ ([0-9]+)\.([0-9]+) ]]; then
        MAJOR="${BASH_REMATCH[1]}"
        MINOR="${BASH_REMATCH[2]}"
        if [ "$MAJOR" -ge 3 ] && [ "$MINOR" -ge 10 ]; then
            echo "  ✓ $PYTHON_VERSION"
        else
            echo "  ❌ Python 3.10+ required (found $PYTHON_VERSION)"
            exit 1
        fi
    else
        echo "  ❌ Python not found. Install from https://python.org"
        exit 1
    fi
    
    # Check AWS credentials
    echo "  Checking AWS credentials..."
    AWS_CHECK=$(aws sts get-caller-identity 2>/dev/null || echo "FAILED")
    if [[ "$AWS_CHECK" == "FAILED" ]]; then
        echo "  ❌ AWS credentials not configured. Run: aws configure"
        exit 1
    fi
    echo "  ✓ AWS credentials configured"
    
    # Check/set region
    echo "  Checking AWS region..."
    CURRENT_REGION=$(aws configure get region 2>/dev/null || echo "")
    if [ "$CURRENT_REGION" != "us-east-1" ]; then
        echo "  Setting region to us-east-1 (Nova Act requirement)..."
        aws configure set region us-east-1
    fi
    echo "  ✓ Region: us-east-1"
    
    # Install Nova Act SDK
    echo "  Installing Nova Act SDK..."
    pip install nova-act --quiet 2>/dev/null
    echo "  ✓ Nova Act SDK installed"
    
    # Create workflow definition
    echo "  Creating workflow definition..."
    WORKFLOW_NAME="legacy-system-automation"
    DEFINITIONS=$(aws nova-act list-workflow-definitions --region us-east-1 2>/dev/null || echo '{"workflowDefinitions":[]}')
    
    if echo "$DEFINITIONS" | grep -q "$WORKFLOW_NAME"; then
        echo "  ✓ Workflow '$WORKFLOW_NAME' exists"
    else
        aws nova-act create-workflow-definition --name "$WORKFLOW_NAME" --region us-east-1 2>/dev/null || true
        echo "  ✓ Workflow '$WORKFLOW_NAME' created"
    fi
    
    echo ""
    echo "[SETUP] Complete!"
    echo ""
fi

# ============================================================
# STEP 2: Run Demo
# ============================================================
echo "------------------------------------------------------------"
echo "[DEMO] Creating database in phpMyAdmin..."
echo "------------------------------------------------------------"
echo ""

# Build command arguments
ARGS=""
if [ "$CLEANUP" = true ]; then ARGS="$ARGS --cleanup"; fi
if [ "$HEADLESS" = true ]; then ARGS="$ARGS --headless"; fi
if [ -n "$DB_NAME" ]; then ARGS="$ARGS --db-name $DB_NAME"; fi

cd "$SCRIPT_DIR"
python create_database.py $ARGS

echo ""
echo "============================================================"
echo "  Demo Complete!"
echo "============================================================"
echo ""
