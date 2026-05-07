[CmdletBinding()]
param(
    [string]$Name = 'Codex-Win11-Ready'
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

if ($PSVersionTable.PSEdition -ne 'Desktop') {
    $ps5 = Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0\powershell.exe'
    & $ps5 -NoProfile -ExecutionPolicy Bypass -File $PSCommandPath -Name $Name
    exit $LASTEXITCODE
}

. (Join-Path $PSScriptRoot 'scripts\Win11VmHarness.ps1')

$result = Test-Win11ReadyVm -Name $Name -ProjectRoot $PSScriptRoot
if ($result.Success) {
    exit 0
}

exit 1
