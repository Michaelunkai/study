<#
.SYNOPSIS
    Copy - PowerShell utility script
.NOTES
    Original function: Copy
    Extracted: 2026-02-19 20:20
#>
param (
        [string[]]$InputObject
    )
    $InputObject -join "`n" | Set-Clipboard
    Write-Output "Copied to clipboard."
