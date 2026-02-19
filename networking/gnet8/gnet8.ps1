<#
.SYNOPSIS
    gnet8 - PowerShell utility script
.NOTES
    Original function: gnet8
    Extracted: 2026-02-19 20:20
#>
winget install Microsoft.DotNet.SDK.8 --force;
    winget install Microsoft.DotNet.DesktopRuntime.8 --force;
    winget install Microsoft.DotNet.AspNetCore.8 --force
