[CmdletBinding()]
param(
    [string]$ScriptsRoot
)

$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($ScriptsRoot)) { $ScriptsRoot = $PSScriptRoot }
$nodeCommand = Get-Command node.exe -ErrorAction SilentlyContinue | Select-Object -First 1
$npmCommand = Get-Command npm.cmd -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $nodeCommand) { throw 'Node.js is required to run the Samsung TV bridge. Install Node.js and rerun this dependency restore.' }
if (-not $npmCommand) { throw 'npm.cmd is required to restore the pinned Samsung TV bridge dependency. Install Node.js/npm and rerun this dependency restore.' }

$packageJson = Join-Path $ScriptsRoot 'package.json'
$packageLock = Join-Path $ScriptsRoot 'package-lock.json'
$wsPackageJson = Join-Path $ScriptsRoot 'node_modules\ws\package.json'
if (-not (Test-Path -LiteralPath $packageJson -PathType Leaf) -or -not (Test-Path -LiteralPath $packageLock -PathType Leaf)) {
    throw "Samsung TV package.json/package-lock.json is missing under $ScriptsRoot."
}

function Get-NodePackageValue {
    param([Parameter(Mandatory = $true)][string]$Expression)
    Push-Location $ScriptsRoot
    try {
        $value = & $nodeCommand.Source -p $Expression
        if ($LASTEXITCODE -ne 0) { throw "Node could not evaluate package metadata: $Expression" }
        return ($value -join '').Trim()
    } finally {
        Pop-Location
    }
}

$expectedVersion = Get-NodePackageValue "require('./package-lock.json').packages['node_modules/ws'].version"
if ([string]::IsNullOrWhiteSpace([string]$expectedVersion)) {
    throw 'The Samsung TV websocket dependency is not pinned in package-lock.json.'
}
$installedVersion = if (Test-Path -LiteralPath $wsPackageJson -PathType Leaf) {
    Get-NodePackageValue "require('./node_modules/ws/package.json').version"
} else { $null }

if ($installedVersion -ne $expectedVersion) {
    Push-Location $ScriptsRoot
    try {
        & $npmCommand.Source ci --omit=dev --no-audit --no-fund
        if ($LASTEXITCODE -ne 0) { throw "npm ci failed with exit code $LASTEXITCODE." }
    } finally {
        Pop-Location
    }
    $installedVersion = Get-NodePackageValue "require('./node_modules/ws/package.json').version"
}

if ($installedVersion -ne $expectedVersion) {
    throw "Installed ws version $installedVersion does not match lockfile version $expectedVersion."
}
Write-Output "REMOTE_COMMAND_CENTER_DEPENDENCIES_READY ws=$installedVersion node=$(& $nodeCommand.Source --version)"
