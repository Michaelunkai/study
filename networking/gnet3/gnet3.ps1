<#
.SYNOPSIS
    gnet3 - PowerShell utility script
.NOTES
    Original function: gnet3
    Extracted: 2026-02-19 20:20
#>
winget install Microsoft.DotNet.SDK.3_1 --force;
    winget install Microsoft.DotNet.DesktopRuntime.3_1 --force;
    winget install Microsoft.DotNet.AspNetCore.3_1 --force
