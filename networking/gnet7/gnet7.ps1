<#
.SYNOPSIS
    gnet7 - PowerShell utility script
.NOTES
    Original function: gnet7
    Extracted: 2026-02-19 20:20
#>
winget install Microsoft.DotNet.SDK.7 --force;
    winget install Microsoft.DotNet.DesktopRuntime.7 --force;
    winget install Microsoft.DotNet.AspNetCore.7 --force
