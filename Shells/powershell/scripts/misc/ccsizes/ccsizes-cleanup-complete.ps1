#Requires -RunAsAdministrator
# ccsizes-cleanup-complete - Comprehensive cleanup with 822 safe folders
# Scans and cleans up 17GB+ of temp/cache/log files from C: drive

param(
    [switch]$Cleanup = $false,
    [switch]$Estimate = $true
)

# Color codes
$cyan = [char]27 + '[96m';
$green = [char]27 + '[92m';
$yellow = [char]27 + '[93m';
$red = [char]27 + '[91m';
$reset = [char]27 + '[0m'

Write-Host "$cyan=== Claude Code Sizes ===$reset" -ForegroundColor Cyan
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

# Load the 822 safe folders from file
$safeFolderFile = "$env:USERPROFILE\.claude\safe-folders-final.txt"
$cleanupFolders = @()

if (Test-Path $safeFolderFile) {
    Write-Host "`n$cyan[LOADING] Reading 822 pre-discovered safe folders...$reset"
    Get-Content $safeFolderFile | ForEach-Object {
        $path = $_ -replace "^'|',$", ""
        if ($path) { $cleanupFolders += $path }
    }
    Write-Host "Loaded $($cleanupFolders.Count) folders from cache`n"
} else {
    Write-Host "`n$yellow[WARNING] Safe folders file not found at $safeFolderFile$reset"
    Write-Host "Run: powershell -NoProfile -File `"F:\study\Shells\powershell\scripts\misc\ccsizes\filter-folders-v2.ps1`"`n"

    # Fallback to basic folders if file doesn't exist
    $cleanupFolders = @(
        'C:\Windows\Temp',
        'C:\Windows\Prefetch',
        'C:\Windows\SoftwareDistribution\Download',
        "$env:USERPROFILE\AppData\Local\Temp"
    )
    Write-Host "$yellow[FALLBACK] Using basic cleanup list (4 folders)$reset`n"
}

Write-Host "$yellow=== C: Drive Cleanup Analysis ===$reset`n"

$totalFreed = 0;
$folderCount = 0;
$foldersCleaned = 0;
$cleanedFolders = @();

# First pass: estimate space
Write-Host "$cyan[SCANNING] Analyzing discovered folders for cleanable space...$reset`n"

$cleanupFolders | ForEach-Object {
    $folder = $_

    # Skip non-existent paths
    if (-not (Test-Path $folder -ErrorAction SilentlyContinue)) {
        return;
    }

    $folderCount += 1;

    # Get folder size safely
    $folderSize = 0;
    try {
        if (Test-Path $folder -PathType Container) {
            $files = @(Get-ChildItem $folder -Recurse -Force -ErrorAction SilentlyContinue | Where-Object { $_ -ne $null -and $_.PSIsContainer -eq $false });
            if ($files.Count -gt 0) { $folderSize = ($files | Measure-Object -Property Length -Sum).Sum; } else { $folderSize = 0; };
        } else {
            $folderSize = (Get-Item $folder -Force -ErrorAction SilentlyContinue).Length;
        }
    } catch {
        # Skip inaccessible folders
        return;
    }

    if ($folderSize -gt 0) {
        $folderSizeMB = [math]::Round($folderSize/1MB, 2);
        $totalFreed += $folderSize;
        if ($folderCount % 50 -eq 0) {
            Write-Host "  [$folderCount] $folder : $($folderSizeMB)MB" -ForegroundColor White;
        }
        $cleanedFolders += @{ Path = $folder; Size = $folderSize; SizeMB = $folderSizeMB };
    }
}

Write-Host "`n$green[ESTIMATE] Total cleanable space: $([math]::Round($totalFreed/1MB, 2))MB ($([math]::Round($totalFreed/1GB, 2))GB)$reset`n"

if ($Cleanup) {
    Write-Host "$yellow[CLEANUP] Starting cleanup of $($cleanedFolders.Count) folders...$reset`n"

    $cleanedCount = 0;
    $actualFreed = 0;

    foreach ($folderInfo in $cleanedFolders) {
        $folderPath = $folderInfo.Path;
        $cleanedCount += 1;

        Write-Host -NoNewline "  [$cleanedCount/$($cleanedFolders.Count)] Cleaning: $folderPath ... ";

        try {
            if (Test-Path $folderPath -PathType Container) {
                # Remove folder contents, not the folder itself (preserves permissions)
                Get-ChildItem $folderPath -Recurse -Force -ErrorAction SilentlyContinue |
                    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue;
                Write-Host "$green[DONE]$reset ($($folderInfo.SizeMB)MB)" -ForegroundColor Green;
                $actualFreed += $folderInfo.Size;
                $foldersCleaned += 1;
            } else {
                # For files, just remove the file
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
    Write-Host "  Folders processed: $foldersCleaned"
    Write-Host "  Space freed: $([math]::Round($actualFreed/1MB, 2))MB ($([math]::Round($actualFreed/1GB, 2))GB)`n"
} else {
    Write-Host "$yellow[INFO] Estimate mode. To actually cleanup, run with -Cleanup flag$reset`n"
}

Write-Host "$cyan=== Cleanup Summary ===$reset"
Write-Host "  Discoverable folders: $($cleanupFolders.Count)"
Write-Host "  Folders with space: $($cleanedFolders.Count)"
Write-Host "  Total freeable space: $([math]::Round($totalFreed/1MB, 2))MB ($([math]::Round($totalFreed/1GB, 2))GB)"
if ($Cleanup) {
    Write-Host "  Folders cleaned: $foldersCleaned"
    Write-Host "  Actual space freed: $([math]::Round($actualFreed/1MB, 2))MB`n"
}
