<#
.SYNOPSIS
    getorch - PowerShell utility script
.NOTES
    Original function: getorch
    Extracted: 2026-02-19 20:20
#>
param (
        [string]$CudaVersion = "cu111"
    )
    Invoke-Expression $pipInstallCommand
    Invoke-Expression $pythonCheckCommand
