<#
.SYNOPSIS
    killgow - PowerShell utility script
.NOTES
    Original function: killgow
    Extracted: 2026-02-19 20:20
#>
Write-Host "Killing GoW Ragnarok..." -ForegroundColor Yellow
    cmd /c "taskkill /F /IM GoWR.exe /T" 2>$null
    Stop-Process -Name "GoWR" -Force -ErrorAction SilentlyContinue
    Stop-Process -Name "bridge32" -Force -ErrorAction SilentlyContinue
    Stop-Process -Name "bridge64" -Force -ErrorAction SilentlyContinue
    Stop-Process -Name "crs-handler" -Force -ErrorAction SilentlyContinue
    Stop-Process -Name "crs-uploader" -Force -ErrorAction SilentlyContinue
    Write-Host "Done!" -ForegroundColor Green
