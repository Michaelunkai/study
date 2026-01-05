# ============================================================================
# TOVPLAY DEVELOPMENT LAUNCHER - Complete Suite
# ============================================================================
# Launches backend (Flask) and frontend (Vite) with proper npm config
#
# USAGE:
#   PS> .\tovrun.ps1
#   PS> tovrun  (if added to PowerShell profile as alias/function)
#   PS> tovrun -Backend   (launch only backend)
#   PS> tovrun -Frontend  (launch only frontend)
#
# SETUP IN PROFILE:
#   Add this to your PowerShell profile ($PROFILE):
#
#   function tovrun {
#     cd F:\tovplay; & .\tovrun.ps1 @args
#   }
#
# Features:
# - Activates backend virtual environment
# - Installs dependencies with --include=dev flag
# - Launches Flask on port 5001
# - Launches Vite dev server on port 3000
# - Both run in separate PowerShell windows with visible output
# - Automatic error handling and recovery
# ============================================================================

param(
    [switch]$Backend,
    [switch]$Frontend,
    [switch]$Both
)

$ErrorActionPreference = "Stop"

# Colors for output
$Colors = @{
    Info    = "Cyan"
    Success = "Green"
    Warning = "Yellow"
    Error   = "Red"
}

function Write-Log {
    param([string]$Message, [string]$Level = "Info")
    $Color = $Colors[$Level]
    Write-Host "[$Level] $Message" -ForegroundColor $Color
}

# Navigate to project root
$ProjectRoot = "F:\tovplay"
if (-not (Test-Path $ProjectRoot)) {
    Write-Log "Project root not found: $ProjectRoot" -Level Error
    exit 1
}

Write-Log "Starting TovPlay development environment..."
Write-Log "Project root: $ProjectRoot" -Level Success

# Determine what to launch
$LaunchBackend = $Backend -or $Both -or (-not $Frontend -and -not $Backend -and -not $Both)
$LaunchFrontend = $Frontend -or $Both -or (-not $Backend -and -not $Frontend -and -not $Both)

# ============================================================================
# BACKEND LAUNCHER
# ============================================================================
if ($LaunchBackend) {
    Write-Log "Starting Backend (Flask on port 5001)..." -Level Info

    $BackendScript = @"
    `$ErrorActionPreference = "Stop"
    Set-Location "$ProjectRoot\tovplay-backend"
    Write-Host "[Backend] Directory: `$(Get-Location)" -ForegroundColor Cyan

    # Check if venv exists
    if (-not (Test-Path "venv")) {
        Write-Host "[Backend] Creating virtual environment..." -ForegroundColor Yellow
        python -m venv venv
    }

    # Activate venv
    Write-Host "[Backend] Activating virtual environment..." -ForegroundColor Cyan
    & ".\venv\Scripts\Activate.ps1"

    # Upgrade pip
    Write-Host "[Backend] Upgrading pip..." -ForegroundColor Cyan
    python -m pip install --upgrade pip --quiet

    # Install requirements
    Write-Host "[Backend] Installing requirements..." -ForegroundColor Cyan
    pip install -r requirements.txt --quiet

    # Start Flask
    Write-Host "[Backend] Starting Flask on port 5001..." -ForegroundColor Green
    python -m flask run --host=0.0.0.0 --port=5001 --debug
"@

    Start-Process powershell -ArgumentList @(
        "-NoExit",
        "-Command",
        $BackendScript
    ) -WindowStyle Normal

    Write-Log "Backend window launched" -Level Success
    Start-Sleep -Seconds 2
}

# ============================================================================
# FRONTEND LAUNCHER
# ============================================================================
if ($LaunchFrontend) {
    Write-Log "Starting Frontend (Vite on port 3000)..." -Level Info

    $FrontendScript = @"
    `$ErrorActionPreference = "Stop"
    Set-Location "$ProjectRoot\tovplay-frontend"
    Write-Host "[Frontend] Directory: `$(Get-Location)" -ForegroundColor Cyan

    # Check if node_modules exists
    if (-not (Test-Path "node_modules")) {
        Write-Host "[Frontend] Installing npm packages (first time)..." -ForegroundColor Yellow
        npm install --legacy-peer-deps --ignore-scripts --include=dev
    } else {
        Write-Host "[Frontend] npm packages already installed" -ForegroundColor Green
    }

    # Start Vite dev server
    Write-Host "[Frontend] Starting Vite dev server on port 3000..." -ForegroundColor Green
    npm run dev
"@

    Start-Process powershell -ArgumentList @(
        "-NoExit",
        "-Command",
        $FrontendScript
    ) -WindowStyle Normal

    Write-Log "Frontend window launched" -Level Success
}

Write-Log "Both services should be starting now..." -Level Success
Write-Log "Backend: http://localhost:5001" -Level Success
Write-Log "Frontend: http://localhost:3000" -Level Success
Write-Log "Press Ctrl+C in each window to stop" -Level Info

# Keep parent window open for a few seconds
Start-Sleep -Seconds 3
Write-Log "You can close this window now" -Level Info
