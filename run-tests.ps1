# Test Runner Script for JuCi Faculty Portal
# Runs all tests with coverage and generates report

Write-Host "======================================" -ForegroundColor Cyan
Write-Host " JuCi Faculty Portal - Test Runner" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Check if Flutter is installed
$flutterInstalled = Get-Command flutter -ErrorAction SilentlyContinue
if (-not $flutterInstalled) {
    Write-Host "[ERROR] Flutter is not installed or not in PATH" -ForegroundColor Red
    exit 1
}

Write-Host "[*] Flutter version:" -ForegroundColor Yellow
flutter --version
Write-Host ""

# Get dependencies
Write-Host "[*] Getting dependencies..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Failed to get dependencies" -ForegroundColor Red
    exit 1
}
Write-Host "   [OK] Dependencies installed" -ForegroundColor Green
Write-Host ""

# Run unit and widget tests with coverage
Write-Host "[*] Running unit and widget tests..." -ForegroundColor Yellow
Write-Host ""
flutter test --coverage
$unitTestResult = $LASTEXITCODE

if ($unitTestResult -eq 0) {
    Write-Host ""
    Write-Host "   [OK] All unit and widget tests passed!" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "   [ERROR] Some unit/widget tests failed!" -ForegroundColor Red
}

Write-Host ""
Write-Host "[*] Test Results Summary:" -ForegroundColor Cyan
Write-Host "   Unit/Widget Tests: " -NoNewline
if ($unitTestResult -eq 0) {
    Write-Host "PASSED" -ForegroundColor Green
} else {
    Write-Host "FAILED" -ForegroundColor Red
}

# Check if coverage directory exists
if (Test-Path "coverage/lcov.info") {
    Write-Host ""
    Write-Host "[*] Coverage report generated at: coverage/lcov.info" -ForegroundColor Yellow
    
    # Try to calculate coverage percentage (basic parsing)
    $coverageContent = Get-Content "coverage/lcov.info" -Raw
    $linesFound = ($coverageContent | Select-String -Pattern "LF:" -AllMatches).Matches.Count
    $linesHit = ($coverageContent | Select-String -Pattern "LH:" -AllMatches).Matches.Count
    
    if ($linesFound -gt 0) {
        Write-Host "   Coverage data available - use genhtml to view detailed report" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "   To view coverage in browser:" -ForegroundColor Yellow
        Write-Host "   1. Install lcov: choco install lcov" -ForegroundColor White
        Write-Host "   2. Generate HTML: genhtml coverage/lcov.info -o coverage/html" -ForegroundColor White
        Write-Host "   3. Open: start coverage/html/index.html" -ForegroundColor White
    }
}

Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan

# Exit with appropriate code
if ($unitTestResult -eq 0) {
    Write-Host " ALL TESTS PASSED!" -ForegroundColor Green
    Write-Host "======================================" -ForegroundColor Cyan
    exit 0
} else {
    Write-Host " SOME TESTS FAILED!" -ForegroundColor Red
    Write-Host "======================================" -ForegroundColor Cyan
    exit 1
}
