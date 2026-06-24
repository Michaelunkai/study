# =====================================================
#   Game Torrent Downloader - qBittorrent Auto-Search
#   Searches qBittorrent WebUI API for game torrents,
#   filters for games only, picks best magnet, adds
#   automatically. Never interrupts running qBittorrent.
#   Usage: ./a.ps1 "game name" "game name" ...
# =====================================================

$SearchTerms = $args
$isCliMode = $SearchTerms -and $SearchTerms.Count -gt 0

if (-not $isCliMode) {
    Write-Host "No game names provided." -ForegroundColor Yellow
    Write-Host 'Usage: ./a.ps1 "Baldurs Gate 3" "Elden Ring" "Hades II"' -ForegroundColor Cyan
    exit 0
}

$ProjectPath = $PSScriptRoot
$cliScript = Join-Path $ProjectPath "cli_downloader.py"

if (-not (Test-Path $cliScript)) {
    Write-Host "ERROR: cli_downloader.py not found in $ProjectPath" -ForegroundColor Red
    exit 1
}

# Find Python - check known real installs FIRST, not Windows Store stubs
$pythonPath = $null
$pythonPaths = @(
    "$env:LocalAppData\Programs\Python\Python312\python.exe",
    "$env:LocalAppData\Programs\Python\Python311\python.exe",
    "$env:ProgramFiles\Python312\python.exe",
    "$env:ProgramFiles\Python311\python.exe",
    (Get-Command python -ErrorAction SilentlyContinue).Source
)
foreach ($p in $pythonPaths) {
    if ($p -and (Test-Path $p)) { $pythonPath = $p; break }
}
if (-not $pythonPath) { $pythonPath = "python" }

Write-Host "`n=== Game Torrent Downloader v2.0 ===" -ForegroundColor Cyan
Write-Host "Multi-source search with fuzzy matching" -ForegroundColor DarkGray

$pythonArgs = @($cliScript) + $SearchTerms
& $pythonPath $pythonArgs

Write-Host "`nDone!" -ForegroundColor Green
