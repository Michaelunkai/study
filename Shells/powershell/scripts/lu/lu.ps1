<#
.SYNOPSIS
    lu - PowerShell utility script
.NOTES
    Original function: lu
    Extracted: 2026-02-19 20:20
#>
Get-CimInstance -Namespace root/WMI -ClassName WmiMonitorBrightnessMethods |
        Invoke-CimMethod -MethodName WmiSetBrightness -Arguments @{Brightness=100; Timeout=1}
