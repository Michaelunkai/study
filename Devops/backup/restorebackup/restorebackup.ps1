<#
.SYNOPSIS
    restorebackup - PowerShell utility script
.NOTES
    Original function: restorebackup
    Extracted: 2026-02-19 20:20
#>
Set-Location -Path "F:\";
    mkdir backup;
    restoreapps;
    restorelinux
