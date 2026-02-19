<#
.SYNOPSIS
    backupapps - PowerShell utility script
.NOTES
    Original function: backupapps
    Extracted: 2026-02-19 20:20
#>
$ErrorActionPreference = "Stop"
    Set-Location -Path "F:\backup\windowsapps"
    built michadockermisha/backup:windowsapps
