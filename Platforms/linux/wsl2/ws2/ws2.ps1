<#
.SYNOPSIS
    ws2 - PowerShell utility script
.NOTES
    Original function: ws2
    Extracted: 2026-02-19 20:20
#>
param (
        [string]$Command
    )
    wsl --distribution ubuntu --user root -- bash -lic "$Command";     wsl --distribution ubuntu2 --user root -- bash -lic "$Command"
