<#
.SYNOPSIS
    gnet9 - PowerShell utility script
.NOTES
    Original function: gnet9
    Extracted: 2026-02-19 20:20
#>
winget install Microsoft.DotNet.SDK.9 --force;
    winget install Microsoft.DotNet.DesktopRuntime.9 --force;
    winget install Microsoft.DotNet.AspNetCore.9 --force
