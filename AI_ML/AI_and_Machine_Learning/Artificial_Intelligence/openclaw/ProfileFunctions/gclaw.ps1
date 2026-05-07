$ErrorActionPreference = 'Stop'
. 'F:\study\AI_ML\AI_and_Machine_Learning\Artificial_Intelligence\openclaw\scripts\Resolve-OpenClawPaths.ps1'

function Ensure-TrayManagedGatewayHealthy {
    $restartScript = 'F:\study\AI_ML\AI_and_Machine_Learning\Artificial_Intelligence\openclaw\ProfileFunctions\Restart-OpenclawGateway.ps1'
    if (-not (Test-Path $restartScript)) {
        throw "Restart helper not found at $restartScript"
    }

    $healthy = & $restartScript -CheckOnly -Quiet
    if ($healthy) {
        Write-Host 'Tray-managed gateway chain is healthy.' -ForegroundColor Green
        return
    }

    Write-Host 'Restoring tray-managed gateway chain...' -ForegroundColor Cyan
    $restored = & $restartScript -Quiet
    if (-not $restored) {
        throw 'Tray-managed gateway chain failed to reach healthy state.'
    }
}

function Get-NodePath {
    foreach ($candidate in @(
        'C:\Program Files\nodejs\node.exe',
        (Get-Command node.exe -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -First 1),
        (Get-Command node -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -First 1)
    )) {
        if ($candidate -and (Test-Path $candidate)) {
            return $candidate
        }
    }

    throw 'node.exe not found'
}

$paths = Set-OpenClawProcessEnvironment -PersistUser
& 'F:\study\AI_ML\AI_and_Machine_Learning\Artificial_Intelligence\openclaw\scripts\Ensure-OpenClawCommandSurface.ps1' -PersistUser | Out-Null
$nodeExe = Get-NodePath

Write-Host 'OpenClaw version before repair:' -ForegroundColor Cyan
& $nodeExe $paths.RuntimeEntrypoint --version
Write-Host 'Reconciling F-root command surface without reinstalling or changing daemon ownership...' -ForegroundColor Cyan
& 'F:\study\AI_ML\AI_and_Machine_Learning\Artificial_Intelligence\openclaw\scripts\Ensure-OpenClawCommandSurface.ps1' -PersistUser | Out-Null
Ensure-TrayManagedGatewayHealthy
Write-Host 'OpenClaw version after repair:' -ForegroundColor Cyan
& $nodeExe $paths.RuntimeEntrypoint --version
