<#
.SYNOPSIS
    gnetpreview - PowerShell utility script
.NOTES
    Original function: gnetpreview
    Extracted: 2026-02-19 20:20
#>
winget install Microsoft.DotNet.SDK.Preview --force;
    winget install Microsoft.DotNet.DesktopRuntime.Preview --force;
    winget install Microsoft.DotNet.AspNetCore.Preview --force
