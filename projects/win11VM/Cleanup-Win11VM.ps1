[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [string]$Name = 'Codex-Win11-Ready',
    [switch]$Force,
    [switch]$KeepLogs
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

if ($PSVersionTable.PSEdition -ne 'Desktop') {
    $ps5 = Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0\powershell.exe'
    $args = @('-NoProfile','-ExecutionPolicy','Bypass','-File',$PSCommandPath,'-Name',$Name)
    if ($Force) { $args += '-Force' }
    if ($KeepLogs) { $args += '-KeepLogs' }
    & $ps5 @args
    exit $LASTEXITCODE
}

$projectRoot = $PSScriptRoot
$vmRoot = Join-Path $projectRoot 'vm'
$logsRoot = Join-Path $projectRoot 'logs'
$stateRoot = Join-Path $projectRoot 'state'

if ([string]::IsNullOrWhiteSpace($env:COMPUTERNAME)) {
    $env:COMPUTERNAME = [System.Net.Dns]::GetHostName()
}
$moduleRoot = Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0\Modules'
if ($env:PSModulePath -notlike "*$moduleRoot*") {
    $env:PSModulePath = $moduleRoot + ';' + $env:PSModulePath
}
Import-Module Hyper-V -ErrorAction Stop

$targets = @()
if (Test-Path -LiteralPath $vmRoot) { $targets += $vmRoot }
if (-not $KeepLogs -and (Test-Path -LiteralPath $logsRoot)) { $targets += $logsRoot }
if (Test-Path -LiteralPath $stateRoot) { $targets += $stateRoot }

function Get-DirectoryFileBytes {
    param([Parameter(Mandatory=$true)][string]$Path)

    $measurement = Get-ChildItem -LiteralPath $Path -Recurse -Force -ErrorAction SilentlyContinue |
        Where-Object { -not $_.PSIsContainer } |
        Measure-Object -Property Length -Sum
    if ($null -eq $measurement -or $null -eq $measurement.Sum) {
        return 0
    }
    return [int64]$measurement.Sum
}

$beforeBytes = 0
foreach ($target in $targets) {
    $beforeBytes += Get-DirectoryFileBytes -Path $target
}

$vm = Get-VM -Name $Name -ErrorAction SilentlyContinue
if ($vm) {
    if ($vm.State -ne 'Off') {
        if ($PSCmdlet.ShouldProcess($Name, 'Stop VM before cleanup')) {
            if ($Force) {
                Stop-VM -Name $Name -TurnOff -Force -ErrorAction Stop
            } else {
                Stop-VM -Name $Name -Shutdown -ErrorAction SilentlyContinue
                $deadline = (Get-Date).AddSeconds(45)
                do {
                    Start-Sleep -Seconds 3
                    $vm = Get-VM -Name $Name -ErrorAction SilentlyContinue
                } while ($vm -and $vm.State -ne 'Off' -and (Get-Date) -lt $deadline)
                $vm = Get-VM -Name $Name -ErrorAction SilentlyContinue
                if ($vm -and $vm.State -ne 'Off') {
                    Stop-VM -Name $Name -TurnOff -Force -ErrorAction Stop
                }
            }
        }
    }
    if ($PSCmdlet.ShouldProcess($Name, 'Remove VM registration')) {
        Remove-VM -Name $Name -Force -ErrorAction Stop
    }
}

foreach ($target in $targets) {
    $resolved = Resolve-Path -LiteralPath $target -ErrorAction SilentlyContinue
    if (-not $resolved) { continue }
    $full = $resolved.ProviderPath
    if (-not $full.StartsWith($projectRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to remove path outside project: $full"
    }
    if ($PSCmdlet.ShouldProcess($full, 'Remove generated project artifact directory')) {
        Remove-Item -LiteralPath $full -Recurse -Force -ErrorAction Stop
    }
}

$afterBytes = 0
foreach ($target in $targets) {
    if (Test-Path -LiteralPath $target) {
        $afterBytes += Get-DirectoryFileBytes -Path $target
    }
}

[pscustomobject]@{
    VMName = $Name
    RemovedVMRegistration = [bool]$vm
    RemovedArtifactBytes = [int64]($beforeBytes - $afterBytes)
    RemovedArtifactMB = [math]::Round(($beforeBytes - $afterBytes) / 1MB, 2)
    KeptParentReplica = 'F:\Downloads\VMREplica\VHDX\VMReplica-CurrentWindows.VHDX'
}
