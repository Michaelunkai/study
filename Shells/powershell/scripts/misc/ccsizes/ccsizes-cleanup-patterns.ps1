#Requires -RunAsAdministrator
# ccsizes-cleanup-patterns - Comprehensive cleanup with 40+ BROAD PATH PATTERNS
# Matches hundreds of folders per pattern using wildcards

param(
    [switch]$Cleanup = $false,
    [switch]$Estimate = $true
)

$cyan = [char]27 + '[96m';
$green = [char]27 + '[92m';
$yellow = [char]27 + '[93m';
$red = [char]27 + '[91m';
$reset = [char]27 + '[0m'

Write-Host "$cyan=== Claude Code Sizes ===$reset"
$dirs = @(
    "$env:USERPROFILE\.claude",
    "$env:APPDATA\Claude",
    "$env:LOCALAPPDATA\Claude",
    "$env:LOCALAPPDATA\npm\node_modules\@anthropic-ai"
)
foreach ($d in $dirs) {
    if (Test-Path $d) {
        $size = (Get-ChildItem $d -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
        Write-Host "  $d : $([math]::Round($size/1MB, 2))MB"
    }
}

# ========== 40+ BROAD CLEANUP PATH PATTERNS ==========
# Each pattern uses wildcards to match hundreds of folders automatically
$cleanupPatterns = @(
    # === USER TEMP/CACHE (AppData\Local) ===
    "$env:USERPROFILE\AppData\Local\Temp\*",                    # 1. User temp everything
    "$env:USERPROFILE\AppData\Local\*\Cache\*",                 # 2. Any app cache (Local)
    "$env:USERPROFILE\AppData\Local\*\cache\*",                 # 3. Lowercase cache
    "$env:USERPROFILE\AppData\Local\*\Temp\*",                  # 4. Any app temp folder
    "$env:USERPROFILE\AppData\Local\*\temp\*",                  # 5. Lowercase temp
    "$env:USERPROFILE\AppData\Local\*\Log\*",                   # 6. Any app logs
    "$env:USERPROFILE\AppData\Local\*\log\*",                   # 7. Lowercase logs
    "$env:USERPROFILE\AppData\Local\*\*\Cache\*",               # 8. Nested cache (2 levels)
    "$env:USERPROFILE\AppData\Local\*\*\temp\*",                # 9. Nested temp
    "$env:USERPROFILE\AppData\Local\*\*\log\*",                 # 10. Nested logs

    # === USER TEMP/CACHE (AppData\Roaming) ===
    "$env:USERPROFILE\AppData\Roaming\*\Cache\*",               # 11. Roaming app cache
    "$env:USERPROFILE\AppData\Roaming\*\cache\*",               # 12. Lowercase
    "$env:USERPROFILE\AppData\Roaming\*\Temp\*",                # 13. Roaming temp
    "$env:USERPROFILE\AppData\Roaming\*\temp\*",                # 14. Lowercase
    "$env:USERPROFILE\AppData\Roaming\*\Log\*",                 # 15. Roaming logs
    "$env:USERPROFILE\AppData\Roaming\*\log\*",                 # 16. Lowercase
    "$env:USERPROFILE\AppData\Roaming\*\*\Cache\*",             # 17. Nested Roaming cache
    "$env:USERPROFILE\AppData\Roaming\*\*\Temp\*",              # 18. Nested Roaming temp

    # === USER TEMP/CACHE (AppData\LocalLow) ===
    "$env:USERPROFILE\AppData\LocalLow\*\Cache\*",              # 19. LocalLow cache
    "$env:USERPROFILE\AppData\LocalLow\*\cache\*",              # 20. Lowercase
    "$env:USERPROFILE\AppData\LocalLow\*\Temp\*",               # 21. LocalLow temp
    "$env:USERPROFILE\AppData\LocalLow\*\temp\*",               # 22. Lowercase

    # === WINDOWS SYSTEM TEMPS/LOGS ===
    "C:\Windows\Temp\*",                                         # 23. Windows temp
    "C:\Windows\*\Temp\*",                                       # 24. Any subfolder temp
    "C:\Windows\*\temp\*",                                       # 25. Lowercase
    "C:\Windows\*\Log\*",                                        # 26. Windows logs
    "C:\Windows\*\log\*",                                        # 27. Lowercase
    "C:\Windows\*\Cache\*",                                      # 28. Windows cache
    "C:\Windows\*\cache\*",                                      # 29. Lowercase
    "C:\Windows\Prefetch\*",                                     # 30. Prefetch folder

    # === PROGRAMDATA CACHES/LOGS ===
    "C:\ProgramData\*\Cache\*",                                  # 31. ProgramData cache
    "C:\ProgramData\*\cache\*",                                  # 32. Lowercase
    "C:\ProgramData\*\Log\*",                                    # 33. ProgramData logs
    "C:\ProgramData\*\log\*",                                    # 34. Lowercase
    "C:\ProgramData\*\Temp\*",                                   # 35. ProgramData temp
    "C:\ProgramData\*\temp\*",                                   # 36. Lowercase

    # === SPECIAL SYSTEM CLEANUP ===
    "C:\Windows\SoftwareDistribution\Download\*",               # 37. Windows Update downloads
    "C:\Windows\Installer\$PatchCache$\*",                      # 38. Patch cache
    "C:\Users\*\AppData\Local\Package Cache\*",                 # 39. Package caches
    "C:\Windows\ServiceProfiles\*\AppData\Local\*\Cache\*"      # 40. Service profile caches
)

Write-Host "`n$yellow=== C: Drive Cleanup Analysis ===$reset`n"

$totalFreed = 0;
$patternCount = 0;
$foldersCleaned = 0;
$cleanedFolders = @();

Write-Host "$cyan[SCANNING] Analyzing $($cleanupPatterns.Count) broad cleanup patterns...$reset`n"

foreach ($pattern in $cleanupPatterns) {
    $patternCount += 1;

    # Expand pattern and get matching folders
    try {
        $matchingFolders = @(Get-Item $pattern -Force -ErrorAction SilentlyContinue | Where-Object {$_ -is [System.IO.DirectoryInfo]})

        if ($matchingFolders.Count -gt 0) {
            foreach ($folder in $matchingFolders) {
                $folderSize = 0;
                try {
                    $folderSize = (Get-ChildItem $folder.FullName -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum;
                } catch {}

                if ($folderSize -gt 0) {
                    $folderSizeMB = [math]::Round($folderSize/1MB, 2);
                    $totalFreed += $folderSize;
                    $cleanedFolders += @{ Path = $folder.FullName; Size = $folderSize; SizeMB = $folderSizeMB };
                }
            }
        }
    } catch {}

    # Show progress every 5 patterns
    if ($patternCount % 5 -eq 0) {
        Write-Host "  [$patternCount/$($cleanupPatterns.Count)] Processed patterns..." -ForegroundColor Yellow;
    }
}

# Remove duplicates and sort
$cleanedFolders = $cleanedFolders | Sort-Object -Property Path -Unique | Sort-Object { $_.SizeMB } -Descending

Write-Host "`n$green[ESTIMATE] Total cleanable space: $([math]::Round($totalFreed/1MB, 2))MB ($([math]::Round($totalFreed/1GB, 2))GB)$reset`n"

Write-Host "Pattern Statistics:" -ForegroundColor Cyan
Write-Host "  Cleanup patterns: $($cleanupPatterns.Count)"
Write-Host "  Matching folders found: $($cleanedFolders.Count)"
Write-Host "`nTop 30 folders to clean:" -ForegroundColor Yellow
$cleanedFolders | Select-Object -First 30 | ForEach-Object {
    Write-Host "  $($_.SizeMB)MB : $($_.Path)" -ForegroundColor White
}

if ($Cleanup) {
    Write-Host "`n$yellow[CLEANUP] Starting cleanup of $($cleanedFolders.Count) folders...$reset`n"

    $cleanedCount = 0;
    $actualFreed = 0;

    foreach ($folderInfo in $cleanedFolders) {
        $folderPath = $folderInfo.Path;
        $cleanedCount += 1;

        Write-Host -NoNewline "  [$cleanedCount/$($cleanedFolders.Count)] Cleaning: $folderPath ... ";

        try {
            if (Test-Path $folderPath -PathType Container) {
                Get-ChildItem $folderPath -Recurse -Force -ErrorAction SilentlyContinue |
                    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue;
                Write-Host "$green[DONE]$reset ($($folderInfo.SizeMB)MB)" -ForegroundColor Green;
                $actualFreed += $folderInfo.Size;
                $foldersCleaned += 1;
            } else {
                Remove-Item $folderPath -Force -ErrorAction SilentlyContinue;
                Write-Host "$green[DONE]$reset ($($folderInfo.SizeMB)MB)" -ForegroundColor Green;
                $actualFreed += $folderInfo.Size;
                $foldersCleaned += 1;
            }
        } catch {
            Write-Host "$red[SKIPPED]$reset (Permission denied)" -ForegroundColor Red;
        }
    }

    Write-Host "`n$green[SUCCESS] Cleanup complete!$reset"
    Write-Host "  Folders cleaned: $foldersCleaned"
    Write-Host "  Space freed: $([math]::Round($actualFreed/1MB, 2))MB ($([math]::Round($actualFreed/1GB, 2))GB)`n"
} else {
    Write-Host "`n$yellow[INFO] Estimate mode. To actually cleanup, run with -Cleanup flag$reset`n"
}

Write-Host "$cyan=== Cleanup Summary ===$reset"
Write-Host "  Cleanup patterns: $($cleanupPatterns.Count) broad patterns"
Write-Host "  Folders found: $($cleanedFolders.Count)"
Write-Host "  Total freeable space: $([math]::Round($totalFreed/1MB, 2))MB ($([math]::Round($totalFreed/1GB, 2))GB)"
if ($Cleanup) {
    Write-Host "  Folders cleaned: $foldersCleaned"
    Write-Host "  Actual space freed: $([math]::Round($actualFreed/1MB, 2))MB`n"
}
