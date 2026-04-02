# =============================================================================
# setup_and_run.ps1 — One-click setup for Flask DevOps Pipeline on Windows
# Run this from PowerShell (as Administrator recommended):
#   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
#   .\setup_and_run.ps1
# =============================================================================

$ErrorActionPreference = "Stop"
$ProjectRoot = $PSScriptRoot

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Flask DevOps Pipeline — Windows Setup " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ── Step 1: Check / Install Python ────────────────────────────────────────────
Write-Host "[1/5] Checking Python installation..." -ForegroundColor Yellow

$pythonCmd = $null
foreach ($cmd in @("python", "python3", "py")) {
    try {
        $ver = & $cmd --version 2>&1
        if ($ver -match "Python 3") {
            $pythonCmd = $cmd
            Write-Host "      Found: $ver (command: $cmd)" -ForegroundColor Green
            break
        }
    } catch { }
}

if (-not $pythonCmd) {
    Write-Host "      Python not found. Installing via winget..." -ForegroundColor Yellow

    # Try winget (built into Windows 10 21H2+ and Windows 11)
    try {
        winget install --id Python.Python.3.11 --source winget --accept-package-agreements --accept-source-agreements
        Write-Host "      Python installed via winget." -ForegroundColor Green

        # Refresh PATH so python is available in this session
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        $pythonCmd = "python"
    }
    catch {
        Write-Host ""
        Write-Host "  ❌ winget failed. Please install Python manually:" -ForegroundColor Red
        Write-Host "     1. Open: https://www.python.org/downloads/" -ForegroundColor White
        Write-Host "     2. Download Python 3.11 (Windows installer 64-bit)" -ForegroundColor White
        Write-Host "     3. ✅ CHECK 'Add Python to PATH' during install" -ForegroundColor White
        Write-Host "     4. Re-run this script after install" -ForegroundColor White
        Write-Host ""
        Read-Host "Press Enter to open the Python download page in your browser"
        Start-Process "https://www.python.org/downloads/"
        exit 1
    }
}

# ── Step 2: Create Virtual Environment ────────────────────────────────────────
Write-Host ""
Write-Host "[2/5] Creating Python virtual environment (.venv)..." -ForegroundColor Yellow

$venvPath = Join-Path $ProjectRoot ".venv"
if (Test-Path $venvPath) {
    Write-Host "      Existing .venv found — reusing." -ForegroundColor Green
} else {
    & $pythonCmd -m venv $venvPath
    Write-Host "      Virtual environment created at .venv\" -ForegroundColor Green
}

# ── Step 3: Activate venv and install dependencies ───────────────────────────
Write-Host ""
Write-Host "[3/5] Installing dependencies from requirements.txt..." -ForegroundColor Yellow

$pip     = Join-Path $venvPath "Scripts\pip.exe"
$python  = Join-Path $venvPath "Scripts\python.exe"

& $pip install --upgrade pip --quiet
& $pip install -r (Join-Path $ProjectRoot "requirements.txt")

Write-Host "      All dependencies installed." -ForegroundColor Green

# ── Step 4: Run Tests ─────────────────────────────────────────────────────────
Write-Host ""
Write-Host "[4/5] Running pytest (all 12 tests)..." -ForegroundColor Yellow

Set-Location $ProjectRoot
& $python -m pytest tests/ -v --no-header --tb=short
if ($LASTEXITCODE -ne 0) {
    Write-Host "  ⚠️  Some tests failed. Check output above." -ForegroundColor Red
} else {
    Write-Host "      All tests passed!" -ForegroundColor Green
}

# ── Step 5: Start Flask App ───────────────────────────────────────────────────
Write-Host ""
Write-Host "[5/5] Starting Flask app on http://localhost:5000 ..." -ForegroundColor Yellow
Write-Host ""
Write-Host "  Endpoints:" -ForegroundColor Cyan
Write-Host "    http://localhost:5000/         — Home" -ForegroundColor White
Write-Host "    http://localhost:5000/health   — Health check" -ForegroundColor White
Write-Host "    http://localhost:5000/info     — Version + hostname" -ForegroundColor White
Write-Host "    http://localhost:5000/metrics  — Prometheus metrics" -ForegroundColor White
Write-Host ""
Write-Host "  Press Ctrl+C to stop the server." -ForegroundColor Gray
Write-Host "========================================"  -ForegroundColor Cyan
Write-Host ""

$env:FLASK_APP = "app.py"
$env:APP_ENV   = "development"
& $python app.py
