param(
    [switch]$Json
)

$ErrorActionPreference = 'Stop'
. 'F:\study\AI_ML\AI_and_Machine_Learning\Artificial_Intelligence\openclaw\scripts\Resolve-OpenClawPaths.ps1'

$paths = Get-OpenClawPaths
$packagePath = Join-Path $paths.RuntimeCommandRoot 'node_modules\openclaw\package.json'
$npmCmd = Join-Path (Split-Path -Path $paths.NodeExePath -Parent) 'npm.cmd'
$powershellHost = if (Test-Path -LiteralPath 'C:\Program Files\PowerShell\7\pwsh.exe') {
    'C:\Program Files\PowerShell\7\pwsh.exe'
} else {
    'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe'
}

if (-not (Test-Path -LiteralPath $npmCmd)) {
    throw "npm.cmd was not found next to node.exe: $npmCmd"
}

function Get-PackageVersion {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return $null
    }

    return [string]((Get-Content -Raw -LiteralPath $Path | ConvertFrom-Json).version)
}

function Invoke-NpmJson {
    param([string[]]$Arguments)

    $output = & $npmCmd @Arguments 2>&1
    $exitCode = $LASTEXITCODE
    [pscustomobject]@{
        ExitCode = $exitCode
        Output = @($output)
    }
}

$beforeVersion = Get-PackageVersion -Path $packagePath
$latestResult = Invoke-NpmJson -Arguments @('view', 'openclaw', 'version', '--json')
if ($latestResult.ExitCode -ne 0) {
    throw ("Failed to query latest OpenClaw version from npm. Output:`n{0}" -f ($latestResult.Output -join [Environment]::NewLine))
}

$latestVersionText = ($latestResult.Output -join [Environment]::NewLine).Trim()
$latestVersion = [string](ConvertFrom-Json -InputObject $latestVersionText)
if ([string]::IsNullOrWhiteSpace($latestVersion)) {
    throw 'Latest OpenClaw version query returned an empty version.'
}

$installOutput = @()
$changed = $false
if ($beforeVersion -ne $latestVersion) {
    $installResult = Invoke-NpmJson -Arguments @(
        'i',
        '-g',
        ('openclaw@{0}' -f $latestVersion),
        '--prefix',
        $paths.RuntimeCommandRoot,
        '--force',
        '--no-fund',
        '--no-audit',
        '--loglevel=error'
    )
    $installOutput = $installResult.Output
    if ($installResult.ExitCode -ne 0) {
        throw ("Stable update install failed. Output:`n{0}" -f ($installOutput -join [Environment]::NewLine))
    }
    $changed = $true
}

$afterVersion = Get-PackageVersion -Path $packagePath
if ([string]::IsNullOrWhiteSpace($afterVersion)) {
    throw "Updated runtime package.json was not found after install: $packagePath"
}

& $powershellHost -NoProfile -ExecutionPolicy Bypass -File (Join-Path $paths.RepoRoot 'scripts\Ensure-OpenClawCommandSurface.ps1') | Out-Null
$wrapperPath = Join-Path $paths.RuntimeCommandRoot 'openclaw.cmd'
if (-not (Test-Path -LiteralPath $wrapperPath)) {
    throw "Updated runtime command surface is missing openclaw.cmd: $wrapperPath"
}

$authority = Get-OpenClawAuthority
$runtimeRootMatches = [string]$authority.runtime.commandRoot -eq $paths.RuntimeCommandRoot
if (-not $runtimeRootMatches) {
    throw "Post-update runtime root mismatch. Expected $($paths.RuntimeCommandRoot) but authority points to $([string]$authority.runtime.commandRoot)."
}

$result = [pscustomobject]@{
    changed = $changed
    beforeVersion = $beforeVersion
    latestVersion = $latestVersion
    afterVersion = $afterVersion
    runtimeCommandRoot = $paths.RuntimeCommandRoot
    authorityVerified = $runtimeRootMatches
    installOutput = @($installOutput)
}

if ($Json) {
    $result | ConvertTo-Json -Depth 6
} else {
    $result
}
