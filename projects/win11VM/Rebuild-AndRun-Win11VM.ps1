[CmdletBinding()]
param(
    [switch]$CleanFirst,
    [switch]$OpenAllDrives
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

if ($CleanFirst) {
    & (Join-Path $PSScriptRoot 'Cleanup-Win11VM.ps1') -Force
}

& (Join-Path $PSScriptRoot 'Start-Win11VM.ps1')

if ($OpenAllDrives) {
    & (Join-Path $PSScriptRoot 'Open-Win11VM-AllDrives.ps1')
}
