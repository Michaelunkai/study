<#
.SYNOPSIS
    wingup - PowerShell utility script
.DESCRIPTION
    Extracted from PowerShell profile for modular organization
.NOTES
    Original function: wingup
    Location: F:\study\Shells\powershell\scripts\wingup\wingup.ps1
    Extracted: 2026-02-19 20:05
#>
param()
    # Force upgrade ALL packages with fallbacks for Edge/Chrome/Firefox failures
    $ProgressPreference = 'SilentlyContinue'
    $ErrorActionPreference = 'Continue'

    function local:Get-WingetUpgrades {
        $raw = winget upgrade --include-unknown 2>&1 | Out-String
        $lines = $raw -split "`r?`n"
        $headerLine = ""
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match '^-{20,}') { $headerLine = $lines[$i - 1]; break }
        }
        if (-not $headerLine -or $headerLine -notmatch 'Id') { return @() }
        $idCol = $headerLine.IndexOf('Id')
        $verCol = $headerLine.IndexOf('Version')
        $availCol = $headerLine.IndexOf('Available')
        $srcCol = $headerLine.IndexOf('Source')
        if ($idCol -lt 0 -or $verCol -lt 0 -or $availCol -lt 0 -or $srcCol -lt 0) { return @() }
        $pkgs = @()
        $ds = $false
        foreach ($l in $lines) {
            if ($l -match '^-{20,}') { $ds = $true; continue }
            if ($ds) {
                if ($l -match '^\d+ upgrades? available') { break }
                if ($l.Trim() -eq '' -or $l.Length -lt $srcCol) { continue }
                $pkgs += @{ Name=$l.Substring(0,$idCol).Trim(); Id=$l.Substring($idCol,$verCol-$idCol).Trim(); Current=$l.Substring($verCol,$availCol-$verCol).Trim(); Available=$l.Substring($availCol,$srcCol-$availCol).Trim() }
            }
        }
        return $pkgs
    }

    Write-Host "`n=== WINGUP - Force Upgrade All ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "[1/4] Checking for available upgrades..." -ForegroundColor Yellow
    $packages = @(local:Get-WingetUpgrades)

    if ($packages.Count -eq 0) {
        Write-Host "`n  No upgrades available - everything is up to date!" -ForegroundColor Green
        Write-Host "`n=== WINGUP Complete ===" -ForegroundColor Cyan; return
    }

    Write-Host "  Found $($packages.Count) package(s):" -ForegroundColor White
    foreach ($p in $packages) { Write-Host "    $($p.Name) ($($p.Id)): $($p.Current) -> $($p.Available)" -ForegroundColor Gray }

    Write-Host "`n[2/4] Running winget upgrade --all..." -ForegroundColor Yellow
    winget upgrade --all --include-unknown --silent --accept-source-agreements --accept-package-agreements --force 2>&1 | Out-String | ForEach-Object { ($_ -split "`r?`n" | Where-Object { $_ -match '\S' -and $_ -notmatch '^\s*[-\\|/]\s*$' }) -join "`n" } | Write-Host

    Write-Host "`n[3/4] Checking for failures..." -ForegroundColor Yellow
    Start-Sleep -Seconds 3
    $remaining = @(local:Get-WingetUpgrades)
    $failed = @()
    foreach ($p in $packages) { foreach ($r in $remaining) { if ($r.Id -eq $p.Id) { $failed += $p; break } } }

    if ($failed.Count -eq 0) { Write-Host "  All upgraded!" -ForegroundColor Green }
    else {
        Write-Host "  $($failed.Count) need fallback:" -ForegroundColor Yellow
        foreach ($p in $failed) { Write-Host "    - $($p.Name) ($($p.Id))" -ForegroundColor Yellow }
    }

    foreach ($p in $failed) {
        Write-Host ""
        switch -Wildcard ($p.Id) {
            'Microsoft.Edge*' {
                Write-Host "  [Edge] Trying direct methods..." -ForegroundColor Cyan
                $ok = $false
                # Method 1: EdgeUpdate
                $eu = "${env:ProgramFiles(x86)}\Microsoft\EdgeUpdate\MicrosoftEdgeUpdate.exe"
                if (-not (Test-Path $eu)) { $eu = "$env:LocalAppData\Microsoft\EdgeUpdate\MicrosoftEdgeUpdate.exe" }
                if ((Test-Path $eu) -and -not $ok) {
                    Write-Host "    EdgeUpdate service..." -ForegroundColor Gray
                    Start-Process $eu -ArgumentList "/silent /install appguid={56EB18F8-B008-4CBD-B6D2-8C97FE7E9062}&appname=Microsoft%20Edge&needsadmin=prefers" -Wait -NoNewWindow -ErrorAction SilentlyContinue
                    Start-Sleep -Seconds 10
                    if (-not (@(local:Get-WingetUpgrades) | Where-Object { $_.Id -like 'Microsoft.Edge*' })) { Write-Host "    Edge updated via EdgeUpdate!" -ForegroundColor Green; $ok = $true }
                }
                # Method 2: Direct installer
                if (-not $ok) {
                    Write-Host "    Direct installer..." -ForegroundColor Gray
                    $ei = "$env:TEMP\MicrosoftEdgeSetup.exe"
                    try {
                        Invoke-WebRequest -Uri "https://go.microsoft.com/fwlink/?linkid=2108834&Channel=Stable&language=en&brand=M100" -OutFile $ei -UseBasicParsing
                        Start-Process $ei -ArgumentList "--msedge --channel=stable --system-level --silent --force-install" -Wait -NoNewWindow
                        Start-Sleep -Seconds 15; Remove-Item $ei -Force -ErrorAction SilentlyContinue
                        if (-not (@(local:Get-WingetUpgrades) | Where-Object { $_.Id -like 'Microsoft.Edge*' })) { Write-Host "    Edge updated!" -ForegroundColor Green; $ok = $true }
                    } catch { Write-Host "    Failed: $($_.Exception.Message)" -ForegroundColor Red }
                }
                # Method 3: Scheduled task
                if (-not $ok) {
                    Write-Host "    Edge update task..." -ForegroundColor Gray
                    schtasks /Run /TN "\MicrosoftEdgeUpdateTaskMachineCore" 2>&1 | Out-Null
                    Start-Sleep -Seconds 20
                    if (-not (@(local:Get-WingetUpgrades) | Where-Object { $_.Id -like 'Microsoft.Edge*' })) { Write-Host "    Edge updated!" -ForegroundColor Green; $ok = $true }
                }
                # Method 4: winget install --force
                if (-not $ok) {
                    Write-Host "    winget install --force..." -ForegroundColor Gray
                    winget install --id Microsoft.Edge --force --silent --accept-source-agreements --accept-package-agreements 2>&1 | Out-Null
                    Start-Sleep -Seconds 10
                    if (-not (@(local:Get-WingetUpgrades) | Where-Object { $_.Id -like 'Microsoft.Edge*' })) { Write-Host "    Edge fixed!" -ForegroundColor Green; $ok = $true }
                }
                # Method 5: Pin to suppress
                if (-not $ok) {
                    Write-Host "    Pinning Edge (will self-update in background)..." -ForegroundColor Yellow
                    winget pin add --id Microsoft.Edge --blocking 2>&1 | Out-Null; $ok = $true
                }
            }
            'Google.Chrome*' {
                Write-Host "  [Chrome] Direct installer..." -ForegroundColor Cyan
                try {
                    $o = "$env:TEMP\chrome_installer.exe"
                    Invoke-WebRequest -Uri 'https://dl.google.com/chrome/install/latest/chrome_installer.exe' -OutFile $o -UseBasicParsing
                    Start-Process $o -ArgumentList '/silent','/install' -Wait
                    Remove-Item $o -Force -ErrorAction SilentlyContinue
                    Write-Host "    Chrome updated!" -ForegroundColor Green
                } catch { Write-Host "    Chrome failed: $($_.Exception.Message)" -ForegroundColor Red }
            }
            'Mozilla.Firefox*' {
                Write-Host "  [Firefox] Direct installer..." -ForegroundColor Cyan
                try {
                    $o = "$env:TEMP\firefox_installer.exe"
                    Invoke-WebRequest -Uri "https://download.mozilla.org/?product=firefox-latest&os=win64&lang=en-US" -OutFile $o -UseBasicParsing
                    Start-Process $o -ArgumentList '-ms' -Wait
                    Remove-Item $o -Force -ErrorAction SilentlyContinue
                    Write-Host "    Firefox updated!" -ForegroundColor Green
                } catch { Write-Host "    Firefox failed: $($_.Exception.Message)" -ForegroundColor Red }
            }
            default {
                Write-Host "  [$($p.Name)] Retrying..." -ForegroundColor Cyan
                $r = winget upgrade --id $p.Id --force --silent --accept-source-agreements --accept-package-agreements 2>&1 | Out-String
                if ($r -match 'Successfully installed') { Write-Host "    $($p.Name) upgraded!" -ForegroundColor Green }
                else {
                    winget uninstall --id $p.Id --silent 2>&1 | Out-Null; Start-Sleep 3
                    $r2 = winget install --id $p.Id --force --silent --accept-source-agreements --accept-package-agreements 2>&1 | Out-String
                    if ($r2 -match 'Successfully installed') { Write-Host "    $($p.Name) fixed!" -ForegroundColor Green }
                    else { Write-Host "    $($p.Name): Auto-upgrade failed." -ForegroundColor Red }
                }
            }
        }
    }

    # Final check + unpin resolved Edge
    Write-Host "`n[4/4] Final verification..." -ForegroundColor Yellow
    Start-Sleep 3
    $pinList = winget pin list 2>&1 | Out-String
    if ($pinList -match 'Microsoft.Edge') {
        if (-not (@(local:Get-WingetUpgrades) | Where-Object { $_.Id -like 'Microsoft.Edge*' })) {
            winget pin remove --id Microsoft.Edge 2>&1 | Out-Null
        }
    }
    $final = @(local:Get-WingetUpgrades)
    if ($final.Count -eq 0) { Write-Host "`n  ALL PACKAGES UP TO DATE!" -ForegroundColor Green }
    else { Write-Host "`n  $($final.Count) still pending:" -ForegroundColor Yellow; foreach ($f in $final) { Write-Host "    $($f.Name) ($($f.Id))" -ForegroundColor Gray } }
    Write-Host "`n=== WINGUP Complete ===" -ForegroundColor Cyan
    Write-Host ""
