# Add Node.js to PATH
$env:PATH = "C:\Program Files\nodejs;$env:PATH"

Write-Host "=== TovPlay Development Server ===" -ForegroundColor Cyan
Write-Host "Starting Backend (Flask)..." -ForegroundColor Green
Write-Host "Starting Frontend (Vite)..." -ForegroundColor Green
Write-Host ""

# Start Backend
$backendScript = {
    cd "F:\tovplay\tovplay-backend"
    . .\venv\Scripts\Activate.ps1
    Write-Host "Backend: Python venv activated" -ForegroundColor Yellow
    Write-Host "Backend: Starting Flask on port 5001..." -ForegroundColor Yellow
    flask run --host=0.0.0.0 --port=5001
}

# Start Frontend
$frontendScript = {
    $env:PATH = "C:\Program Files\nodejs;$env:PATH"
    cd "F:\tovplay\tovplay-frontend"
    Write-Host "Frontend: Starting Vite dev server on port 3000..." -ForegroundColor Yellow
    npm run dev
}

# Launch both in background
Start-Job -ScriptBlock $backendScript -Name "Backend"
Start-Sleep -Seconds 2
Start-Job -ScriptBlock $frontendScript -Name "Frontend"

Write-Host ""
Write-Host "Both services started!" -ForegroundColor Green
Write-Host "Backend:  http://localhost:5001" -ForegroundColor Cyan
Write-Host "Frontend: http://localhost:3000" -ForegroundColor Cyan
Write-Host ""
Write-Host "Press Ctrl+C to stop" -ForegroundColor Yellow

# Keep script running
Get-Job | Wait-Job
