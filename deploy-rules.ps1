# Firestore Rules Deployment Script for JuCi Faculty Portal
# Author: Development Team
# Project: facconsult-19071
# Database: facconsult-firebase

Write-Host "JuCi Firestore Rules Deployment" -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan
Write-Host ""

# Check if Firebase CLI is installed
Write-Host "[*] Checking Firebase CLI..." -ForegroundColor Yellow
try {
    $firebaseVersion = firebase --version
    Write-Host "   [OK] Firebase CLI installed: $firebaseVersion" -ForegroundColor Green
} catch {
    Write-Host "   [ERROR] Firebase CLI not found!" -ForegroundColor Red
    Write-Host "   Install it with: npm install -g firebase-tools" -ForegroundColor Yellow
    exit 1
}

# Check if firestore.rules exists
if (-Not (Test-Path "firestore.rules")) {
    Write-Host "   [ERROR] firestore.rules not found!" -ForegroundColor Red
    Write-Host "   Please create firestore.rules before deploying." -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "[*] Rule File Summary:" -ForegroundColor Yellow
Write-Host "   Location: firestore.rules"
$ruleContent = Get-Content "firestore.rules" -Raw
$lineCount = ($ruleContent -split "`n").Count
Write-Host "   Lines: $lineCount" -ForegroundColor Gray
Write-Host ""

# Show preview of rules
Write-Host "[*] Preview (first 15 lines):" -ForegroundColor Yellow
Get-Content "firestore.rules" | Select-Object -First 15 | ForEach-Object { Write-Host "   $_" -ForegroundColor Gray }
Write-Host "   ..." -ForegroundColor Gray
Write-Host ""

# Confirm deployment
Write-Host "[!] You are about to deploy to:" -ForegroundColor Yellow
Write-Host "   Project: facconsult-19071" -ForegroundColor White
Write-Host "   Database: facconsult-firebase" -ForegroundColor White
Write-Host ""

$confirmation = Read-Host "Continue with deployment? (y/n)"
if ($confirmation -ne 'y') {
    Write-Host "[X] Deployment cancelled." -ForegroundColor Red
    exit 0
}

# Deploy rules
Write-Host ""
Write-Host "[*] Deploying Firestore rules..." -ForegroundColor Yellow
Write-Host ""

try {
    # Deploy to default (production) database
    firebase deploy --only firestore:rules
    
    Write-Host ""
    Write-Host "[OK] Deployment successful!" -ForegroundColor Green
    Write-Host ""
    Write-Host "View rules in console:" -ForegroundColor Cyan
    Write-Host "   https://console.firebase.google.com/project/facconsult-19071/firestore/rules" -ForegroundColor Blue
    Write-Host ""
    Write-Host "Test rules in playground:" -ForegroundColor Cyan
    Write-Host "   Click 'Rules playground' tab in the console" -ForegroundColor Blue
    Write-Host ""
    
} catch {
    Write-Host ""
    Write-Host "[ERROR] Deployment failed!" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Troubleshooting:" -ForegroundColor Yellow
    Write-Host "   1. Run 'firebase login' if not authenticated" -ForegroundColor White
    Write-Host "   2. Run 'firebase use facconsult-19071' to select project" -ForegroundColor White
    Write-Host "   3. Check firestore.rules syntax" -ForegroundColor White
    exit 1
}

Write-Host "[DONE] Deployment complete!" -ForegroundColor Green
