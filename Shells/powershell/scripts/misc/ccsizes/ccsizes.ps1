# ccsizes - Show Claude Code directory sizes
$dirs = @(
    "$env:USERPROFILE\.claude",
    "$env:APPDATA\Claude",
    "$env:LOCALAPPDATA\Claude",
    "$env:LOCALAPPDATA\npm\node_modules\@anthropic-ai"
)
Write-Host "=== Claude Code Sizes ===" -ForegroundColor Cyan
foreach ($d in $dirs) {
    if (Test-Path $d) {
        $size = (Get-ChildItem $d -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
        Write-Host "  $d : $([math]::Round($size/1MB, 2))MB" -ForegroundColor White
    }
}