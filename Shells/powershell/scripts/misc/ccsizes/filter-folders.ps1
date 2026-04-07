#Requires -RunAsAdministrator
# Intelligent Folder Filter - Remove unsafe paths, deduplicate, create final cleanup list

param(
    [int]$MinSizeMB = 1,
    [switch]$ExportPowerShell = $true
)

$cyan = [char]27 + '[96m';
$green = [char]27 + '[92m';
$yellow = [char]27 + '[93m';
$red = [char]27 + '[91m';
$reset = [char]27 + '[0m'

Write-Host "$cyan=== INTELLIGENT FOLDER FILTERING ===$reset`n"

# Load discovered folders
$discoveredFile = "$env:USERPROFILE\.claude\discovered-folders.txt"
if (-not (Test-Path $discoveredFile)) {
    Write-Host "$red ERROR: Discovered folders file not found!$reset"
    Write-Host "Run discover-cleanable-folders.ps1 first"
    return
}

$allFolders = @()
Get-Content $discoveredFile | ForEach-Object {
    $path = $_ -replace "^'|',$", ""
    if ($path -and (Test-Path $path -ErrorAction SilentlyContinue)) {
        $allFolders += $path
    }
}

Write-Host "Loaded $($allFolders.Count) discovered folders`n"

# UNSAFE PATTERNS - NEVER INCLUDE
$unsafePatterns = @(
    '*\node_modules\*',           # npm dependencies - CRITICAL
    '*\site-packages\*',          # Python packages - CRITICAL
    '*\.npm\node_modules\*',      # npm global modules
    '*\AppData\Roaming\npm\*',    # npm global (but keep cache)
    '*\Program Files\*',          # Program installations
    '*\Program Files (x86)\*',    # 32-bit programs
    'C:\ProgramFiles\*',          # Alternate program path
    '*\.venv\*',                  # Python virtual environments
    '*\.vscode\*',                # VS Code settings
    '*\Documents\*',              # User documents - user might need
    '*\Downloads\*',              # Downloads - user might need (except temp)
    '*\Desktop\*',                # Desktop files
    '*\Pictures\*',               # Images
    '*\Music\*',                  # Music
    '*\Videos\*',                 # Videos
    'C:\Recovery\*',              # Windows recovery
    'C:\$Recycle.Bin\*',          # Recycle bin
    '*\System32\*',               # System files (except specific cache dirs)
    '*\SysWOW64\*',               # 32-bit system
    '*\WinSxS\*',                 # Windows component store
    'C:\ProgramData\Microsoft\Windows\Containers\*'  # Container files - risky
)

# SAFE PATTERNS - INCLUDE
$safePatterns = @(
    '*\Cache\*',
    '*\cache\*',
    '*\Temp\*',
    '*\temp\*',
    '*\.tmp\*',
    '*\.cache\*',
    '*\Log\*',
    '*\log\*',
    '*\Logs\*',
    '*\logs\*',
    '*\__pycache__\*',
    '*\GrShaderCache\*',
    '*\shader_cache\*',
    '*\Code Cache\*',
    '*\code cache\*',
    '*\prefetch\*',
    '*\Prefetch\*',
    '*\CacheStorage\*',
    '*\CefCache\*',
    '*\component_crx_cache\*',
    '*\Download Service\*',
    '*\DownloadService\*',
    '*\GPUCache\*',
    '*\GPUPersistentCache\*',
    '*\discovery_cache\*',
    '*\ServiceWorker\*',
    '*\DxCache\*',
    '*\DawnWebGPUCache\*'
)

function IsUnsafe {
    param([string]$path)

    # Check unsafe patterns
    foreach ($pattern in $unsafePatterns) {
        if ($path -like $pattern) {
            return $true
        }
    }

    # Check if it's under node_modules or packages (but allow their cache subfolders)
    if ($path -like '*\node_modules\*' -and -not ($path -like '*\node_modules\*\cache*' -or $path -like '*\node_modules\*\__pycache__*')) {
        return $true
    }

    # Never delete inside site-packages unless it's __pycache__ or discovery_cache
    if ($path -like '*\site-packages\*' -and -not ($path -like '*\__pycache__*' -or $path -like '*\discovery_cache*')) {
        return $true
    }

    return $false
}

