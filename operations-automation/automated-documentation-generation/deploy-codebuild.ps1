#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Deploy AWS Transform Documentation Generator using CodeBuild

.DESCRIPTION
    This script deploys a CodeBuild-based solution that runs AWS Transform to generate
    comprehensive documentation from any Git repository. Simple and cost-effective.

.PARAMETER RepositoryUrl
    Git repository URL to analyze (default: AWS Device Farm sample)

.PARAMETER OutputBucket
    S3 bucket name for storing generated documentation (optional - will be created)

.PARAMETER Region
    AWS region for deployment (default: us-east-1)

.EXAMPLE
    .\deploy-codebuild.ps1
    .\deploy-codebuild.ps1 -RepositoryUrl "https://github.com/owner/repo"
    .\deploy-codebuild.ps1 -Region "us-west-2"
#>

param(
    [string]$RepositoryUrl = "",
    [string]$OutputBucket = "",
    [string]$Region = "us-east-1"
)

$defaultRepo = "https://github.com/aws-samples/aws-device-farm-sample-web-app-using-appium-python"

Write-Host "=== AWS Transform Documentation Generator (CodeBuild Version) ===" -ForegroundColor Cyan
Write-Host "Generates comprehensive documentation from any Git repository" -ForegroundColor Green
Write-Host ""

# Check if repository URL was provided
if ([string]::IsNullOrEmpty($RepositoryUrl)) {
    Write-Host "No repository URL specified. Using default sample repository." -ForegroundColor Yellow
    Write-Host "To analyze your own repository, run:" -ForegroundColor Gray
    Write-Host "  .\deploy-codebuild.ps1 -RepositoryUrl `"https://github.com/owner/repo`"" -ForegroundColor White
    Write-Host ""
    $RepositoryUrl = $defaultRepo
}

# Run prerequisites check
Write-Host "Running prerequisites check..." -ForegroundColor Yellow
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
& "$scriptDir\..\..\shared\scripts\check-prerequisites.ps1" -RequiredService "transform"

if ($LASTEXITCODE -ne 0) {
    Write-Host "Prerequisites check failed" -ForegroundColor Red
    exit 1
}

# Get account ID
$accountId = aws sts get-caller-identity --query Account --output text
if ([string]::IsNullOrEmpty($accountId)) {
    Write-Host "Failed to get AWS account ID" -ForegroundColor Red
    exit 1
}

# Set default output bucket if not provided
if ([string]::IsNullOrEmpty($OutputBucket)) {
    $OutputBucket = "doc-gen-output-$accountId-$Region"
}

Write-Host ""
Write-Host "[1/5] Creating S3 bucket for documentation output..." -ForegroundColor Yellow
Write-Host "      Bucket: $OutputBucket" -ForegroundColor Gray

# Create S3 bucket if it doesn't exist
$bucketExists = aws s3api head-bucket --bucket $OutputBucket --region $Region 2>$null
if ($LASTEXITCODE -ne 0) {
    if ($Region -eq "us-east-1") {
        aws s3api create-bucket --bucket $OutputBucket --region $Region | Out-Null
    } else {
        aws s3api create-bucket --bucket $OutputBucket --region $Region --create-bucket-configuration LocationConstraint=$Region | Out-Null
    }
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "      S3 bucket created successfully" -ForegroundColor Green
    } else {
        Write-Host "      Failed to create S3 bucket" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "      S3 bucket already exists" -ForegroundColor Green
}

Write-Host "[2/5] Uploading buildspec to S3..." -ForegroundColor Yellow
$buildspecPath = Join-Path $scriptDir "buildspec.yml"
aws s3 cp $buildspecPath "s3://$OutputBucket/config/buildspec.yml" --region $Region | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Host "      Buildspec uploaded successfully" -ForegroundColor Green
} else {
    Write-Host "      Failed to upload buildspec" -ForegroundColor Red
    exit 1
}

Write-Host "[3/5] Creating IAM role for CodeBuild..." -ForegroundColor Yellow

$roleName = "CodeBuildDocGenRole"
$roleArn = aws iam get-role --role-name $roleName --query 'Role.Arn' --output text 2>$null

