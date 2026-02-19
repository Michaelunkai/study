<#
.SYNOPSIS
    rmrust - PowerShell utility script
.NOTES
    Original function: rmrust
    Extracted: 2026-02-19 20:20
#>
# COMPLETE REMOVAL ONE-LINER (Run this to uninstall everything)
Remove-Item -Recurse -Force "$env:USERPROFILE\.pkgx" -ErrorAction SilentlyContinue; Remove-Item -Recurse -Force "$env:USERPROFILE\.cargo" -ErrorAction SilentlyContinue; Remove-Item -Recurse -Force "$env:USERPROFILE\.rustup" -ErrorAction SilentlyContinue; $userPath = [Environment]::GetEnvironmentVariable("PATH", "User"); $userPath = ($userPath -split ';' | Where-Object { $_ -notmatch '\.pkgx|\.cargo|\.rustup' }) -join ';'; [Environment]::SetEnvironmentVariable("PATH", $userPath, "User"); Write-Host "pkgx and Rust completely removed. Restart PowerShell." -ForegroundColor Green
