# AI-Powered Legacy System Automation - Setup Script
# Installs Nova Act SDK and creates the workflow definition

param(
    [switch]$SkipPrerequisites = $false
)

$ErrorActionPreference = "Stop"

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "AI-Powered Legacy System Automation Setup" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

# Step 1: Check Python
Write-Host "`n[1/3] Checking Python..." -ForegroundColor Yellow
$pythonVersion = python --version 2>&1
if ($pythonVersion -match "Python (\d+)\.(\d+)") {
    $major = [int]$Matches[1]
    $minor = [int]$Matches[2]
    if ($major -ge 3 -and $minor -ge 10) {
        Write-Host "      ✓ $pythonVersion" -ForegroundColor Green
    } else {
        Write-Host "      ❌ Python 3.10+ required (found $pythonVersion)" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "      ❌ Python not found" -ForegroundColor Red
    exit 1
}

# Step 2: Install Nova Act SDK
Write-Host "`n[2/3] Installing Nova Act SDK..." -ForegroundColor Yellow
pip install nova-act --quiet
if ($LASTEXITCODE -eq 0) {
    Write-Host "      ✓ Nova Act SDK installed" -ForegroundColor Green
} else {
    Write-Host "      ❌ Failed to install Nova Act SDK" -ForegroundColor Red
    exit 1
}

# Step 3: Create workflow definition
Write-Host "`n[3/3] Creating Nova Act workflow definition..." -ForegroundColor Yellow

$workflowName = "legacy-system-automation"

# Check region
$currentRegion = aws configure get region 2>$null
if ($currentRegion -ne "us-east-1") {
    Write-Host "      Setting region to us-east-1 (Nova Act requirement)..." -ForegroundColor Gray
    aws configure set region us-east-1
}

# Check if workflow exists
$definitions = aws nova-act list-workflow-definitions --region us-east-1 2>$null | ConvertFrom-Json
$exists = $definitions.workflowDefinitions | Where-Object { $_.name -eq $workflowName }

if ($exists) {
    Write-Host "      ✓ Workflow '$workflowName' already exists" -ForegroundColor Green
} else {
    aws nova-act create-workflow-definition --name $workflowName --region us-east-1 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "      ✓ Workflow '$workflowName' created" -ForegroundColor Green
    } else {
        Write-Host "      ⚠ Could not create workflow (check AWS credentials)" -ForegroundColor Yellow
    }
}

# Done
Write-Host "`n=============================================" -ForegroundColor Cyan
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Run the phpMyAdmin demo:" -ForegroundColor Yellow
Write-Host "  python -m scenarios.phpmyadmin_create_database --cleanup" -ForegroundColor Cyan
Write-Host ""
