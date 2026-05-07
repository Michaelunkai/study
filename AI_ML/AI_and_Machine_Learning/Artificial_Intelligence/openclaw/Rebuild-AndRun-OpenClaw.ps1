[CmdletBinding()]
param(
    [switch]$CleanFirst,
    [switch]$SkipNpmInstall,
    [switch]$SkipTrayBuild,
    [switch]$SkipRun
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$root = $PSScriptRoot
$npmPrefix = Join-Path $root 'npm-global'
$managerProject = Join-Path $root 'ClawdBot\src\ClawdBotManagerApp\ClawdBotManagerApp.csproj'
$managerOutput = Join-Path $root 'ClawdBot\ClawdBotManager.exe'
$openclawHome = Join-Path $root 'openclaw-home'
$cacheRoot = Join-Path $root '.openclaw-cache'
$localDotnet = Join-Path $cacheRoot 'dotnet'
$dotnetVersion = '10.0.203'

function Invoke-Checked {
    param(
        [Parameter(Mandatory=$true)][string]$FilePath,
        [Parameter(Mandatory=$true)][string[]]$Arguments,
        [string]$WorkingDirectory = $root
    )

    Write-Host ">> $FilePath $($Arguments -join ' ')"
    $process = Start-Process -FilePath $FilePath -ArgumentList $Arguments -WorkingDirectory $WorkingDirectory -Wait -PassThru -NoNewWindow
    if ($process.ExitCode -ne 0) {
        throw "$FilePath failed with exit code $($process.ExitCode)."
    }
}

function Get-DotnetForBuild {
    $systemSdk = Join-Path $env:ProgramFiles "dotnet\sdk\$dotnetVersion\Sdks\Microsoft.NET.Sdk"
    if (Test-Path -LiteralPath $systemSdk) {
        return 'dotnet.exe'
    }

    $localDotnetExe = Join-Path $localDotnet 'dotnet.exe'
    $localSdk = Join-Path $localDotnet "sdk\$dotnetVersion\Sdks\Microsoft.NET.Sdk"
    if ((Test-Path -LiteralPath $localDotnetExe) -and (Test-Path -LiteralPath $localSdk)) {
        return $localDotnetExe
    }

    New-Item -ItemType Directory -Path $cacheRoot -Force | Out-Null
    $installScript = Join-Path $cacheRoot 'dotnet-install.ps1'
    if (-not (Test-Path -LiteralPath $installScript)) {
        Invoke-WebRequest -Uri 'https://dot.net/v1/dotnet-install.ps1' -OutFile $installScript
    }

    $installOutput = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $installScript -Version $dotnetVersion -Architecture x64 -InstallDir $localDotnet -NoPath 2>&1
    foreach ($line in $installOutput) {
        Write-Host $line
    }
    if ($LASTEXITCODE -ne 0) {
        throw "dotnet-install.ps1 failed with exit code $LASTEXITCODE."
    }
    if (-not (Test-Path -LiteralPath $localDotnetExe)) {
        throw "Local dotnet.exe was not created: $localDotnetExe"
    }
    return $localDotnetExe
}

if ($CleanFirst) {
    & (Join-Path $root 'Cleanup-OpenClawSpace.ps1') -Force
}

if (-not $SkipNpmInstall) {
    New-Item -ItemType Directory -Path $npmPrefix -Force | Out-Null
    foreach ($shim in @('openclaw.cmd', 'openclaw.ps1', 'clawdbot.cmd', 'clawdbot.ps1')) {
        $shimPath = Join-Path $npmPrefix $shim
        if (Test-Path -LiteralPath $shimPath) {
            Remove-Item -LiteralPath $shimPath -Force
        }
    }
    Invoke-Checked -FilePath 'npm.cmd' -Arguments @('install','-g','--force','--prefix', $npmPrefix, 'openclaw@2026.4.21', 'clawdbot@2026.1.24-3')
}

if (-not $SkipTrayBuild) {
    if (-not (Test-Path -LiteralPath $managerProject)) {
        throw "Tray manager project not found: $managerProject"
    }
    $dotnetExe = Get-DotnetForBuild
    Invoke-Checked -FilePath $dotnetExe -Arguments @('publish', $managerProject, '-c', 'Release', '-o', (Join-Path $root 'ClawdBot\publish'), '--nologo') -WorkingDirectory (Split-Path -Parent $managerProject)
    $publishedExe = Join-Path $root 'ClawdBot\publish\ClawdBotManager.exe'
    if (-not (Test-Path -LiteralPath $publishedExe)) {
        throw "Published tray manager was not created: $publishedExe"
    }
    Copy-Item -LiteralPath $publishedExe -Destination $managerOutput -Force
}

$env:OPENCLAW_HOME = $openclawHome
$env:PATH = (Join-Path $npmPrefix '') + ';' + $env:PATH

if (-not $SkipRun) {
    $restart = Join-Path $root 'ProfileFunctions\Restart-OpenclawGateway.ps1'
    if (Test-Path -LiteralPath $restart) {
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $restart
    } else {
        $openclaw = Join-Path $npmPrefix 'openclaw.cmd'
        if (-not (Test-Path -LiteralPath $openclaw)) {
            throw "OpenClaw launcher was not created: $openclaw"
        }
        Start-Process -FilePath $openclaw -ArgumentList @('gateway') -WorkingDirectory $root -WindowStyle Hidden
    }
}

[pscustomobject]@{
    Root = $root
    NpmPrefix = $npmPrefix
    TrayManager = $managerOutput
    OpenClawHome = $openclawHome
    RanRuntime = -not $SkipRun
}
