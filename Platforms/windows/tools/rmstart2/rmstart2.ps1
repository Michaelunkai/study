<#
.SYNOPSIS
    rmstart2 - PowerShell utility script
.NOTES
    Original function: rmstart2
    Extracted: 2026-02-19 20:20
#>
param([string]$path)
    $taskName = "AutoStart_" + [IO.Path]::GetFileNameWithoutExtension($path)
    SCHTASKS /Delete /TN $taskName /F | Out-Null
    Write-Host "??? Removed startup task for '$path' (task: $taskName)"
