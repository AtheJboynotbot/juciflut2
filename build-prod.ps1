# Production Build Script for JuCi Faculty Portal
# This script builds the app for production deployment

Write-Host "======================================" -ForegroundColor Cyan
Write-Host " JuCi Production Build" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Confirm production build
Write-Host "[!] WARNING: Building for PRODUCTION" -ForegroundColor Red
Write-Host ""
$confirmation = Read-Host "Continue with production build? (y/n)"
if ($confirmation -ne 'y') {
    Write-Host "[X] Build cancelled." -ForegroundColor Red
    exit 0
}

Write-Host ""
Write-Host "[*] Backing up current .env file..." -ForegroundColor Yellow
if (Test-Path ".env") {
    Copy-Item .env .env.backup -Force
    Write-Host "   [OK] Backup created: .env.backup" -ForegroundColor Green
}

Write-Host ""
Write-Host "[*] Copying production environment..." -ForegroundColor Yellow
if (-Not (Test-Path ".env.prod")) {
    Write-Host "   [ERROR] .env.prod not found!" -ForegroundColor Red
    if (Test-Path ".env.backup") {
        Copy-Item .env.backup .env -Force
        Remove-Item .env.backup
    }
    exit 1
}

Copy-Item .env.prod .env -Force
Write-Host "   [OK] Using .env.prod configuration" -ForegroundColor Green

Write-Host ""
Write-Host "[*] Running pub get..." -ForegroundColor Yellow
flutter pub get

Write-Host ""
Write-Host "[*] Building for web (production)..." -ForegroundColor Yellow
Write-Host ""

try {
    flutter build web --release
    
    Write-Host ""
    Write-Host "[OK] Build successful!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Build output: build/web/" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "   1. Test build locally: cd build/web && python -m http.server 8000" -ForegroundColor White
    Write-Host "   2. Deploy to Firebase Hosting: firebase deploy --only hosting" -ForegroundColor White
    Write-Host "   3. Or deploy to your web server" -ForegroundColor White
    Write-Host ""
    
} catch {
    Write-Host ""
    Write-Host "[ERROR] Build failed!" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
} finally {
    # Restore original .env
    Write-Host "[*] Restoring original .env..." -ForegroundColor Yellow
    if (Test-Path ".env.backup") {
        Copy-Item .env.backup .env -Force
        Remove-Item .env.backup
        Write-Host "   [OK] Original .env restored" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "[DONE] Production build complete!" -ForegroundColor Green
