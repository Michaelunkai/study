# clawt - OpenClaw tray status
$proc = Get-Process -Name "wscript" -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowTitle -match "Clawdbot|openclaw" }
if ($proc) { Write-Host "OpenClaw tray is running (PID: $($proc.Id))" -ForegroundColor Green }
else {
    $wscripts = Get-Process -Name "wscript" -ErrorAction SilentlyContinue
    if ($wscripts) { Write-Host "wscript running ($($wscripts.Count) instances) - may include OpenClaw" -ForegroundColor Yellow }
    else { Write-Host "OpenClaw tray not running" -ForegroundColor Red }
}