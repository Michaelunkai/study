# conit - Storage & context mega-cleanup
Write-Host "=== CONIT: Storage & Context Cleanup ===" -ForegroundColor Cyan
# 1. Clean temp
$tempSize = (Get-ChildItem "$env:TEMP" -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum / 1MB
Write-Host "  TEMP: $([math]::Round($tempSize, 1))MB" -ForegroundColor Gray
Get-ChildItem "$env:TEMP" -Force -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-3) } | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
# 2. Clean Claude old sessions
$sessDir = "$env:USERPROFILE\.claude\projects"
if (Test-Path $sessDir) {
    $old = Get-ChildItem $sessDir -Recurse -Filter "*.jsonl" -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-3) }
    if ($old) { $old | Remove-Item -Force -ErrorAction SilentlyContinue; Write-Host "  Cleaned $($old.Count) old sessions" -ForegroundColor Yellow }
}
Write-Host "  Done!" -ForegroundColor Green