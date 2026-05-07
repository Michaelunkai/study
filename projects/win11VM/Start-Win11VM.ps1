[CmdletBinding()]
param(
    [string]$Name = 'Codex-Win11-Ready',
    [string]$ParentVhd = '',
    [string]$VmRoot = '',
    [string]$SwitchName = 'Codex External Ethernet',
    [int64]$MemoryStartupBytes = 8GB,
    [int]$ProcessorCount = 4,
    [switch]$Preflight,
    [switch]$NoRelaunch
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($VmRoot)) {
    $VmRoot = Join-Path $PSScriptRoot 'vm'
}

if (-not $NoRelaunch -and $PSVersionTable.PSEdition -ne 'Desktop') {
    $ps5 = Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0\powershell.exe'
    if (Test-Path -LiteralPath $ps5) {
        $args = @(
            '-NoProfile',
            '-ExecutionPolicy', 'Bypass',
            '-File', $PSCommandPath,
            '-Name', $Name,
            '-VmRoot', $VmRoot,
            '-SwitchName', $SwitchName,
            '-MemoryStartupBytes', $MemoryStartupBytes,
            '-ProcessorCount', $ProcessorCount,
            '-NoRelaunch'
        )
        if (-not [string]::IsNullOrWhiteSpace($ParentVhd)) {
            $args += @('-ParentVhd', $ParentVhd)
        }
        if ($Preflight) { $args += '-Preflight' }
        & $ps5 @args
        exit $LASTEXITCODE
    }
}

. (Join-Path $PSScriptRoot 'scripts\Win11VmHarness.ps1')

$result = Start-Win11ReadyVm `
    -Name $Name `
    -ParentVhd $ParentVhd `
    -VmRoot $VmRoot `
    -SwitchName $SwitchName `
    -MemoryStartupBytes $MemoryStartupBytes `
    -ProcessorCount $ProcessorCount `
    -Preflight:$Preflight

if ($result.Success) {
    exit 0
}

exit 1
