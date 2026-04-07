# brules - Browse CLAUDE.md rules across all locations
$paths = @(
    "$env:USERPROFILE\.claude\CLAUDE.md",
    "$env:USERPROFILE\CLAUDE.md",
    "$env:USERPROFILE\Documents\WindowsPowerShell\CLAUDE.md"
)
foreach ($p in $paths) {
    if (Test-Path $p) {
        Write-Host "`n=== $p ===" -ForegroundColor Cyan
        $rules = Get-Content $p | Select-String "^## Rule"
        foreach ($r in $rules) { Write-Host "  $($r.Line)" -ForegroundColor White }
    }
}