# Register-ClawdBotStartup - Register ClawdBot to start on logon via Task Scheduler
param([switch]$Unregister)

. 'F:\study\AI_ML\AI_and_Machine_Learning\Artificial_Intelligence\openclaw\scripts\Resolve-OpenClawPaths.ps1'
$paths = Get-OpenClawPaths
$defaults = Get-OpenClawCanonicalDefaults

$taskName = 'ClawdBotTray'
$legacyConsoleTask = 'OpenClaw Gateway'
$vbs = $paths.TrayLauncherVbs
$wscript = Join-Path $env:SystemRoot 'System32\wscript.exe'
$runAs = (& whoami).Trim()
$expectedTaskRun = "$wscript //B //Nologo $vbs"
$expectedGatewayRun = ('"{0}"' -f (Join-Path $paths.StateRoot 'gateway.cmd'))

if ($Unregister) {
    schtasks /delete /tn $taskName /f 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Unregistered task: $taskName" -ForegroundColor Yellow
    }
    return
}
if (-not (Test-Path $vbs)) {
    Write-Warning "Launcher not found: $vbs"
    return
}

$legacyTask = schtasks /query /tn $legacyConsoleTask /v /fo list 2>$null
if ($LASTEXITCODE -eq 0 -and $legacyTask) {
    schtasks /change /tn $legacyConsoleTask /DISABLE 2>$null | Out-Null
    $legacyRunLine = ($legacyTask | Select-String '^Task To Run:\s*(.+)$' | Select-Object -First 1)
    if (-not $legacyRunLine -or $legacyRunLine.Matches[0].Groups[1].Value.Trim() -ne $expectedGatewayRun) {
        schtasks /delete /tn $legacyConsoleTask /f 2>$null | Out-Null
        schtasks /create /tn $legacyConsoleTask /tr $expectedGatewayRun /sc onlogon /ru $runAs /f 2>&1 | Out-Null
        schtasks /change /tn $legacyConsoleTask /DISABLE 2>$null | Out-Null
    }
}

$existingTask = schtasks /query /tn $taskName /v /fo list 2>$null
$taskLooksCorrect = $false
if ($LASTEXITCODE -eq 0 -and $existingTask) {
    $taskRunLine = ($existingTask | Select-String '^Task To Run:\s*(.+)$' | Select-Object -First 1)
    $taskEnabledLine = ($existingTask | Select-String '^Scheduled Task State:\s*(.+)$' | Select-Object -First 1)
    if ($taskRunLine) {
        $taskRun = $taskRunLine.Matches[0].Groups[1].Value.Trim()
        if ($taskRun -eq $expectedTaskRun) {
            $taskLooksCorrect = $true
            if ($taskEnabledLine -and $taskEnabledLine.Matches[0].Groups[1].Value.Trim() -eq 'Disabled') {
                schtasks /change /tn $taskName /ENABLE 2>$null | Out-Null
            }
        }
    }
}

if ($taskLooksCorrect) {
    Write-Host "ClawdBot startup task already correct: $taskName" -ForegroundColor Gray
    return
}

schtasks /delete /tn $taskName /f 2>$null | Out-Null
schtasks /create /tn $taskName /tr "`"$wscript`" //B //Nologo `"$vbs`"" /sc onlogon /ru $runAs /it /f 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    schtasks /create /tn $taskName /tr "`"$wscript`" //B //Nologo `"$vbs`"" /sc onlogon /ru $runAs /f 2>&1 | Out-Null
}
if ($LASTEXITCODE -eq 0) {
    schtasks /change /tn $taskName /ENABLE 2>$null | Out-Null
    Write-Host "Registered ClawdBot startup task: $taskName" -ForegroundColor Green
} else {
    Write-Warning "Failed to register startup task: $taskName"
}