if ($LASTEXITCODE -ne 0) {
    Write-Host "      Creating new IAM role..." -ForegroundColor Gray
    
    # Create trust policy
    $trustPolicy = @{
        Version = "2012-10-17"
        Statement = @(
            @{
                Effect = "Allow"
                Principal = @{
                    Service = "codebuild.amazonaws.com"
                }
                Action = "sts:AssumeRole"
            }
        )
    } | ConvertTo-Json -Depth 10 -Compress
    
    aws iam create-role --role-name $roleName --assume-role-policy-document $trustPolicy | Out-Null
    
    # Attach managed policies
    Write-Host "      Attaching CloudWatch Logs policy..." -ForegroundColor Gray
    aws iam attach-role-policy --role-name $roleName --policy-arn "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
    
    Write-Host "      Attaching S3 policy..." -ForegroundColor Gray
    aws iam attach-role-policy --role-name $roleName --policy-arn "arn:aws:iam::aws:policy/AmazonS3FullAccess"
    
    # Create and attach Transform custom policy
    Write-Host "      Creating Transform custom policy..." -ForegroundColor Gray
    $transformPolicy = @{
        Version = "2012-10-17"
        Statement = @(
            @{
                Effect = "Allow"
                Action = "transform-custom:*"
                Resource = "*"
            }
        )
    } | ConvertTo-Json -Depth 10 -Compress
    
    aws iam put-role-policy --role-name $roleName --policy-name "TransformCustomPolicy" --policy-document $transformPolicy
    
    # Wait for role to propagate
    Write-Host "      Waiting for IAM role to propagate..." -ForegroundColor Gray
    Start-Sleep -Seconds 10
    
    $roleArn = aws iam get-role --role-name $roleName --query 'Role.Arn' --output text
    Write-Host "      IAM role created successfully" -ForegroundColor Green
} else {
    Write-Host "      IAM role already exists" -ForegroundColor Green
    
    # Ensure Transform policy exists
    $policyExists = aws iam get-role-policy --role-name $roleName --policy-name "TransformCustomPolicy" 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "      Adding Transform custom policy..." -ForegroundColor Gray
        $transformPolicy = @{
            Version = "2012-10-17"
            Statement = @(
                @{
                    Effect = "Allow"
                    Action = "transform-custom:*"
                    Resource = "*"
                }
            )
        } | ConvertTo-Json -Depth 10 -Compress
        aws iam put-role-policy --role-name $roleName --policy-name "TransformCustomPolicy" --policy-document $transformPolicy
    }
}

Write-Host "[4/5] Creating CodeBuild project..." -ForegroundColor Yellow

$projectName = "aws-transform-doc-generator"

# Check if project exists
$projectExists = aws codebuild batch-get-projects --names $projectName --region $Region --query 'projects[0].name' --output text 2>$null

if ($projectExists -ne $projectName) {
    Write-Host "      Creating new CodeBuild project..." -ForegroundColor Gray
    
    # Create project with S3 source
    aws codebuild create-project `
        --name $projectName `
        --description "AWS Transform Documentation Generator - generates comprehensive docs from any Git repo" `
        --service-role $roleArn `
        --region $Region `
        --artifacts "type=NO_ARTIFACTS" `
        --environment "type=LINUX_CONTAINER,image=aws/codebuild/amazonlinux2-x86_64-standard:5.0,computeType=BUILD_GENERAL1_MEDIUM,environmentVariables=[{name=REPOSITORY_URL,value=$RepositoryUrl,type=PLAINTEXT},{name=OUTPUT_BUCKET,value=$OutputBucket,type=PLAINTEXT},{name=JOB_ID,value=doc-gen-default,type=PLAINTEXT}]" `
        --source "type=S3,location=$OutputBucket/config/buildspec.yml" `
        --timeout-in-minutes 60 | Out-Null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "      CodeBuild project created successfully" -ForegroundColor Green
    } else {
        Write-Host "      Failed to create CodeBuild project" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "      CodeBuild project already exists" -ForegroundColor Green
}

Write-Host "[5/5] Starting test build..." -ForegroundColor Yellow
Write-Host "      Repository: $RepositoryUrl" -ForegroundColor Gray

# Generate unique job ID
$jobId = "doc-gen-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

# Start build with environment variable overrides
$buildResult = aws codebuild start-build `
    --project-name $projectName `
    --region $Region `
    --environment-variables-override "name=REPOSITORY_URL,value=$RepositoryUrl,type=PLAINTEXT" "name=OUTPUT_BUCKET,value=$OutputBucket,type=PLAINTEXT" "name=JOB_ID,value=$jobId,type=PLAINTEXT" `
    --query 'build.id' --output text

if ($LASTEXITCODE -eq 0) {
    Write-Host "      Build started: $buildResult" -ForegroundColor Green
} else {
    Write-Host "      Failed to start build" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=== Deployment Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Resources created:" -ForegroundColor Yellow
Write-Host "  - S3 Bucket: $OutputBucket" -ForegroundColor White
Write-Host "  - IAM Role: $roleName" -ForegroundColor White
Write-Host "  - CodeBuild Project: $projectName" -ForegroundColor White
Write-Host ""
Write-Host "Monitor build progress:" -ForegroundColor Yellow
Write-Host "  aws codebuild batch-get-builds --ids $buildResult --region $Region" -ForegroundColor Gray
Write-Host ""
Write-Host "Stream build logs:" -ForegroundColor Yellow
Write-Host "  aws logs tail /aws/codebuild/$projectName --follow --region $Region" -ForegroundColor Gray
Write-Host ""
Write-Host "Check generated documentation:" -ForegroundColor Yellow
Write-Host "  aws s3 ls s3://$OutputBucket/documentation/$jobId/ --recursive" -ForegroundColor Gray
Write-Host ""
Write-Host "Generate docs for another repository:" -ForegroundColor Yellow
Write-Host "  aws codebuild start-build --project-name $projectName --region $Region ``" -ForegroundColor Gray
Write-Host "    --environment-variables-override name=REPOSITORY_URL,value=https://github.com/owner/repo" -ForegroundColor Gray
