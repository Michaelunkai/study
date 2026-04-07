# todoit - Quick inline todo manager
param([Parameter(ValueFromRemainingArguments=$true)][string[]]$Task)
$todoFile = "$env:USERPROFILE\.claude\todoit.txt"
if (-not $Task) {
    if (Test-Path $todoFile) {
        Write-Host "=== Todos ===" -ForegroundColor Cyan
        $lines = Get-Content $todoFile
        for ($i = 0; $i -lt $lines.Count; $i++) { Write-Host "  $($i+1). $($lines[$i])" -ForegroundColor White }
    } else { Write-Host "No todos" -ForegroundColor Yellow }
    return
}
$text = $Task -join ' '
if ($text -match '^done (\d+)$') {
    $lines = @(Get-Content $todoFile)
    $idx = [int]$Matches[1] - 1
    if ($idx -ge 0 -and $idx -lt $lines.Count) {
        Write-Host "Done: $($lines[$idx])" -ForegroundColor Green
        $lines = $lines | Where-Object { $_ -ne $lines[$idx] }
        $lines | Set-Content $todoFile
    }
    return
}
Add-Content $todoFile $text
Write-Host "Added: $text" -ForegroundColor Green