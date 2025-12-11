#!/bin/bash
# GenAI Ops Demo Library - Shared Prerequisites Check
# This script validates common requirements across all demos

set -e  # Exit on error

# Parse command line arguments
REQUIRED_SERVICE=""
MIN_AWS_CLI_VERSION="2.31.13"
SKIP_SERVICE_CHECK=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --service)
            REQUIRED_SERVICE="$2"
            shift 2
            ;;
        --min-cli-version)
            MIN_AWS_CLI_VERSION="$2"
            shift 2
            ;;
        --skip-service-check)
            SKIP_SERVICE_CHECK=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

echo -e "\033[0;36m=== GenAI Ops Demo Prerequisites Check ===\033[0m"

# Step 1: Verify AWS credentials
echo -e "\n\033[0;33m[1/4] Verifying AWS credentials...\033[0m"
echo -e "\033[0;90m      (Checking AWS CLI configuration and validating access)\033[0m"

# Check if AWS credentials are configured
if ! CALLER_IDENTITY=$(aws sts get-caller-identity 2>&1); then
    echo -e "\033[0;31mAWS credentials are not configured or have expired\033[0m"
    echo -e "\n\033[0;33mPlease configure AWS credentials using one of these methods:\033[0m"
    echo -e "\033[0;36m  1. Run: aws configure\033[0m"
    echo -e "\033[0;36m  2. Set environment variables: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY\033[0m"
    echo -e "\033[0;36m  3. Use AWS SSO: aws sso login --profile <profile-name>\033[0m"
    echo -e "\n\033[0;90mFor more info: https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html\033[0m"
    exit 1
fi

# Display current AWS identity
ACCOUNT_ID=$(echo "$CALLER_IDENTITY" | grep -o '"Account": "[^"]*' | cut -d'"' -f4)
ARN=$(echo "$CALLER_IDENTITY" | grep -o '"Arn": "[^"]*' | cut -d'"' -f4)
echo -e "\033[0;32m      Authenticated as: $ARN\033[0m"
echo -e "\033[0;32m      AWS Account: $ACCOUNT_ID\033[0m"

# Step 2: Check AWS CLI version
echo -e "\n\033[0;33m[2/4] Checking AWS CLI version...\033[0m"
AWS_VERSION=$(aws --version 2>&1)
if [[ $AWS_VERSION =~ aws-cli/([0-9]+)\.([0-9]+)\.([0-9]+) ]]; then
    MAJOR=${BASH_REMATCH[1]}
    MINOR=${BASH_REMATCH[2]}
    PATCH=${BASH_REMATCH[3]}
    echo -e "\033[0;90m      Current version: aws-cli/$MAJOR.$MINOR.$PATCH\033[0m"
    
    # Parse minimum version requirement
    IFS='.' read -r MIN_MAJOR MIN_MINOR MIN_PATCH <<< "$MIN_AWS_CLI_VERSION"
    
    # Check if version meets minimum requirement
    if [ "$MAJOR" -gt "$MIN_MAJOR" ] || \
       [ "$MAJOR" -eq "$MIN_MAJOR" -a "$MINOR" -gt "$MIN_MINOR" ] || \
       [ "$MAJOR" -eq "$MIN_MAJOR" -a "$MINOR" -eq "$MIN_MINOR" -a "$PATCH" -ge "$MIN_PATCH" ]; then
        echo -e "\033[0;32m      ✓ AWS CLI version is compatible\033[0m"
    else
        echo -e "\033[0;31m      ❌ AWS CLI version $MIN_AWS_CLI_VERSION or later is required\033[0m"
        echo -e ""
        echo -e "\033[0;33m      Your current version: aws-cli/$MAJOR.$MINOR.$PATCH\033[0m"
        echo -e "\033[0;33m      Required version: aws-cli/$MIN_AWS_CLI_VERSION or later\033[0m"
        echo -e ""
        echo -e "\033[0;33m      Please upgrade your AWS CLI:\033[0m"
        echo -e "\033[0;36m        https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html\033[0m"
        exit 1
    fi
else
    echo -e "\033[0;33m      ⚠ Could not parse AWS CLI version, continuing anyway...\033[0m"
fi

