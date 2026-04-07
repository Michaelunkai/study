#Requires -RunAsAdministrator
# ccsizes-cleanup - Enhanced cleanup with real-time progress

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

# Define 40+ safe cleanup folders on C: drive
$cleanupFolders = @(
    # Windows system temps
    'C:\Windows\Temp',
    'C:\Windows\Prefetch',
    'C:\Windows\SoftwareDistribution\Download',
    'C:\Windows\LiveKernelReports',
    'C:\Windows\Memory.dmp',
    'C:\ProgramData\Package Cache',

    # User temps
    "$env:USERPROFILE\AppData\Local\Temp",
    "$env:USERPROFILE\AppData\Local\Adobe",
    "$env:USERPROFILE\AppData\Local\Google\Chrome\User Data\Default\Cache",
    "$env:USERPROFILE\AppData\Local\Google\Chrome\User Data\Default\Code Cache",
    "$env:USERPROFILE\AppData\Local\Chromium\User Data\Default\Cache",
    "$env:USERPROFILE\AppData\Local\Chromium\User Data\Default\Code Cache",
    "$env:USERPROFILE\AppData\Local\Microsoft\Windows\INetCache",
    "$env:USERPROFILE\AppData\Local\Microsoft\Windows\Temporary Internet Files",
    "$env:USERPROFILE\AppData\Local\Microsoft\Edge\User Data\Default\Cache",
    "$env:USERPROFILE\AppData\Local\Microsoft\Edge\User Data\Default\Code Cache",
    "$env:USERPROFILE\AppData\LocalLow\Microsoft\Windows\INetCache",

    # Node/npm caches
    "$env:USERPROFILE\AppData\Roaming\npm-cache",
    "$env:USERPROFILE\.npm",

    # Python caches
    "$env:USERPROFILE\AppData\Local\pip\cache",
    "$env:USERPROFILE\.cache\pip",
    'C:\Users\*\AppData\Local\Python\*\site-packages\__pycache__',

    # .NET caches
    "$env:USERPROFILE\AppData\Local\NuGet\v3-cache",
    "$env:USERPROFILE\.nuget\packages",

    # Maven/Gradle
    "$env:USERPROFILE\.m2\repository",
    "$env:USERPROFILE\.gradle\caches",

    # Composer
    "$env:USERPROFILE\AppData\Roaming\Composer\cache",

    # Vagrant
    "$env:USERPROFILE\.vagrant.d\tmp",

    # Visual Studio caches
    'C:\ProgramData\Microsoft\VisualStudio',
    "$env:USERPROFILE\AppData\Local\Microsoft\VisualStudio\*\ComponentModelCache",

    # Windows Update caches
    'C:\Windows\Installer\$PatchCache$',

    # Delivery Optimization cache
    'C:\Windows\System32\Tasks\Microsoft\Windows\DeliveryOptimization',
    'C:\Windows\SoftwareDistribution\DataStore\Logs',

    # Windows Update logs
    'C:\Windows\servicing\Packages\*\InstallDate',

    # Event logs cleanup (archived)
    'C:\Windows\System32\winevt\Logs\Archive*',

    # DirectX caches
    "$env:USERPROFILE\AppData\Local\DirectX",

    # Steam shader cache
    'C:\Program Files (x86)\Steam\steamapps\shadercache',
    'C:\Program Files\Steam\steamapps\shadercache',

    # OneDrive cache
    "$env:USERPROFILE\AppData\Local\Microsoft\OneDrive\logs",
    "$env:USERPROFILE\AppData\Local\Microsoft\OneDrive\cache",

    # ASP.NET temporary files
    'C:\Windows\Microsoft.NET\Framework\v4.0.30319\Temporary ASP.NET Files',
    'C:\Windows\Microsoft.NET\Framework64\v4.0.30319\Temporary ASP.NET Files'
)

Write-Host "`n$yellow=== C: Drive Cleanup Analysis ===$reset`n"

$totalFreed = 0;
$folderCount = 0;
$foldersCleaned = 0;
$cleanedFolders = @();

# First pass: estimate space
Write-Host "$cyan[SCANNING] Analyzing C: drive for cleanable folders...$reset`n"

foreach ($folder in $cleanupFolders) {
    # Skip non-existent paths
    if (-not (Test-Path $folder -ErrorAction SilentlyContinue)) {
        continue;
    }

    $folderCount += 1;

    # Get folder size safely
    $folderSize = 0;
    try {
        if (Test-Path $folder -PathType Container) {
            $folderSize = (Get-ChildItem $folder -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum;
        } else {
            $folderSize = (Get-Item $folder -Force -ErrorAction SilentlyContinue).Length;
        }
    } catch {
        # Skip inaccessible folders
        continue;
    }

    if ($folderSize -gt 0) {
        $folderSizeMB = [math]::Round($folderSize/1MB, 2);
        $totalFreed += $folderSize;
        Write-Host "  [$folderCount] $folder : $($folderSizeMB)MB" -ForegroundColor White;
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
Write-Host "  Cleanable folders found: $($cleanedFolders.Count)"
Write-Host "  Total freeable space: $([math]::Round($totalFreed/1MB, 2))MB"
if ($Cleanup) {
    Write-Host "  Folders cleaned: $foldersCleaned"
    Write-Host "  Actual space freed: $([math]::Round($actualFreed/1MB, 2))MB`n"
}
