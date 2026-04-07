#Requires -RunAsAdministrator
# Deep C: Drive Scanner - Find ALL cleanable folders
# This script scans the entire C: drive for temp, cache, log, and download folders

param(
    [switch]$FastMode = $false,
    [int]$MinSizeMB = 0
)

$cyan = [char]27 + '[96m';
$green = [char]27 + '[92m';
$yellow = [char]27 + '[93m';
$reset = [char]27 + '[0m'

Write-Host "$cyan=== DEEP C: DRIVE FOLDER DISCOVERY ===$reset`n"

# Folders to SKIP (protected system/program areas)
$skipPaths = @(
    'C:\Windows\System32',
    'C:\Windows\SysWOW64',
    'C:\Windows\WinSxS',
    'C:\Program Files',
    'C:\Program Files (x86)',
    'C:\ProgramFiles',
    'C:\ProgramFiles(x86)',
    'C:\Recovery',
    'C:\$Recycle.Bin'
)

function ShouldSkip {
    param([string]$path)
    foreach ($skip in $skipPaths) {
        if ($path -like "$skip*") { return $true }
    }
    return $false
}

# Pattern detection
$tempPatterns = @('*temp*', '*tmp*', '*.tmp', '*cache*', '*.cache', '*log*', '*.log', '*downloads*', '*download*', '*prefetch*')

$discoveredFolders = @()
$folderCount = 0
$scannedCount = 0

Write-Host "$yellow[SCANNING] Recursively analyzing C: drive (this may take 2-5 minutes)...$reset`n"

# Main scan loop
Get-ChildItem -Path 'C:\' -Recurse -Directory -Force -ErrorAction SilentlyContinue -Depth 10 |
    Where-Object {
        # Skip protected paths
        -not (ShouldSkip $_.FullName)
    } |
    ForEach-Object {
        $scannedCount += 1
        $folderName = $_.Name.ToLower()

        # Check if folder matches any temp/cache/log pattern
        $isMatch = $false
        foreach ($pattern in $tempPatterns) {
            if ($folderName -like $pattern) {
                $isMatch = $true
                break
            }
        }

        if ($isMatch) {
            try {
                # Get folder size
                $size = 0
                if ($fastMode) {
                    # Fast: count files only, don't recurse
                    $size = (Get-Item $_.FullName -Force -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Length) -as [long]
                } else {
                    # Comprehensive: full recursive size
                    $size = (Get-ChildItem $_.FullName -Recurse -Force -ErrorAction SilentlyContinue |
                        Measure-Object -Property Length -Sum).Sum
                }

                if ($size -gt 0) {
                    $sizeMB = [math]::Round($size / 1MB, 2)

                    # Only include if meets minimum size threshold
                    if ($sizeMB -ge $MinSizeMB) {
                        $folderCount += 1
                        $discoveredFolders += @{
                            Path = $_.FullName
                            Size = $size
                            SizeMB = $sizeMB
                        }

                        # Show real-time progress
                        if ($folderCount % 10 -eq 0) {
                            Write-Host "  [$folderCount] Found: $($_.FullName) : $($sizeMB)MB" -ForegroundColor White
                        }
                    }
                }
            } catch {
                # Skip inaccessible folders
            }
        }

        # Progress indicator every 1000 folders
        if ($scannedCount % 1000 -eq 0) {
            Write-Host "  [Progress] Scanned $scannedCount folders, found $folderCount cleanable..." -ForegroundColor Yellow
        }
    }

Write-Host "`n$green[COMPLETE] Scan finished!$reset`n"

# Sort by size descending
$discoveredFolders = $discoveredFolders | Sort-Object { $_.SizeMB } -Descending

Write-Host "$cyan=== TOP 50 LARGEST CLEANABLE FOLDERS ===$reset`n"
$discoveredFolders | Select-Object -First 50 | ForEach-Object {
    Write-Host "  $($_.SizeMB)MB : $($_.Path)" -ForegroundColor White
}

# Summary by category
Write-Host "`n$cyan=== SUMMARY ===$reset`n"
Write-Host "Total folders found: $folderCount" -ForegroundColor Green
Write-Host "Total scanned: $scannedCount" -ForegroundColor White
Write-Host "Total space: $([math]::Round(($discoveredFolders | Measure-Object -Property Size -Sum).Sum / 1GB, 2))GB" -ForegroundColor Green

# Categorize
$tempFolders = $discoveredFolders | Where-Object { $_.Path -like '*temp*' -or $_.Path -like '*.tmp' }
$cacheFolders = $discoveredFolders | Where-Object { $_.Path -like '*cache*' }
$logFolders = $discoveredFolders | Where-Object { $_.Path -like '*log*' }
$downloadFolders = $discoveredFolders | Where-Object { $_.Path -like '*download*' }

Write-Host "`nBreakdown:`n"
Write-Host "  TEMP folders: $($tempFolders.Count) folders, $([math]::Round(($tempFolders | Measure-Object -Property Size -Sum).Sum / 1GB, 2))GB"
Write-Host "  CACHE folders: $($cacheFolders.Count) folders, $([math]::Round(($cacheFolders | Measure-Object -Property Size -Sum).Sum / 1GB, 2))GB"
Write-Host "  LOG folders: $($logFolders.Count) folders, $([math]::Round(($logFolders | Measure-Object -Property Size -Sum).Sum / 1GB, 2))GB"
Write-Host "  DOWNLOAD folders: $($downloadFolders.Count) folders, $([math]::Round(($downloadFolders | Measure-Object -Property Size -Sum).Sum / 1GB, 2))GB"

# Export results
$exportPath = "$env:USERPROFILE\.claude\discovered-folders.txt"
Write-Host "`n$yellow[EXPORT] Saving discovered folders to: $exportPath$reset"
$discoveredFolders | ForEach-Object { "'$($_.Path)'," } | Set-Content $exportPath
Write-Host "Exported paths as PowerShell array entries" -ForegroundColor Green

# Show how to use results
Write-Host "`n$cyan=== NEXT STEPS ===$reset"
Write-Host "1. Review the exported folders: $exportPath"
Write-Host "2. Copy safe folders into ccsizes-cleanup.ps1 cleanupFolders array"
Write-Host "3. Test with ccestimate to verify all folders are found"
Write-Host "4. Run cccleanup to delete them"