# Step 3: Check AWS region configuration
echo -e "\n\033[0;33m[3/4] Checking AWS region configuration...\033[0m"
CURRENT_REGION=$(aws configure get region)
if [ -z "$CURRENT_REGION" ]; then
    echo -e "\033[0;31m      ❌ No AWS region configured\033[0m"
    echo -e ""
    echo -e "\033[0;33m      Please configure your AWS region using:\033[0m"
    echo -e "\033[0;36m        aws configure set region <your-region>\033[0m"
    echo -e ""
    echo -e "\033[0;90m      For supported regions, see AWS service documentation\033[0m"
    exit 1
fi
echo -e "\033[0;90m      Target region: $CURRENT_REGION\033[0m"

# Step 4: Check specific AWS service availability (if specified)
if [ "$SKIP_SERVICE_CHECK" = false ] && [ -n "$REQUIRED_SERVICE" ]; then
    echo -e "\n\033[0;33m[4/4] Checking $REQUIRED_SERVICE availability in $CURRENT_REGION...\033[0m"
    
    case "${REQUIRED_SERVICE,,}" in
        "bedrock")
            if ! aws bedrock list-foundation-models --region "$CURRENT_REGION" --max-results 1 > /dev/null 2>&1; then
                echo -e "\033[0;31m      ❌ Amazon Bedrock is not available in region: $CURRENT_REGION\033[0m"
                echo -e ""
                echo -e "\033[0;90m      For supported regions, see:\033[0m"
                echo -e "\033[0;90m      https://docs.aws.amazon.com/bedrock/latest/userguide/bedrock-regions.html\033[0m"
                exit 1
            fi
            echo -e "\033[0;32m      ✓ Amazon Bedrock is available in $CURRENT_REGION\033[0m"
            ;;
        "agentcore")
            if ! aws bedrock-agentcore-control list-agent-runtimes --region "$CURRENT_REGION" --max-results 1 > /dev/null 2>&1; then
                echo -e "\033[0;31m      ❌ Amazon Bedrock AgentCore is not available in region: $CURRENT_REGION\033[0m"
                echo -e ""
                echo -e "\033[0;90m      For supported regions, see:\033[0m"
                echo -e "\033[0;90m      https://docs.aws.amazon.com/bedrock/latest/userguide/bedrock-regions.html\033[0m"
                exit 1
            fi
            echo -e "\033[0;32m      ✓ Amazon Bedrock AgentCore is available in $CURRENT_REGION\033[0m"
            ;;
        "transform")
            # AWS Transform doesn't have a direct availability check, so we check if the CLI supports it
            if ! aws transform help > /dev/null 2>&1; then
                echo -e "\033[0;31m      ❌ AWS Transform CLI is not available\033[0m"
                echo -e ""
                echo -e "\033[0;33m      AWS Transform requires AWS CLI version 2.31.13 or later\033[0m"
                echo -e "\033[0;33m      Please upgrade your AWS CLI\033[0m"
                exit 1
            fi
            echo -e "\033[0;32m      ✓ AWS Transform CLI is available\033[0m"
            ;;
        *)
            echo -e "\033[0;33m      ⚠ Unknown service '$REQUIRED_SERVICE', skipping service check...\033[0m"
            ;;
    esac
else
    echo -e "\n\033[0;33m[4/4] Skipping service availability check...\033[0m"
fi

# Install CDK dependencies if CDK directory exists
if [ -d "deployment" ]; then
    echo -e "\nInstalling CDK dependencies...\033[0m"
    echo -e "\033[0;90m      (Installing AWS CDK libraries and TypeScript packages)\033[0m"
    if [ ! -d "deployment/node_modules" ]; then
        pushd deployment > /dev/null
        npm install
        popd > /dev/null
        echo -e "\033[0;32m      ✓ CDK dependencies installed\033[0m"
    else
        echo -e "\033[0;90m      ✓ CDK dependencies already installed\033[0m"
    fi
fi

echo -e "\n\033[0;32m✅ All prerequisites validated successfully!\033[0m"
echo -e "\033[0;36mReady to proceed with demo deployment.\033[0m"

# Export variables for use by calling script
export AWS_ACCOUNT_ID="$ACCOUNT_ID"
export AWS_REGION="$CURRENT_REGION"
export AWS_ARN="$ARN"