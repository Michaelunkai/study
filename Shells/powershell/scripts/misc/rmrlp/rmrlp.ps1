# rmrlp - Remove RLP state file
$statePath = "$env:USERPROFILE\.claude\rlp-state.json"
if (Test-Path $statePath) {
    $backup = "$env:USERPROFILE\.claude\rlp-state.backup.json"
    Copy-Item $statePath $backup -Force
    Remove-Item $statePath -Force
    Write-Host "RLP state removed (backup at $backup)" -ForegroundColor Yellow
} else {
    Write-Host "No RLP state to remove" -ForegroundColor Gray
}