# sizes - Quick disk space analysis
Write-Host "=== Disk Usage ===" -ForegroundColor Cyan
[System.IO.DriveInfo]::GetDrives() | Where-Object { $_.IsReady } | ForEach-Object {
    $total = [math]::Round($_.TotalSize / 1GB, 1)
    $free = [math]::Round($_.AvailableFreeSpace / 1GB, 1)
    $used = $total - $free
    $pct = [math]::Round(($used / $total) * 100, 0)
    $color = if ($pct -gt 90) { 'Red' } elseif ($pct -gt 75) { 'Yellow' } else { 'Green' }
    Write-Host "  $($_.Name) $($_.DriveFormat) | ${used}/${total}GB ($pct%)" -ForegroundColor $color
}