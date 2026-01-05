# TovPlay Development Environment Launcher
# This script starts both Backend (Flask) and Frontend (Vite) in separate PowerShell windows

Write-Host "╔════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║         TovPlay Development Environment Launcher        ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Add Node.js to PATH
$env:PATH = "C:\Program Files\nodejs;$env:PATH"

Write-Host "Starting Backend (Flask on port 5001)..." -ForegroundColor Green
$backendCommand = @"
`$env:PATH = 'C:\Program Files\nodejs;' + `$env:PATH
cd 'F:\tovplay\tovplay-backend'
. .\venv\Scripts\Activate.ps1
Write-Host 'Backend: Python venv activated' -ForegroundColor Yellow
Write-Host 'Backend: Python version:' (python --version)
Write-Host 'Backend: Starting Flask...' -ForegroundColor Yellow
flask run --host=0.0.0.0 --port=5001
"@

Start-Process powershell -ArgumentList "-NoExit", "-Command", $backendCommand -WindowStyle Normal

Start-Sleep -Seconds 2

Write-Host "Starting Frontend (Vite on port 3000)..." -ForegroundColor Green
$frontendCommand = @"
`$env:PATH = 'C:\Program Files\nodejs;' + `$env:PATH
cd 'F:\tovplay\tovplay-frontend'
Write-Host 'Frontend: Starting Vite dev server...' -ForegroundColor Yellow
npm run dev
"@

Start-Process powershell -ArgumentList "-NoExit", "-Command", $frontendCommand -WindowStyle Normal

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║                  SERVICES STARTED                       ║" -ForegroundColor Green
Write-Host "╠════════════════════════════════════════════════════════╣" -ForegroundColor Green
Write-Host "║  Backend:  http://localhost:5001                       ║" -ForegroundColor Cyan
Write-Host "║  Frontend: http://localhost:3000                       ║" -ForegroundColor Cyan
Write-Host "║                                                        ║" -ForegroundColor Green
Write-Host "║  Both services should open in separate windows         ║" -ForegroundColor Yellow
Write-Host "║  Press Ctrl+C in each window to stop the service       ║" -ForegroundColor Yellow
Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Green
