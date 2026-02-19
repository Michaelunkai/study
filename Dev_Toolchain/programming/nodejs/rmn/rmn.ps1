<#
.SYNOPSIS
    rmn - PowerShell utility script
.NOTES
    Original function: rmn
    Extracted: 2026-02-19 20:20
#>
param(
        [string]$filename
    )
    # Remove the file, forcing removal even if it's read-only
    Remove-Item -Path $filename -Force
    # Open the file in nano editor
    nano $filename
