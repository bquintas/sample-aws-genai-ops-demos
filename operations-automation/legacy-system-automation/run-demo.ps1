# AI-Powered Legacy System Automation - Demo Runner
# One-click setup and demo execution

param(
    [switch]$SkipSetup = $false,
    [switch]$Cleanup = $false,
    [switch]$Headless = $false,
    [string]$DbName = ""
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  AI-Powered Legacy System Automation with Nova Act" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# ============================================================
# STEP 1: Setup (unless skipped)
# ============================================================
if (-not $SkipSetup) {
    Write-Host "[SETUP] Checking prerequisites..." -ForegroundColor Yellow
    Write-Host ""
    
    # Check Python
    Write-Host "  Checking Python..." -ForegroundColor Gray
    $pythonVersion = python --version 2>&1
    if ($pythonVersion -match "Python (\d+)\.(\d+)") {
        $major = [int]$Matches[1]
        $minor = [int]$Matches[2]
        if ($major -ge 3 -and $minor -ge 10) {
            Write-Host "  ✓ $pythonVersion" -ForegroundColor Green
        } else {
            Write-Host "  ❌ Python 3.10+ required (found $pythonVersion)" -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "  ❌ Python not found. Install from https://python.org" -ForegroundColor Red
        exit 1
    }
    
    # Check AWS credentials
    Write-Host "  Checking AWS credentials..." -ForegroundColor Gray
    $awsCheck = aws sts get-caller-identity 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  ❌ AWS credentials not configured. Run: aws configure" -ForegroundColor Red
        exit 1
    }
    Write-Host "  ✓ AWS credentials configured" -ForegroundColor Green
    
    # Check/set region
    Write-Host "  Checking AWS region..." -ForegroundColor Gray
    $currentRegion = aws configure get region 2>$null
    if ($currentRegion -ne "us-east-1") {
        Write-Host "  Setting region to us-east-1 (Nova Act requirement)..." -ForegroundColor Gray
        aws configure set region us-east-1
    }
    Write-Host "  ✓ Region: us-east-1" -ForegroundColor Green
    
    # Install Nova Act SDK
    Write-Host "  Installing Nova Act SDK..." -ForegroundColor Gray
    pip install nova-act --quiet 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ Nova Act SDK installed" -ForegroundColor Green
    } else {
        Write-Host "  ❌ Failed to install Nova Act SDK" -ForegroundColor Red
        exit 1
    }
    
    # Create workflow definition
    Write-Host "  Creating workflow definition..." -ForegroundColor Gray
    $workflowName = "legacy-system-automation"
    $definitions = aws nova-act list-workflow-definitions --region us-east-1 2>$null | ConvertFrom-Json
    $exists = $definitions.workflowDefinitions | Where-Object { $_.name -eq $workflowName }
    
    if ($exists) {
        Write-Host "  ✓ Workflow '$workflowName' exists" -ForegroundColor Green
    } else {
        aws nova-act create-workflow-definition --name $workflowName --region us-east-1 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✓ Workflow '$workflowName' created" -ForegroundColor Green
        } else {
            Write-Host "  ⚠ Could not create workflow (may already exist)" -ForegroundColor Yellow
        }
    }
    
    Write-Host ""
    Write-Host "[SETUP] Complete!" -ForegroundColor Green
    Write-Host ""
}

# ============================================================
# STEP 2: Run Demo
# ============================================================
Write-Host "------------------------------------------------------------" -ForegroundColor Gray
Write-Host "[DEMO] Creating database in phpMyAdmin..." -ForegroundColor Yellow
Write-Host "------------------------------------------------------------" -ForegroundColor Gray
Write-Host ""

# Build command arguments
$demoArgs = @()
if ($Cleanup) { $demoArgs += "--cleanup" }
if ($Headless) { $demoArgs += "--headless" }
if ($DbName) { $demoArgs += "--db-name"; $demoArgs += $DbName }

Push-Location $ScriptDir
try {
    if ($demoArgs.Count -gt 0) {
        python create_database.py @demoArgs
    } else {
        python create_database.py
    }
} finally {
    Pop-Location
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Demo Complete!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
