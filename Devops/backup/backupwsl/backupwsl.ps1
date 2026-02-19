<#
.SYNOPSIS
    backupwsl - PowerShell utility script
.NOTES
    Original function: backupwsl
    Extracted: 2026-02-19 20:20
#>
$ErrorActionPreference = "Stop"
    Set-Location -Path "F:\backup\linux\wsl"
    built michadockermisha/backup:wsl
