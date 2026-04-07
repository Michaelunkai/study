# ccsizes - Show Claude Code sizes + auto-cleanup C: drive temp/cache/log folders

$cyan = [char]27 + '[96m'; $green = [char]27 + '[92m'; $yellow = [char]27 + '[93m'; $red = [char]27 + '[91m'; $reset = [char]27 + '[0m'

Write-Host "$cyan=== Claude Code Sizes ===$reset"
foreach ($d in @("$env:USERPROFILE\.claude","$env:APPDATA\Claude","$env:LOCALAPPDATA\Claude")) {
    if (Test-Path $d) {
        $s = 0; Get-ChildItem $d -Recurse -Force -File -EA SilentlyContinue | ForEach-Object { $s += $_.Length }
        Write-Host "  $d : $([math]::Round($s/1MB,2))MB"
    }
}

# Get C: free space BEFORE cleanup
$volBefore = (Get-Volume -DriveLetter C).SizeRemaining

# 72 broad cleanup patterns covering ALL temp/cache/log across C: drive
$patterns = @(
    # AppData\Local temp/cache/log (13)
    "$env:USERPROFILE\AppData\Local\Temp\*",
    "$env:USERPROFILE\AppData\Local\*\Cache\*",
    "$env:USERPROFILE\AppData\Local\*\cache\*",
    "$env:USERPROFILE\AppData\Local\*\Temp\*",
    "$env:USERPROFILE\AppData\Local\*\temp\*",
    "$env:USERPROFILE\AppData\Local\*\Log\*",
    "$env:USERPROFILE\AppData\Local\*\log\*",
    "$env:USERPROFILE\AppData\Local\*\*\Cache\*",
    "$env:USERPROFILE\AppData\Local\*\*\cache\*",
    "$env:USERPROFILE\AppData\Local\*\*\Temp\*",
    "$env:USERPROFILE\AppData\Local\*\*\temp\*",
    "$env:USERPROFILE\AppData\Local\*\*\Log\*",
    "$env:USERPROFILE\AppData\Local\*\*\log\*",

    # AppData\Roaming temp/cache/log (10)
    "$env:USERPROFILE\AppData\Roaming\*\Cache\*",
    "$env:USERPROFILE\AppData\Roaming\*\cache\*",
    "$env:USERPROFILE\AppData\Roaming\*\Temp\*",
    "$env:USERPROFILE\AppData\Roaming\*\temp\*",
    "$env:USERPROFILE\AppData\Roaming\*\Log\*",
    "$env:USERPROFILE\AppData\Roaming\*\log\*",
    "$env:USERPROFILE\AppData\Roaming\*\*\Cache\*",
    "$env:USERPROFILE\AppData\Roaming\*\*\cache\*",
    "$env:USERPROFILE\AppData\Roaming\*\*\Temp\*",
    "$env:USERPROFILE\AppData\Roaming\*\*\Log\*",

    # AppData\LocalLow (5)
    "$env:USERPROFILE\AppData\LocalLow\*\Cache\*",
    "$env:USERPROFILE\AppData\LocalLow\*\cache\*",
    "$env:USERPROFILE\AppData\LocalLow\*\Temp\*",
    "$env:USERPROFILE\AppData\LocalLow\*\temp\*",
    "$env:USERPROFILE\AppData\LocalLow\*\Log\*",

    # Windows system temps/logs (10)
    "C:\Windows\Temp\*",
    "C:\Windows\*\Temp\*",
    "C:\Windows\*\temp\*",
    "C:\Windows\*\Log\*",
    "C:\Windows\*\log\*",
    "C:\Windows\*\Cache\*",
    "C:\Windows\*\cache\*",
    "C:\Windows\Prefetch\*",
    "C:\Windows\ServiceState\*",
    "C:\Windows\SoftwareDistribution\Download\*",

    # ProgramData caches/logs (8)
    "C:\ProgramData\*\Cache\*",
    "C:\ProgramData\*\cache\*",
    "C:\ProgramData\*\Log\*",
    "C:\ProgramData\*\log\*",
    "C:\ProgramData\*\Temp\*",
    "C:\ProgramData\*\temp\*",
    "C:\ProgramData\*\*\Cache\*",
    "C:\ProgramData\*\*\Log\*",

    # User home profile caches (9)
    "$env:USERPROFILE\.cache\*",
    "$env:USERPROFILE\.cache\*\*",
    "$env:USERPROFILE\.npm-cache\*",
    "$env:USERPROFILE\.pnpm-cache\*",
    "$env:USERPROFILE\.pnpm\*",
    "$env:USERPROFILE\AppData\Local\*pnpm*",
    "$env:USERPROFILE\AppData\Local\*npm*",
    "$env:USERPROFILE\AppData\Local\npm-cache\*",
    "$env:USERPROFILE\AppData\Roaming\npm-cache\*",

    # Browser-specific caches (7)
    "$env:USERPROFILE\AppData\Local\Google\Chrome\*\Cache\*",
    "$env:USERPROFILE\AppData\Local\Google\Chrome\*\Code Cache\*",
    "$env:USERPROFILE\AppData\Local\Microsoft\Edge\*\Cache\*",
    "$env:USERPROFILE\AppData\Local\Microsoft\Edge\*\Code Cache\*",
    "$env:USERPROFILE\AppData\Local\Chromium\*\Cache\*",
    "$env:USERPROFILE\AppData\Local\Firefox\*\Cache\*",
    "$env:USERPROFILE\AppData\Roaming\Mozilla\Firefox\*\Cache\*",

    # Python & dev tool caches (5)
    "$env:USERPROFILE\AppData\Local\Programs\Python\*\*\*\cache\*",
    "$env:USERPROFILE\AppData\Local\pip-cache\*",
    "$env:USERPROFILE\.gradle\caches\*",
    "$env:USERPROFILE\.m2\repository\*",
    "$env:USERPROFILE\.nuget\*\cache\*",

    # System-wide cleanup (5)
    "C:\Windows\Installer\*",
    "C:\Windows\Logs\*",
    "C:\Users\*\AppData\Local\Package Cache\*",
    "C:\Windows\System32\catroot\*",
    "C:\Windows\System32\CatRoot2\*"
)