function IsSafe {
    param([string]$path)

    foreach ($pattern in $safePatterns) {
        if ($path -like $pattern) {
            return $true
        }
    }

    return $false
}

# Filter folders
$safeFolders = @()
$filteredOut = 0

Write-Host "$yellow[FILTERING] Checking each folder for safety...$reset`n"

$allFolders | ForEach-Object {
    $path = $_

    # Skip if unsafe
    if (IsUnsafe $path) {
        $filteredOut += 1
        return
    }

    # Only keep if matches safe pattern
    if (IsSafe $path) {
        $size = 0
        try {
            $size = (Get-ChildItem $path -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
        } catch {}

        if (($size / 1MB) -ge $MinSizeMB) {
            $safeFolders += @{
                Path = $path
                Size = $size
                SizeMB = [math]::Round($size / 1MB, 2)
            }
        }
    }
}

Write-Host "$green[COMPLETE] Filtering done!$reset`n"
Write-Host "Results:" -ForegroundColor Cyan
Write-Host "  Original discovered: $($allFolders.Count)"
Write-Host "  Filtered out (unsafe): $filteredOut"
Write-Host "  Safe folders: $($safeFolders.Count)"

# Sort by size
$safeFolders = $safeFolders | Sort-Object { $_.SizeMB } -Descending

Write-Host "`nTotal space from safe folders: $([math]::Round(($safeFolders | Measure-Object -Property Size -Sum).Sum / 1GB, 2))GB`n"

# Show top 50
Write-Host "$cyan=== TOP 50 SAFE CLEANABLE FOLDERS ===$reset`n"
$safeFolders | Select-Object -First 50 | ForEach-Object {
    Write-Host "$($_.SizeMB)MB : $($_.Path)" -ForegroundColor White
}

# Categorize
Write-Host "`n$cyan=== CATEGORY BREAKDOWN ===$reset`n"

$cacheFolders = $safeFolders | Where-Object { $_.Path -like '*ache*' }
$tempFolders = $safeFolders | Where-Object { $_.Path -like '*emp*' -or $_.Path -like '*.tmp*' }
$logFolders = $safeFolders | Where-Object { $_.Path -like '*log*' }
$shaderFolders = $safeFolders | Where-Object { $_.Path -like '*shader*' -or $_.Path -like '*Gpu*' }
$codeFolders = $safeFolders | Where-Object { $_.Path -like '*code*' }
$pythonFolders = $safeFolders | Where-Object { $_.Path -like '*pycache*' -or $_.Path -like '*discovery_cache*' }

Write-Host "Cache folders: $($cacheFolders.Count) = $([math]::Round(($cacheFolders | Measure-Object -Property Size -Sum).Sum / 1GB, 2))GB"
Write-Host "Temp folders: $($tempFolders.Count) = $([math]::Round(($tempFolders | Measure-Object -Property Size -Sum).Sum / 1GB, 2))GB"
Write-Host "Log folders: $($logFolders.Count) = $([math]::Round(($logFolders | Measure-Object -Property Size -Sum).Sum / 1GB, 2))GB"
Write-Host "Shader caches: $($shaderFolders.Count) = $([math]::Round(($shaderFolders | Measure-Object -Property Size -Sum).Sum / 1GB, 2))GB"
Write-Host "Code caches: $($codeFolders.Count) = $([math]::Round(($codeFolders | Measure-Object -Property Size -Sum).Sum / 1GB, 2))GB"
Write-Host "Python caches: $($pythonFolders.Count) = $([math]::Round(($pythonFolders | Measure-Object -Property Size -Sum).Sum / 1GB, 2))GB`n"

# Export as PowerShell array
if ($ExportPowerShell) {
    $outputFile = "$env:USERPROFILE\.claude\safe-folders-final.txt"
    Write-Host "$yellow[EXPORT] Saving to: $outputFile$reset"

    $safeFolders | ForEach-Object { "'$($_.Path)'," } | Set-Content $outputFile
    Write-Host "Exported $($safeFolders.Count) safe folders as PowerShell array`n"

    Write-Host "$green[READY] Copy these paths into ccsizes-cleanup.ps1 cleanupFolders array$reset"
}
