# listclau - List backup folders/files in F:\backup\claudecode sorted by latest created (fast .NET enumeration)
$backupPath = 'F:\backup\claudecode'
Write-Host "=== F:\backup\claudecode (latest first) ===" -ForegroundColor Cyan
Write-Host ""

$items = [System.IO.Directory]::GetFileSystemEntries($backupPath) | ForEach-Object {
    if ([System.IO.Directory]::Exists($_)) { [System.IO.DirectoryInfo]::new($_) }
    else { [System.IO.FileInfo]::new($_) }
} | Sort-Object CreationTime -Descending

if (-not $items) { Write-Host "No items found in $backupPath" -ForegroundColor Yellow; return }

$items | ForEach-Object {
    $isDir = $_ -is [System.IO.DirectoryInfo]
    $sizeBytes = if ($isDir) {
        $total = 0L
        try {
            foreach ($f in [System.IO.Directory]::EnumerateFiles($_.FullName, '*', [System.IO.SearchOption]::AllDirectories)) {
                $total += [System.IO.FileInfo]::new($f).Length
            }
        } catch {}
        $total
    } else { $_.Length }
    $sizeMB = [math]::Round($sizeBytes / 1MB, 2)
    $sizeGB = [math]::Round($sizeBytes / 1GB, 3)
    $type = if ($isDir) { '[DIR] ' } else { '[FILE]' }
    $color = if ($isDir) { 'Yellow' } else { 'White' }
    Write-Host ("{0} {1,-45} {2,10} MB  ({3,8} GB)  Created: {4}" -f $type, $_.Name, $sizeMB, $sizeGB, $_.CreationTime.ToString('yyyy-MM-dd HH:mm:ss')) -ForegroundColor $color
}