Write-Host "`n$yellow=== C: Drive Auto-Cleanup ($($patterns.Count) patterns) ===$reset`n"

$seen = @{}; $cleaned = 0; $totalMB = 0

foreach ($pat in $patterns) {
    try {
        foreach ($item in @(Get-Item $pat -Force -EA SilentlyContinue)) {
            if ($item -is [System.IO.DirectoryInfo] -and -not $seen[$item.FullName]) {
                # Skip junction/symlink duplicates (e.g. "Application Data" -> AppData)
                if ($item.FullName -match 'Application Data') { continue }
                $seen[$item.FullName] = $true
                $sz = 0; Get-ChildItem $item.FullName -Recurse -Force -File -EA SilentlyContinue | ForEach-Object { $sz += $_.Length }
                if ($sz -gt 0) {
                    $mb = [math]::Round($sz/1MB,2)
                    Write-Host -NoNewline "  Cleaning $($item.FullName) ($($mb)MB) ... "
                    try {
                        Get-ChildItem $item.FullName -Recurse -Force -EA SilentlyContinue | Remove-Item -Recurse -Force -EA SilentlyContinue
                        Write-Host "$green[DONE]$reset" -ForegroundColor Green
                        $totalMB += $mb; $cleaned++
                    } catch {
                        Write-Host "$red[SKIP]$reset" -ForegroundColor Red
                    }
                }
            }
        }
    } catch {}
}

# Get C: free space AFTER cleanup
[System.GC]::Collect(); [System.GC]::WaitForPendingFinalizers()
Start-Sleep -Seconds 1
$volAfter = (Get-Volume -DriveLetter C).SizeRemaining
$actualFreedMB = [math]::Round(($volAfter - $volBefore)/1MB, 2)

Write-Host "`n$green========================================$reset"
Write-Host "$green  CLEANUP COMPLETE$reset"
Write-Host "$green  Folders cleaned: $cleaned$reset"
Write-Host "$green  Estimated freed: $($totalMB)MB$reset"
Write-Host "$green  Actual C: freed: $($actualFreedMB)MB$reset"
Write-Host "$green========================================$reset"
