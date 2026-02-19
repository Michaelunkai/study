<#
.SYNOPSIS
    gnet5 - PowerShell utility script
.NOTES
    Original function: gnet5
    Extracted: 2026-02-19 20:20
#>
winget install Microsoft.DotNet.SDK.5 --force;
    winget install Microsoft.DotNet.DesktopRuntime.5 --force;
    winget install Microsoft.DotNet.AspNetCore.5 --force
