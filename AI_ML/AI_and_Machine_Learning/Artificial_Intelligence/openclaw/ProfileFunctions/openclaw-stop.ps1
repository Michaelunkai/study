# openclaw-stop - Stop all OpenClaw/ClawdBot processes
$killed = 0
$processes = @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object {
    ($_.Name -eq 'wscript.exe' -and $_.CommandLine -match 'ClawdbotTray') -or
    ($_.Name -eq 'node.exe' -and $_.CommandLine -match 'openclaw|clawdbot') -or
    $_.Name -eq 'ClawdBotManager.exe'
})

foreach ($process in $processes) {
    Stop-Process -Id $process.ProcessId -Force -ErrorAction SilentlyContinue
    $killed++
}

Write-Host "OpenClaw stopped ($killed processes killed)" -ForegroundColor Yellow
