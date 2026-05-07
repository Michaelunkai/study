# openclaw-start - Start OpenClaw gateway and ClawdBot tray
$restart = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) 'Restart-OpenclawGateway.ps1'
Write-Host 'Starting OpenClaw...' -ForegroundColor Cyan
if (Test-Path $restart) {
    & $restart
    Write-Host 'OpenClaw started' -ForegroundColor Green
} else {
    Write-Warning "Restart-OpenclawGateway.ps1 not found at $restart"
}
