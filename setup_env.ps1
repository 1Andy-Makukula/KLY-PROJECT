# =============================================================================
# KithLy Global Protocol - Environment Setup Script
# =============================================================================
# Usage: .\setup_env.ps1
# This script sets up the development environment for KithLy.

Write-Host "🌍 KithLy Global Protocol - Setup Wizard" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# 1. Check Python
# -----------------------------------------------------------------------------
Write-Host "`n[1/4] Checking Python Environment..." -ForegroundColor Yellow
$pythonUi = (Get-Command python -ErrorAction SilentlyContinue)
if ($pythonUi) {
    $ver = python --version
    Write-Host "✅ Python found: $ver" -ForegroundColor Green
    
    # Setup Virtual Environment (Gateway)
    if (-not (Test-Path "03_gateway\venv")) {
        Write-Host "   Creating virtual environment (03_gateway\venv)..."
        python -m venv 03_gateway\venv
    }
    
    # Install Dependencies
    Write-Host "   Installing Python dependencies..."
    .\03_gateway\venv\Scripts\python.exe -m pip install --upgrade pip
    if (Test-Path "03_gateway\requirements.txt") {
        .\03_gateway\venv\Scripts\python.exe -m pip install -r 03_gateway\requirements.txt
    } else {
        Write-Host "   ⚠️ requirements.txt not found in 03_gateway!" -ForegroundColor Red
    }
} else {
    Write-Host "❌ Python is not installed! Please install Python 3.9+ from python.org" -ForegroundColor Red
}

# 2. Check Flutter
# -----------------------------------------------------------------------------
Write-Host "`n[2/4] Checking Flutter Environment..." -ForegroundColor Yellow
$flutterUi = (Get-Command flutter -ErrorAction SilentlyContinue)
if ($flutterUi) {
    $fver = flutter --version
    Write-Host "✅ Flutter found" -ForegroundColor Green
    
    # Run Pub Get
    Write-Host "   Running 'flutter pub get'..."
    Push-Location "04_skin"
    flutter pub get
    Pop-Location
} else {
    Write-Host "❌ Flutter not found in PATH!" -ForegroundColor Red
    Write-Host "   Please install Flutter SDK:"
    Write-Host "   1. Download from: https://docs.flutter.dev/get-started/install/windows"
    Write-Host "   2. Extract to C:\src\flutter"
    Write-Host "   3. Add C:\src\flutter\bin to your User PATH environment variable"
}

# 3. Check C++ (Engine)
# -----------------------------------------------------------------------------
Write-Host "`n[3/4] Checking C++ Compiler..." -ForegroundColor Yellow
$gpp = (Get-Command g++ -ErrorAction SilentlyContinue)
$cl = (Get-Command cl -ErrorAction SilentlyContinue)

if ($gpp) {
    Write-Host "✅ G++ found" -ForegroundColor Green
    # TODO: Compile orchestrator if needed
} elseif ($cl) {
    Write-Host "✅ MSVC (cl.exe) found" -ForegroundColor Green
} else {
    Write-Host "⚠️ No C++ compiler found (g++ or cl). Engine compilation might fail." -ForegroundColor Yellow
    Write-Host "   Install MinGW or Visual Studio C++ workload."
}

# 4. Check Database (PostgreSQL)
# -----------------------------------------------------------------------------
Write-Host "`n[4/4] Checking PostgreSQL..." -ForegroundColor Yellow
$psql = (Get-Command psql -ErrorAction SilentlyContinue)
if ($psql) {
    Write-Host "✅ PostgreSQL client found" -ForegroundColor Green
    # Check connection
    # psql -c "SELECT 1" ...
} else {
    Write-Host "⚠️ psql not found. Assuming database is managed externally or Dockerized." -ForegroundColor Yellow
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Setup Check Complete!" -ForegroundColor Cyan
Write-Host "To start the Backend:"
Write-Host "  cd 03_gateway"
Write-Host "  .\venv\Scripts\activate"
Write-Host "  uvicorn main:app --reload"
Write-Host "`nTo start the Frontend:"
Write-Host "  cd 04_skin"
Write-Host "  flutter run"
