<#
.SYNOPSIS
    waitit - PowerShell utility script
.NOTES
    Original function: waitit
    Extracted: 2026-02-19 20:20
#>
param(
        [Parameter(Position=0, Mandatory=$true)]
        [string]$Command,
        [Parameter(Position=1, Mandatory=$false)]
        [int]$Seconds = 10
    )
    while($true) {
        Clear-Host
        Get-Date
        Invoke-Expression $Command
        Start-Sleep $Seconds
    }
