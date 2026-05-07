param([switch]$PersistUser)

$ErrorActionPreference = 'Stop'
. 'F:\study\AI_ML\AI_and_Machine_Learning\Artificial_Intelligence\openclaw\scripts\Resolve-OpenClawPaths.ps1'
$null = Ensure-OpenClawAuthorityFiles

function Write-AsciiFile {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Content,
        [Parameter(Mandatory = $true)][string]$Kind,
        [string]$Source = 'Ensure-OpenClawCommandSurface.ps1'
    )

    if (Test-Path $Path) {
        $existing = [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
        if ($existing -eq $Content) {
            Register-OpenClawManagedFile -Path $Path -Kind $Kind -Source $Source -GeneratedBy 'Ensure-OpenClawCommandSurface.ps1'
            return
        }
    }

    [System.IO.File]::WriteAllText($Path, $Content, [System.Text.Encoding]::ASCII)
    Register-OpenClawManagedFile -Path $Path -Kind $Kind -Source $Source -GeneratedBy 'Ensure-OpenClawCommandSurface.ps1'
}

function Ensure-WrapperFiles {
    param(
        [Parameter(Mandatory = $true)]$Paths
    )

    $runtimeCommandRoot = if ($Paths.PSObject.Properties['RuntimeCommandRoot']) {
        [string]$Paths.RuntimeCommandRoot
    } else {
        [string]$Paths.NpmGlobalRoot
    }

    if (-not (Test-Path $Paths.NpmGlobalRoot)) {
        New-Item -ItemType Directory -Path $Paths.NpmGlobalRoot -Force | Out-Null
    }

    $cmdTemplate = @'
@ECHO off
GOTO start
:find_dp0
SET dp0=%~dp0
EXIT /b
:start
SETLOCAL
CALL :find_dp0

IF EXIST "%dp0%\node.exe" (
  SET "_prog=%dp0%\node.exe"
) ELSE (
  SET "_prog=node"
  SET PATHEXT=%PATHEXT:;.JS;=;%
)

endLocal & goto #_undefined_# 2>NUL || title %COMSPEC% & "%_prog%"  "%dp0%\node_modules\__PKG__\__ENTRY__" %*
'@

    $psTemplate = @'
#!/usr/bin/env pwsh
$basedir=Split-Path $MyInvocation.MyCommand.Definition -Parent

$exe=""
if ($PSVersionTable.PSVersion -lt "6.0" -or $IsWindows) {
  $exe=".exe"
}
$ret=0
if (Test-Path "$basedir/node$exe") {
  if ($MyInvocation.ExpectingInput) {
    $input | & "$basedir/node$exe"  "$basedir/node_modules/__PKG__/__ENTRY__" $args
  } else {
    & "$basedir/node$exe"  "$basedir/node_modules/__PKG__/__ENTRY__" $args
  }
  $ret=$LASTEXITCODE
} else {
  if ($MyInvocation.ExpectingInput) {
    $input | & "node$exe"  "$basedir/node_modules/__PKG__/__ENTRY__" $args
  } else {
    & "node$exe"  "$basedir/node_modules/__PKG__/__ENTRY__" $args
  }
  $ret=$LASTEXITCODE
}
exit $ret
'@

    $authorityHeaderCmd = @(
        '@ECHO off'
        'REM OpenClaw managed wrapper'
        ('REM authority_generation={0}' -f $Paths.AuthorityGenerationId)
        ('REM runtime_generation={0}' -f $Paths.RuntimeGenerationId)
        ''
    ) -join [Environment]::NewLine

    $authorityHeaderPs = @(
        '# OpenClaw managed wrapper'
        ('# authority_generation={0}' -f $Paths.AuthorityGenerationId)
        ('# runtime_generation={0}' -f $Paths.RuntimeGenerationId)
        ''
    ) -join [Environment]::NewLine

    $wrappers = @(
        @{ Package = 'openclaw'; Entry = 'openclaw.mjs'; Cmd = 'openclaw.cmd'; Ps = 'openclaw.ps1' }
    )

    foreach ($wrapper in $wrappers) {
        $packageRoot = Join-Path $runtimeCommandRoot ("node_modules\{0}" -f $wrapper.Package)
        if (-not (Test-Path $packageRoot)) {
            continue
        }

        $cmdPath = Join-Path $Paths.NpmGlobalRoot $wrapper.Cmd
        $psPath = Join-Path $Paths.NpmGlobalRoot $wrapper.Ps
        if ($runtimeCommandRoot -eq $Paths.NpmGlobalRoot) {
            Write-AsciiFile -Path $cmdPath -Content ($authorityHeaderCmd + $cmdTemplate.Replace('__PKG__', $wrapper.Package).Replace('__ENTRY__', $wrapper.Entry)) -Kind 'command-wrapper' -Source $wrapper.Package
            Write-AsciiFile -Path $psPath -Content ($authorityHeaderPs + $psTemplate.Replace('__PKG__', $wrapper.Package).Replace('__ENTRY__', $wrapper.Entry)) -Kind 'powershell-wrapper' -Source $wrapper.Package
        } else {
            $cmdForwarder = @"
@ECHO off
REM OpenClaw managed wrapper
REM authority_generation=$($Paths.AuthorityGenerationId)
REM runtime_generation=$($Paths.RuntimeGenerationId)
CALL "$(Join-Path $runtimeCommandRoot $wrapper.Cmd)" %*
"@

            $psForwarder = @"
#!/usr/bin/env pwsh
# OpenClaw managed wrapper
# authority_generation=$($Paths.AuthorityGenerationId)
# runtime_generation=$($Paths.RuntimeGenerationId)
& '$(Join-Path $runtimeCommandRoot $wrapper.Ps)' @args
exit `$LASTEXITCODE
"@

            Write-AsciiFile -Path $cmdPath -Content $cmdForwarder -Kind 'command-forwarder' -Source $wrapper.Package
            Write-AsciiFile -Path $psPath -Content $psForwarder -Kind 'powershell-forwarder' -Source $wrapper.Package
        }
    }

    $openclawCmd = Join-Path $Paths.NpmGlobalRoot 'openclaw.cmd'
    $openclawPs = Join-Path $Paths.NpmGlobalRoot 'openclaw.ps1'
    if ((Test-Path $openclawCmd) -and (Test-Path $openclawPs)) {
        $clawdbotCmd = @"
@ECHO off
CALL "$openclawCmd" %*
"@

        $clawdbotPs = @"
#!/usr/bin/env pwsh
# OpenClaw managed wrapper
# authority_generation=$($Paths.AuthorityGenerationId)
# runtime_generation=$($Paths.RuntimeGenerationId)
& '$openclawPs' @args
exit `$LASTEXITCODE
"@

        Write-AsciiFile -Path (Join-Path $Paths.NpmGlobalRoot 'clawdbot.cmd') -Content ("@ECHO off`r`nREM OpenClaw managed wrapper`r`nREM authority_generation=$($Paths.AuthorityGenerationId)`r`nREM runtime_generation=$($Paths.RuntimeGenerationId)`r`nCALL ""$openclawCmd"" %*`r`n") -Kind 'command-wrapper' -Source 'clawdbot'
        Write-AsciiFile -Path (Join-Path $Paths.NpmGlobalRoot 'clawdbot.ps1') -Content $clawdbotPs -Kind 'powershell-wrapper' -Source 'clawdbot'
    }
}

function Ensure-LegacyForwarders {
    param(
        [Parameter(Mandatory = $true)]$Paths
    )

    $legacyMap = @(
        @{
            Name = 'openclaw'
            Root = Join-Path $env:LOCALAPPDATA 'npm-global'
            CanonicalCmd = Join-Path $Paths.NpmGlobalRoot 'openclaw.cmd'
            CanonicalPs = Join-Path $Paths.NpmGlobalRoot 'openclaw.ps1'
        },
        @{
            Name = 'clawdbot'
            Root = Join-Path $env:APPDATA 'npm'
            CanonicalCmd = Join-Path $Paths.NpmGlobalRoot 'clawdbot.cmd'
            CanonicalPs = Join-Path $Paths.NpmGlobalRoot 'clawdbot.ps1'
        }
    )

    foreach ($entry in $legacyMap) {
        if (-not (Test-Path $entry.Root)) {
            continue
        }

        if (-not ((Test-Path $entry.CanonicalCmd) -and (Test-Path $entry.CanonicalPs))) {
            continue
        }

        $cmdForwarder = @"
@ECHO off
CALL "$($entry.CanonicalCmd)" %*
"@

        $psForwarder = @"
#!/usr/bin/env pwsh
& '$($entry.CanonicalPs)' @args
exit `$LASTEXITCODE
"@

        Write-AsciiFile -Path (Join-Path $entry.Root ("{0}.cmd" -f $entry.Name)) -Content ("@ECHO off`r`nREM OpenClaw canonical forwarder`r`nREM authority_generation=$($Paths.AuthorityGenerationId)`r`nCALL ""$($entry.CanonicalCmd)"" %*`r`n") -Kind 'legacy-command-forwarder' -Source $entry.Name
        Write-AsciiFile -Path (Join-Path $entry.Root ("{0}.ps1" -f $entry.Name)) -Content ("#!/usr/bin/env pwsh`n# OpenClaw canonical forwarder`n# authority_generation=$($Paths.AuthorityGenerationId)`n& '$($entry.CanonicalPs)' @args`nexit `$LASTEXITCODE`n") -Kind 'legacy-powershell-forwarder' -Source $entry.Name
    }
}

function Update-UserPath {
    param(
        [Parameter(Mandatory = $true)][string]$PreferredRoot,
        [string[]]$AdditionalRoots = @(),
        [switch]$Persist
    )

    $separator = ';'
    $roots = @($PreferredRoot) + @($AdditionalRoots | Where-Object { -not [string]::IsNullOrWhiteSpace($_) -and (Test-Path $_) })
    $currentProcessParts = @($env:PATH -split ';' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    $cleanProcess = @($currentProcessParts | Where-Object {
        $part = $_.TrimEnd('\')
        -not (@($roots | ForEach-Object { $_.TrimEnd('\') }) -contains $part)
    })
    $env:PATH = @($roots) + $cleanProcess -join $separator

    if (-not $Persist) {
        return
    }

    $currentUserPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $currentUserParts = @($currentUserPath -split ';' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    $cleanUser = @($currentUserParts | Where-Object {
        $part = $_.TrimEnd('\')
        -not (@($roots | ForEach-Object { $_.TrimEnd('\') }) -contains $part)
    })
    [Environment]::SetEnvironmentVariable('Path', (@($roots) + $cleanUser) -join $separator, 'User')
}

$paths = Set-OpenClawProcessEnvironment -PersistUser:$PersistUser
Ensure-WrapperFiles -Paths $paths
Ensure-LegacyForwarders -Paths $paths
Update-UserPath -PreferredRoot $paths.NpmGlobalRoot -Persist:$PersistUser

[pscustomobject]@{
    npmGlobalRoot = $paths.NpmGlobalRoot
    openclawWrapper = Join-Path $paths.NpmGlobalRoot 'openclaw.cmd'
    clawdbotWrapper = Join-Path $paths.NpmGlobalRoot 'clawdbot.cmd'
    persistedUserEnv = [bool]$PersistUser
}
