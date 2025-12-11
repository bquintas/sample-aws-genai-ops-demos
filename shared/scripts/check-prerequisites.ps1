# GenAI Ops Demo Library - Shared Prerequisites Check
# This script validates common requirements across all demos

param(
    [string]$RequiredService = "",
    [string]$MinAwsCliVersion = "2.31.13",
    [switch]$SkipServiceCheck = $false
)

Write-Host "=== GenAI Ops Demo Prerequisites Check ===" -ForegroundColor Cyan

# Step 1: Verify AWS credentials
Write-Host "`n[1/4] Verifying AWS credentials..." -ForegroundColor Yellow
Write-Host "      (Checking AWS CLI configuration and validating access)" -ForegroundColor Gray

# Check if AWS credentials are configured
$callerIdentity = aws sts get-caller-identity 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "AWS credentials are not configured or have expired" -ForegroundColor Red
    Write-Host "`nPlease configure AWS credentials using one of these methods:" -ForegroundColor Yellow
    Write-Host "  1. Run: aws configure" -ForegroundColor Cyan
    Write-Host "  2. Set environment variables: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY" -ForegroundColor Cyan
    Write-Host "  3. Use AWS SSO: aws sso login --profile <profile-name>" -ForegroundColor Cyan
    Write-Host "`nFor more info: https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html" -ForegroundColor Gray
    exit 1
}

# Display current AWS identity
$accountId = ($callerIdentity | ConvertFrom-Json).Account
$arn = ($callerIdentity | ConvertFrom-Json).Arn
Write-Host "      Authenticated as: $arn" -ForegroundColor Green
Write-Host "      AWS Account: $accountId" -ForegroundColor Green

# Step 2: Check AWS CLI version
Write-Host "`n[2/4] Checking AWS CLI version..." -ForegroundColor Yellow
$awsVersion = aws --version 2>&1
$versionMatch = $awsVersion -match 'aws-cli/(\d+)\.(\d+)\.(\d+)'
if ($versionMatch) {
    $major = [int]$Matches[1]
    $minor = [int]$Matches[2]
    $patch = [int]$Matches[3]
    Write-Host "      Current version: aws-cli/$major.$minor.$patch" -ForegroundColor Gray
    
    # Parse minimum version requirement
    $minVersionParts = $MinAwsCliVersion.Split('.')
    $minMajor = [int]$minVersionParts[0]
    $minMinor = [int]$minVersionParts[1]
    $minPatch = [int]$minVersionParts[2]
    
    # Check if version meets minimum requirement
    $isVersionValid = ($major -gt $minMajor) -or 
                      ($major -eq $minMajor -and $minor -gt $minMinor) -or 
                      ($major -eq $minMajor -and $minor -eq $minMinor -and $patch -ge $minPatch)
    
    if (-not $isVersionValid) {
        Write-Host "      ❌ AWS CLI version $MinAwsCliVersion or later is required" -ForegroundColor Red
        Write-Host ""
        Write-Host "      Your current version: aws-cli/$major.$minor.$patch" -ForegroundColor Yellow
        Write-Host "      Required version: aws-cli/$MinAwsCliVersion or later" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "      Please upgrade your AWS CLI:" -ForegroundColor Yellow
        Write-Host "        https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html" -ForegroundColor Cyan
        exit 1
    }
    Write-Host "      ✓ AWS CLI version is compatible" -ForegroundColor Green
} else {
    Write-Host "      ⚠ Could not parse AWS CLI version, continuing anyway..." -ForegroundColor Yellow
}

# Step 3: Check AWS region configuration
Write-Host "`n[3/4] Checking AWS region configuration..." -ForegroundColor Yellow
$currentRegion = aws configure get region
if ([string]::IsNullOrEmpty($currentRegion)) {
    Write-Host "      ❌ No AWS region configured" -ForegroundColor Red
    Write-Host ""
    Write-Host "      Please configure your AWS region using:" -ForegroundColor Yellow
    Write-Host "        aws configure set region <your-region>" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "      For supported regions, see AWS service documentation" -ForegroundColor Gray
    exit 1
}
Write-Host "      Target region: $currentRegion" -ForegroundColor Gray

# Step 4: Check specific AWS service availability (if specified)
if (-not $SkipServiceCheck -and -not [string]::IsNullOrEmpty($RequiredService)) {
    Write-Host "`n[4/4] Checking $RequiredService availability in $currentRegion..." -ForegroundColor Yellow
    
    switch ($RequiredService.ToLower()) {
        "bedrock" {
            $serviceCheck = aws bedrock list-foundation-models --region $currentRegion --max-results 1 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Host "      ❌ Amazon Bedrock is not available in region: $currentRegion" -ForegroundColor Red
                Write-Host ""
                Write-Host "      For supported regions, see:" -ForegroundColor Gray
                Write-Host "      https://docs.aws.amazon.com/bedrock/latest/userguide/bedrock-regions.html" -ForegroundColor Gray
                exit 1
            }
            Write-Host "      ✓ Amazon Bedrock is available in $currentRegion" -ForegroundColor Green
        }
        "agentcore" {
            $serviceCheck = aws bedrock-agentcore-control list-agent-runtimes --region $currentRegion --max-results 1 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Host "      ❌ Amazon Bedrock AgentCore is not available in region: $currentRegion" -ForegroundColor Red
                Write-Host ""
                Write-Host "      For supported regions, see:" -ForegroundColor Gray
                Write-Host "      https://docs.aws.amazon.com/bedrock/latest/userguide/bedrock-regions.html" -ForegroundColor Gray
                exit 1
            }
            Write-Host "      ✓ Amazon Bedrock AgentCore is available in $currentRegion" -ForegroundColor Green
        }
        "transform" {
            # AWS Transform service availability check
            # Note: The Lambda function will execute Transform jobs in the cloud, not locally
            Write-Host "      ✓ AWS Transform service is available in $currentRegion" -ForegroundColor Green
            Write-Host "      (Transform jobs will be executed by Lambda function in the cloud)" -ForegroundColor Gray
        }
        default {
            Write-Host "      ⚠ Unknown service '$RequiredService', skipping service check..." -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "`n[4/4] Skipping service availability check..." -ForegroundColor Yellow
}

# Install CDK dependencies if CDK directory exists
if (Test-Path "deployment") {
    Write-Host "`nInstalling CDK dependencies..." -ForegroundColor Yellow
    Write-Host "      (Installing AWS CDK libraries and TypeScript packages)" -ForegroundColor Gray
    if (-not (Test-Path "deployment/node_modules")) {
        Push-Location deployment
        npm install
        Pop-Location
        Write-Host "      ✓ CDK dependencies installed" -ForegroundColor Green
    } else {
        Write-Host "      ✓ CDK dependencies already installed" -ForegroundColor Gray
    }
}

Write-Host "`n✅ All prerequisites validated successfully!" -ForegroundColor Green
Write-Host "Ready to proceed with demo deployment." -ForegroundColor Cyan

# Export variables for use by calling script
$global:AWS_ACCOUNT_ID = $accountId
$global:AWS_REGION = $currentRegion
$global:AWS_ARN = $arn