<#
.SYNOPSIS
    time - PowerShell utility script
.NOTES
    Original function: time
    Extracted: 2026-02-19 20:20
#>
param (
        [ScriptBlock]$Command
    )
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    & $Command
    $sw.Stop()
    Write-Output "Finished in $($sw.Elapsed.TotalSeconds) seconds"
