#Requires -RunAsAdministrator
# Intelligent Folder Filter V2 - Smart nested path handling

param(
    [int]$MinSizeMB = 0.5
)

$cyan = [char]27 + '[96m';
$green = [char]27 + '[92m';
$yellow = [char]27 + '[93m';
$red = [char]27 + '[91m';
$reset = [char]27 + '[0m'

Write-Host "$cyan=== SMART FOLDER FILTER V2 ===$reset`n"

# Load discovered folders
$discoveredFile = "$env:USERPROFILE\.claude\discovered-folders.txt"
$allFolders = @()
Get-Content $discoveredFile | ForEach-Object {
    $path = $_ -replace "^'|',$", ""
    if ($path) { $allFolders += $path }
}

Write-Host "Processing $($allFolders.Count) discovered folders`n"

# ABSOLUTELY UNSAFE - Never include these root paths
$completelyUnsafePaths = @(
    'C:\Users\*\Documents',
    'C:\Users\*\Downloads',
    'C:\Users\*\Desktop',
    'C:\Users\*\Pictures',
    'C:\Users\*\Music',
    'C:\Users\*\Videos',
    'C:\Users\*\Favorites',
    'C:\Program Files\*',
    'C:\Program Files (x86)\*',
    'C:\Recovery',
    'C:\$Recycle.Bin',
    'C:\ProgramData\Microsoft\Windows\Containers'
)

function IsCompletelyUnsafe {
    param([string]$path)
    foreach ($unsafe in $completelyUnsafePaths) {
        if ($path -like "$unsafe*") { return $true }
    }
    return $false
}

# Smart validation: check folder name and parent context
function IsSafeFolder {
    param([string]$path)

    $folderName = Split-Path $path -Leaf
    $folderNameLower = $folderName.ToLower()

    # Extract parent folder name
    $parent = Split-Path $path -Parent
    $parentName = if ($parent) { Split-Path $parent -Leaf } else { "" }

    # TIER 1: Folder name clearly indicates cache/temp/log
    $cacheIndicators = @('cache', 'temp', 'tmp', 'log', 'prefetch', 'downloads', 'shader', 'gpu', 'cef', 'crx', 'dawn', 'graphite')
    foreach ($indicator in $cacheIndicators) {
        if ($folderNameLower -like "*$indicator*") {
            # But: if folder is "node_modules" alone, skip it (unless it contains cache subpath)
            if ($folderNameLower -eq 'node_modules' -and -not ($path -like '*node_modules*cache*')) {
                return $false
            }
            # If it's a known cache/temp folder name, it's safe
            return $true
        }
    }

    # TIER 2: Special folders that are always safe (even without cache in name)
    if ($folderNameLower -in @('__pycache__', 'pycache', 'site-packages\__pycache__')) { return $true }

    # TIER 3: Discovery caches are safe
    if ($folderNameLower -like '*discovery*') { return $true }

    # TIER 4: GPU/Shader related
    if ($folderNameLower -like '*gpucache*' -or $folderNameLower -like '*shadercache*' -or $folderNameLower -like '*grcache*') { return $true }

    # TIER 5: CEF (Chromium Embedded Framework) caches are safe
    if ($folderNameLower -like '*cef*' -and $path -like '*cache*') { return $true }

    # TIER 6: Service worker caches are safe
    if ($path -like '*service worker*cache*' -or $path -like '*serviceworker*cache*') { return $true }

    # TIER 7: Windows system temp/logs (but not core system)
    if ($path -like 'C:\Windows\Temp*' -or $path -like 'C:\Windows\Logs*' -or $path -like 'C:\Windows\SystemTemp*') { return $true }
    if ($path -like 'C:\Windows\*Cache*' -and -not ($path -like 'C:\Windows\System32*' -and -not ($path -like '*cache*'))) { return $true }

    # TIER 8: Containers and Docker cache files
    if ($path -like '*docker*cache*' -or $path -like '*container*cache*') { return $true }

    # TIER 9: Font cache
    if ($path -like '*fontcache*') { return $true }

    # TIER 10: Application-specific safe caches
    $safeAppCaches = @('wemod', 'todoist', 'obsidian', 'wand', 'ollama', 'ascendara', 'telegram', 'open-whispr')
    foreach ($app in $safeAppCaches) {
        if ($path -like "*$app*cache*" -or $path -like "*$app*temp*" -or $path -like "*$app*log*") {
            return $true
        }
    }

    # TIER 11: npm/pip/pnpm caches
    if ($path -like '*npm-cache*' -or $path -like '*pnpm*cache*' -or $path -like '*\\.cache\*' -or $path -like '*\.cache\*') {
        # But not if it's inside node_modules and not a cache folder
        if ($path -like '*node_modules*' -and -not ($path -like '*cache*')) { return $false }
        return $true
    }

    # TIER 12: Python caches (but NOT site-packages root, only __pycache__ or discovery)
    if ($path -like '*python*' -and ($path -like '*__pycache__*' -or $path -like '*discovery_cache*' -or $path -like '*\.cache\*')) {
        return $true
    }

    # TIER 13: Package managers
    if ($path -like '*\.nuget\*cache*' -or $path -like '*maven*cache*' -or $path -like '*gradle*cache*' -or $path -like '*composer*cache*') { return $true }

    # TIER 14: Chrome/Chromium/Edge (always safe - just caches)
    if ($path -like '*chrome*' -and ($path -like '*cache*' -or $path -like '*code*' -or $path -like '*gpu*' -or $path -like '*shader*' -or $path -like '*download*')) {
        return $true
    }

    # TIER 15: Browser service workers
    if ($path -like '*service*worker*' -and $path -like '*script*') { return $true }

    return $false
}

$safeFolders = @()
$filtered = 0

Write-Host "$yellow[FILTERING] Validating folders using smart logic...$reset`n"

$allFolders | ForEach-Object {
    $path = $_

    # Skip completely unsafe root paths
    if (IsCompletelyUnsafe $path) {
        $filtered += 1
        return
    }

    # Check if it's a safe folder
    if (IsSafeFolder $path) {
        $size = 0
        try {
            $size = (Get-ChildItem $path -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
        } catch {}

        $sizeMB = [math]::Round($size / 1MB, 2)
        if ($sizeMB -ge $MinSizeMB) {
            $safeFolders += @{
                Path = $path
                Size = $size
                SizeMB = $sizeMB
            }
        }
    }
}

Write-Host "$green[COMPLETE] Smart filtering finished!$reset`n"

$safeFolders = $safeFolders | Sort-Object { $_.SizeMB } -Descending

Write-Host "Results:" -ForegroundColor Cyan
Write-Host "  Original: $($allFolders.Count)"
Write-Host "  Safe folders found: $($safeFolders.Count)"
Write-Host "  Total space: $([math]::Round(($safeFolders | Measure-Object -Property Size -Sum).Sum / 1GB, 2))GB`n"

Write-Host "$cyan=== TOP 100 SAFE CLEANABLE FOLDERS ===$reset`n"
$safeFolders | Select-Object -First 100 | ForEach-Object {
    Write-Host "$($_.SizeMB)MB : $($_.Path)" -ForegroundColor White
}

# Export
$outputFile = "$env:USERPROFILE\.claude\safe-folders-final.txt"
Write-Host "`n$yellow[EXPORT] Saving to: $outputFile$reset"
$safeFolders | ForEach-Object { "'$($_.Path)'," } | Set-Content $outputFile

Write-Host "$green[READY] $($safeFolders.Count) safe folders exported$reset"
Write-Host "Next: Update ccsizes-cleanup.ps1 with these paths"
