<#
.SYNOPSIS
    unfixc - PowerShell utility script
.NOTES
    Original function: unfixc
    Extracted: 2026-02-19 20:20
#>
# Cancel scheduled chkdsk - reset BootExecute to standard
    $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager"
    Set-ItemProperty -Path $regPath -Name BootExecute -Value @("autocheck autochk *") -Type MultiString
    Write-Host "? Scheduled chkdsk cancelled. Normal boot restored." -ForegroundColor Green
