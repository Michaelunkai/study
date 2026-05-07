# clawlog - Show recent OpenClaw logs
param([int]$Lines = 20)
) 
. 'F:\study\AI_ML\AI_and_Machine_Learning\Artificial_Intelligence\openclaw\scripts\Resolve-OpenClawPaths.ps1'
$paths = Get-OpenClawPaths
@(
    (Join-Path $paths.ChannelsRoot 'channel.log'),
    (Join-Path $paths.ChannelsRoot 'tg-debug.log'),
    (Join-Path $paths.ChannelsRoot 'claude-debug.log')
) | Where-Object { Test-Path $_ } | ForEach-Object {
    Write-Host "=== $_ ===" -ForegroundColor Cyan
    Get-Content $_ -Tail $Lines
}
