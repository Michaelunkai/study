# backclau - Backup Claude Code configuration
$src = "$env:USERPROFILE\.claude"
$dst = "F:\backup\claudecode\backup_$((Get-Date).ToString('yyyyMMdd_HHmmss'))"
New-Item -ItemType Directory -Force -Path $dst | Out-Null
$items = @('settings.json', 'settings.local.json', 'memory', 'commands', 'rlp-state.json', 'CLAUDE.md')
$copied = 0
foreach ($item in $items) {
    $full = Join-Path $src $item
    if (Test-Path $full) {
        if ((Get-Item $full).PSIsContainer) {
            Copy-Item $full (Join-Path $dst $item) -Recurse -Force
        } else {
            Copy-Item $full (Join-Path $dst $item) -Force
        }
        $copied++
    }
}
Write-Host "Backed up $copied items to $dst" -ForegroundColor Green