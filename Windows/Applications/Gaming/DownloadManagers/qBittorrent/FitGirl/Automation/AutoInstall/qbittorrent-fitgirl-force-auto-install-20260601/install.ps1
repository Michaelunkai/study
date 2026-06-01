[CmdletBinding()]
param([switch]$NoRunOnce)
$root = [System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
$main = Join-Path $root 'scripts\Force-QbitFitGirlAutoInstall.ps1'
if($NoRunOnce){ & $main -Install } else { & $main -Install -RunOnceAfterInstall }
if($LASTEXITCODE -ne $null){ exit $LASTEXITCODE }
