# megaclean - Mega system cleanup
Write-Host "=== MEGACLEAN ===" -ForegroundColor Cyan
# Temp files
$before = (Get-PSDrive C).Free
Get-ChildItem "$env:TEMP" -Force -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-1) } | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
# Windows temp
Get-ChildItem "C:\Windows\Temp" -Force -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-1) } | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
# Recycle bin
try { Clear-RecycleBin -Force -ErrorAction SilentlyContinue } catch {}
$after = (Get-PSDrive C).Free
$freed = [math]::Round(($after - $before) / 1MB, 1)
Write-Host "  Freed: ${freed}MB" -ForegroundColor Green