[CmdletBinding()]
param(
    [int]$TimeoutSec = 210,
    [switch]$CheckOnly,
    [switch]$Quiet,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

. 'F:\study\AI_ML\AI_and_Machine_Learning\Artificial_Intelligence\openclaw\scripts\Resolve-OpenClawPaths.ps1'
$paths = Set-OpenClawProcessEnvironment

$truthScript = Join-Path $paths.RepoRoot 'scripts\Test-OpenClawCurrentTruth.ps1'
$wscriptExe = Join-Path $env:SystemRoot 'System32\wscript.exe'
$trayVbs = $paths.TrayLauncherVbs
$managerExe = $paths.TrayManagerExe
$runtimeScript = $paths.RuntimeDistEntrypoint
$gatewayPort = 18789

function Write-RestartStatus {
    param(
        [Parameter(Mandatory = $true)][string]$Message,
        [ConsoleColor]$Color = [ConsoleColor]::DarkGray
    )

    if (-not $Quiet) {
        Write-Host $Message -ForegroundColor $Color
    }
}

function Get-OpenClawTruth {
    try {
        $json = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $truthScript
        if ([string]::IsNullOrWhiteSpace($json)) {
            return $null
        }
        return ($json | ConvertFrom-Json)
    } catch {
        return $null
    }
}

function Test-OpenClawHealthy {
    param($Truth)

    if ($null -eq $Truth) {
        return $false
    }

    return (
        $Truth.authorityPassed -and
        $Truth.tcpLiveness -and
        $Truth.managerCount -eq 1 -and
        $Truth.gatewayCount -eq 1 -and
        $Truth.trayOwnedGateway -and
        -not $Truth.scheduledGatewayTaskEnabled
    )
}

function Wait-OpenClawHealthy {
    param([int]$MaxSeconds)

    $deadline = (Get-Date).AddSeconds([Math]::Max(5, $MaxSeconds))
    $lastTruth = $null
    do {
        $lastTruth = Get-OpenClawTruth
        if (Test-OpenClawHealthy -Truth $lastTruth) {
            return [pscustomobject]@{
                Ok = $true
                Truth = $lastTruth
            }
        }

        Start-Sleep -Milliseconds 1500
    } while ((Get-Date) -lt $deadline)

    return [pscustomobject]@{
        Ok = $false
        Truth = $lastTruth
    }
}

function Get-ManagedProcesses {
    $all = @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue)
    return [pscustomobject]@{
        Tray = @($all | Where-Object {
            $_.Name -eq 'wscript.exe' -and
            $_.CommandLine -and
            $_.CommandLine -match [regex]::Escape($trayVbs)
        })
        Manager = @($all | Where-Object {
            $_.Name -eq 'ClawdBotManager.exe' -and
            $_.ExecutablePath -eq $managerExe
        })
        Gateway = @($all | Where-Object {
            $_.Name -eq 'node.exe' -and
            $_.CommandLine -and
            $_.CommandLine -match [regex]::Escape($runtimeScript) -and
            $_.CommandLine -match ('gateway run --port {0}' -f [regex]::Escape([string]$gatewayPort))
        })
    }
}

function Stop-OpenClawManagedProcesses {
    $processes = Get-ManagedProcesses
    $ordered = @(
        $processes.Manager
        $processes.Gateway
        $processes.Tray
    ) | ForEach-Object { $_ } | Where-Object { $_ }

    foreach ($process in $ordered) {
        try {
            Stop-Process -Id $process.ProcessId -Force -ErrorAction SilentlyContinue
        } catch {
        }
    }
}

function Start-OpenClawTrayHidden {
    if (-not (Test-Path -LiteralPath $trayVbs)) {
        throw "Tray launcher not found: $trayVbs"
    }
    if (-not (Test-Path -LiteralPath $wscriptExe)) {
        throw "wscript.exe not found: $wscriptExe"
    }

    Start-Process -FilePath $wscriptExe -ArgumentList '//B','//Nologo',"`"$trayVbs`"" -WindowStyle Hidden | Out-Null
}

$initialTruth = Get-OpenClawTruth
if ($CheckOnly) {
    $check = Wait-OpenClawHealthy -MaxSeconds $TimeoutSec
    if ($check.Ok) {
        Write-RestartStatus 'OpenClaw tray-managed runtime is healthy.' Green
        return $true
    }

    Write-RestartStatus 'OpenClaw tray-managed runtime is not healthy.' Yellow
    return $false
}

if ((-not $Force) -and (Test-OpenClawHealthy -Truth $initialTruth)) {
    Write-RestartStatus 'OpenClaw tray-managed runtime already healthy.' Green
    return $true
}

Write-RestartStatus 'Restarting OpenClaw tray-managed runtime...' Cyan
Stop-OpenClawManagedProcesses
Start-Sleep -Seconds 2
Start-OpenClawTrayHidden

$result = Wait-OpenClawHealthy -MaxSeconds $TimeoutSec
if ($result.Ok) {
    $truth = $result.Truth
    $managerPid = ($truth.managerPids | Select-Object -First 1)
    if ($null -eq $managerPid -or [string]::IsNullOrWhiteSpace([string]$managerPid)) {
        $managerPid = '?'
    }
    $gatewayPid = ($truth.gatewayPids | Select-Object -First 1)
    if ($null -eq $gatewayPid -or [string]::IsNullOrWhiteSpace([string]$gatewayPid)) {
        $gatewayPid = '?'
    }
    Write-RestartStatus ("OpenClaw ready: manager PID {0}, gateway PID {1}, port {2}" -f $managerPid, $gatewayPid, $gatewayPort) Green
    return $true
}

$finalTruth = $result.Truth
if ($finalTruth) {
    Write-RestartStatus ("OpenClaw failed to reach healthy state within {0}s (managers={1}, gateways={2}, tcp={3}, trayOwned={4})" -f $TimeoutSec, $finalTruth.managerCount, $finalTruth.gatewayCount, $finalTruth.tcpLiveness, $finalTruth.trayOwnedGateway) Red
} else {
    Write-RestartStatus ("OpenClaw failed to reach healthy state within {0}s." -f $TimeoutSec) Red
}

return $false
