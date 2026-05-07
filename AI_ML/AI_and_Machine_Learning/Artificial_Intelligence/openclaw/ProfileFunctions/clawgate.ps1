# clawgate - Restart OpenClaw gateway
$restart = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) 'Restart-OpenclawGateway.ps1'
if (Test-Path $restart) {
    Write-Host 'Restarting OpenClaw gateway...' -ForegroundColor Cyan
    & $restart
} else { Write-Warning "Restart-OpenclawGateway.ps1 not found at $restart" }
