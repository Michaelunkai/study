<#
.SYNOPSIS
    clawd - Ensure the hidden OpenClaw tray-managed runtime is running and healthy
#>
$restart = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) 'Restart-OpenclawGateway.ps1'
if (-not (Test-Path -LiteralPath $restart)) {
    Write-Warning "clawd: restart helper not found at $restart"
    return
}

$ok = & $restart -TimeoutSec 150
if (-not $ok) {
    Write-Warning 'clawd: OpenClaw failed to reach a healthy tray-managed state.'
}
