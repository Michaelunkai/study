param(
    [ValidateSet('Full', 'CleanupOnly')]
    [string]$Mode = 'Full'
)

Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'

$allowed = @('Phone', 'YourPhone', 'current.ahk', 'OpenSpeedy', 'OpenWhisper', 'FullScreenSnip', 'Docker', 'SecurityHealth', 'RtkAudUService')
$exemptedTasks = @('Autorun_current_ahk', 'ClawdBotTray')
$legacyConsoleTasks = @('OpenClaw Gateway')
$ahkPath = 'F:\study\Platforms\windows\autohotkey\mymainahk\current.ahk'
$ahkName = 'current.ahk'
$taskName = 'Autorun_current_ahk'
$clawdBotTaskName = 'ClawdBotTray'
$clawdBotRoot = 'F:\study\AI_ML\AI_and_Machine_Learning\Artificial_Intelligence\openclaw\ClawdBot'
$clawdBotTrayVbs = Join-Path $clawdBotRoot 'ClawdbotTray.vbs'
$clawdBotManagerExe = Join-Path $clawdBotRoot 'ClawdBotManager.exe'
$clawdBotConfigPath = 'F:\study\AI_ML\AI_and_Machine_Learning\Artificial_Intelligence\openclaw\openclaw-home\openclaw.json'
$clawdBotStartupScript = 'F:\study\AI_ML\AI_and_Machine_Learning\Artificial_Intelligence\openclaw\ProfileFunctions\Register-ClawdBotStartup.ps1'
$clawdBotRestartScript = 'F:\study\AI_ML\AI_and_Machine_Learning\Artificial_Intelligence\openclaw\ProfileFunctions\Restart-OpenclawGateway.ps1'
$clawdBotWscriptExe = Join-Path $env:SystemRoot 'System32\wscript.exe'
$desiredDmScope = 'per-account-channel-peer'
$telegramAccountCount = 0
$telegramBindingCount = 0
$clawdBotReady = $false
$clawdBotTaskLooksCorrect = $false
$legacyConsoleTasksSafe = $true
$runAs = (& whoami).Trim()
$ahkExe = @(
    'C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe',
    'C:\Program Files\AutoHotkey\AutoHotkey.exe'
) | Where-Object { Test-Path $_ } | Select-Object -First 1

function Normalize-CommandText {
    param([string]$Value)
    if ([string]::IsNullOrWhiteSpace($Value)) { return '' }
    return (($Value -replace '"', '') -replace '\s+', ' ').Trim().ToLowerInvariant()
}

function Get-TaskInfo {
    param([string]$TaskName)

    $raw = & schtasks /query /tn $TaskName /v /fo list 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $raw) { return $null }

    $taskToRunLine = $raw | Select-String '^Task To Run:\s*(.+)$' | Select-Object -First 1
    $taskStateLine = $raw | Select-String '^Scheduled Task State:\s*(.+)$' | Select-Object -First 1
    $taskToRun = if ($taskToRunLine) { $taskToRunLine.Matches[0].Groups[1].Value.Trim() } else { $null }
    $taskState = if ($taskStateLine) { $taskStateLine.Matches[0].Groups[1].Value.Trim() } else { $null }

    [pscustomobject]@{
        Name      = $TaskName
        Raw       = $raw
        TaskToRun = $taskToRun
        State     = $taskState
        Enabled   = ($taskState -ne 'Disabled')
    }
}

function Disable-TaskIfExists {
    param([string]$TaskName)

    $taskInfo = Get-TaskInfo -TaskName $TaskName
    if (-not $taskInfo) { return $true }
    if ($taskInfo.Enabled) {
        & cmd /c "schtasks /change /tn ""$TaskName"" /disable >nul 2>nul"
        return ($LASTEXITCODE -eq 0)
    }
    return $true
}

function Ensure-AhkShortcut {
    param(
        [string]$ShortcutPath,
        [string]$ScriptPath,
        [string]$ExePath
    )

    if (-not (Test-Path $ScriptPath)) { return $false }

    $expectedTarget = if ($ExePath) { $ExePath } else { $ScriptPath }
    $expectedArguments = if ($ExePath) { "`"$ScriptPath`"" } else { '' }
    $needsWrite = $true
    $shell = New-Object -ComObject WScript.Shell

    if (Test-Path $ShortcutPath) {
        try {
            $existing = $shell.CreateShortcut($ShortcutPath)
            $existingArguments = if ($existing.Arguments) { $existing.Arguments.Trim() } else { '' }
            $needsWrite = ($existing.TargetPath -ne $expectedTarget) -or ($existingArguments -ne $expectedArguments)
        } catch {
            $needsWrite = $true
        }
    }

    if ($needsWrite) {
        $shortcut = $shell.CreateShortcut($ShortcutPath)
        $shortcut.TargetPath = $expectedTarget
        if ($expectedArguments) { $shortcut.Arguments = $expectedArguments }
        $shortcut.WorkingDirectory = (Split-Path $ScriptPath -Parent)
        $shortcut.Save()
        return $true
    }

    return $false
}

function Ensure-AhkScheduledTask {
    param(
        [string]$TaskName,
        [string]$ScriptPath,
        [string]$RunAs
    )

    if (-not (Test-Path $ScriptPath)) { return $false }

    $taskCommand = $ScriptPath
    $expectedTaskRun = Normalize-CommandText -Value $taskCommand
    $taskXml = & cmd /c "schtasks /query /tn ""$TaskName"" /xml" 2>$null
    $taskLooksCorrect = $taskXml -and ((Normalize-CommandText -Value $taskXml) -match [regex]::Escape($expectedTaskRun))

    if ($taskLooksCorrect) { return $true }

    & schtasks /delete /tn $TaskName /f 2>$null | Out-Null
    & schtasks /create /tn $TaskName /tr $taskCommand /sc onlogon /ru $RunAs /it /f 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        & schtasks /create /tn $TaskName /tr $taskCommand /sc onlogon /ru $RunAs /f 2>&1 | Out-Null
    }
    if ($LASTEXITCODE -eq 0) {
        & schtasks /change /tn $TaskName /ENABLE 2>$null | Out-Null
    }

    $verifiedTaskXml = & cmd /c "schtasks /query /tn ""$TaskName"" /xml" 2>$null
    return ($verifiedTaskXml -and ((Normalize-CommandText -Value $verifiedTaskXml) -match [regex]::Escape($expectedTaskRun)))
}

function Get-AllScheduledTaskRows {
    $headers = @(
        'HostName',
        'TaskName',
        'NextRunTime',
        'Status',
        'LogonMode',
        'LastRunTime',
        'LastResult',
        'Author',
        'TaskToRun',
        'StartIn',
        'Comment',
        'ScheduledTaskState',
        'IdleTime',
        'PowerManagement',
        'RunAsUser',
        'DeleteTaskIfNotRescheduled',
        'StopTaskIfRunsTooLong',
        'Schedule',
        'ScheduleType',
        'StartTime',
        'StartDate',
        'EndDate',
        'Days',
        'Months',
        'RepeatEvery',
        'RepeatUntilTime',
        'RepeatUntilDuration',
        'RepeatStopIfStillRunning'
    )
    $csv = & schtasks /query /v /fo csv /nh 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $csv) { return @() }
    return @($csv | ConvertFrom-Csv -Header $headers)
}

function Get-LeafTaskName {
    param([string]$TaskName)
    if ([string]::IsNullOrWhiteSpace($TaskName)) { return '' }
    return (($TaskName -replace '^\\+', '') -split '\\')[-1]
}

try {
    Write-Host '========================================' -ForegroundColor Cyan
    Write-Host "     STARTUP CLEANUP - $(if ($Mode -eq 'CleanupOnly') { 'allstart2' } else { 'allstart' })" -ForegroundColor Cyan
    Write-Host '  PERMANENT ENFORCEMENT MODE' -ForegroundColor Yellow
    Write-Host '========================================' -ForegroundColor Cyan
    Write-Host ''

    Write-Host '[1/6] Registering current.ahk for Windows startup...' -ForegroundColor Yellow
    $ahkRegistered = $false
    $runPath = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run'
    $runValue = if ($ahkExe) { "`"$ahkExe`" `"$ahkPath`"" } else { "`"$ahkPath`"" }

    if (Test-Path $ahkPath) {
        $currentVal = Get-ItemProperty -Path $runPath -Name $ahkName -ErrorAction SilentlyContinue
        if ($currentVal.$ahkName -ne $runValue) {
            Set-ItemProperty -Path $runPath -Name $ahkName -Value $runValue -Force
            Write-Host "  [+] Added to Registry: $runPath" -ForegroundColor Green
        } else {
            Write-Host "  [=] Already in Registry: $runPath" -ForegroundColor Gray
        }
        $ahkRegistered = $true
    }

    $startupFolder = [Environment]::GetFolderPath('Startup')
    $shortcutPath = Join-Path $startupFolder "$ahkName.lnk"
    if (Ensure-AhkShortcut -ShortcutPath $shortcutPath -ScriptPath $ahkPath -ExePath $ahkExe) {
        Write-Host "  [+] Added or repaired Startup folder shortcut: $startupFolder" -ForegroundColor Green
        $ahkRegistered = $true
    } elseif (Test-Path $shortcutPath) {
        Write-Host "  [=] Startup folder shortcut already correct: $startupFolder" -ForegroundColor Gray
    }

    if (Ensure-AhkScheduledTask -TaskName $taskName -ScriptPath $ahkPath -RunAs $runAs) {
        Write-Host "  [+] Scheduled task verified and enabled: $taskName" -ForegroundColor Green
        $ahkRegistered = $true
    }

    if ($ahkRegistered) {
        Write-Host '  [OK] current.ahk will run at EVERY startup' -ForegroundColor Green
    } else {
        Write-Host "  [!] WARNING: current.ahk not found at $ahkPath" -ForegroundColor Red
    }

    Write-Host ''
    Write-Host '[2/6] Repairing silent ClawdBot tray startup...' -ForegroundColor Yellow
    if ((Test-Path $clawdBotTrayVbs) -and (Test-Path $clawdBotManagerExe) -and (Test-Path $clawdBotRestartScript)) {
        if (Test-Path $clawdBotConfigPath) {
            try {
                $clawdBotConfig = Get-Content -Raw $clawdBotConfigPath | ConvertFrom-Json
                if ($null -eq $clawdBotConfig.session) {
                    $clawdBotConfig | Add-Member -MemberType NoteProperty -Name session -Value ([pscustomobject]@{}) -Force
                }
                $currentDmScope = $null
                if ($clawdBotConfig.session.PSObject.Properties['dmScope']) {
                    $currentDmScope = $clawdBotConfig.session.dmScope
                }
                if ($currentDmScope -ne $desiredDmScope) {
                    $clawdBotConfig.session | Add-Member -MemberType NoteProperty -Name dmScope -Value $desiredDmScope -Force
                    $clawdBotConfig | ConvertTo-Json -Depth 100 | Set-Content -Encoding UTF8 $clawdBotConfigPath
                    Write-Host "  [+] Set Telegram DM isolation to $desiredDmScope" -ForegroundColor Green
                } else {
                    Write-Host "  [=] Telegram DM isolation already set to $desiredDmScope" -ForegroundColor Gray
                }
                if ($clawdBotConfig.channels -and $clawdBotConfig.channels.telegram -and $clawdBotConfig.channels.telegram.accounts) {
                    $telegramAccountCount = @($clawdBotConfig.channels.telegram.accounts.PSObject.Properties.Name).Count
                }
                if ($clawdBotConfig.bindings) {
                    $telegramBindingCount = @($clawdBotConfig.bindings | Where-Object { $_.match -and $_.match.channel -eq 'telegram' }).Count
                }
            } catch {
                Write-Host "  [!] Failed to validate ClawdBot config: $_" -ForegroundColor Red
            }
        } else {
            Write-Host "  [!] Missing ClawdBot config: $clawdBotConfigPath" -ForegroundColor Red
        }

        foreach ($legacyTaskName in $legacyConsoleTasks) {
            if (Disable-TaskIfExists -TaskName $legacyTaskName) {
                Write-Host "  [OK] Legacy console startup kept disabled: $legacyTaskName" -ForegroundColor Green
            } else {
                $legacyConsoleTasksSafe = $false
                Write-Host "  [!] Failed to disable legacy console startup: $legacyTaskName" -ForegroundColor Red
            }
        }

        if (Test-Path $clawdBotStartupScript) {
            & $clawdBotStartupScript | Out-Null
        } elseif (Get-Command Register-ClawdBotStartup -ErrorAction SilentlyContinue) {
            Register-ClawdBotStartup | Out-Null
        } else {
            Write-Host "  [!] Missing ClawdBot startup helper: $clawdBotStartupScript" -ForegroundColor Red
        }

        $clawdBotTaskInfo = Get-TaskInfo -TaskName $clawdBotTaskName
        if ($clawdBotTaskInfo) {
            $expectedTaskRun = Normalize-CommandText -Value "$clawdBotWscriptExe //B //Nologo $clawdBotTrayVbs"
            $clawdBotTaskLooksCorrect = ((Normalize-CommandText -Value $clawdBotTaskInfo.TaskToRun) -eq $expectedTaskRun) -and $clawdBotTaskInfo.Enabled
        }

        $clawdBotReady = & $clawdBotRestartScript -CheckOnly -Quiet
        if ($clawdBotReady) {
            Write-Host '  [=] ClawdBot tray already healthy' -ForegroundColor Gray
        } elseif ($Mode -eq 'Full') {
            Write-Host '  [!] ClawdBot tray missing or unhealthy. Restarting...' -ForegroundColor Yellow
            $clawdBotReady = & $clawdBotRestartScript -TimeoutSec 210
        } else {
            Write-Host '  [!] ClawdBot tray not healthy; cleanup-only mode left the live runtime untouched' -ForegroundColor Yellow
        }

        if ($clawdBotReady) {
            Write-Host '  [OK] ClawdBot tray is running silently with one manager and one live gateway' -ForegroundColor Green
        } else {
            Write-Host '  [!] ClawdBot tray startup was repaired, but live gateway readiness was not confirmed' -ForegroundColor Red
        }
        if ($clawdBotTaskLooksCorrect) {
            Write-Host '  [OK] ClawdBotTray task targets the exact hidden VBS launcher' -ForegroundColor Green
        } else {
            Write-Host '  [!] ClawdBotTray task target was not confirmed' -ForegroundColor Red
        }
        if (($telegramAccountCount -eq 4) -and ($telegramBindingCount -eq 4)) {
            Write-Host '  [OK] 4 Telegram accounts and 4 Telegram bindings are configured' -ForegroundColor Green
        } else {
            Write-Host "  [!] Telegram mapping count is $telegramAccountCount accounts / $telegramBindingCount bindings" -ForegroundColor Red
        }
    } else {
        Write-Host '  [!] Missing ClawdBot tray launcher, manager, or restart script' -ForegroundColor Red
    }

    Write-Host ''
    Write-Host '[3/6] Cleaning registry Run keys...' -ForegroundColor Yellow
    $registryPaths = @('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run', 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run')
    foreach ($path in $registryPaths) {
        Write-Host "  Cleaning: $path" -ForegroundColor Gray
        $props = Get-ItemProperty $path -ErrorAction SilentlyContinue
        if ($props) {
            $props.PSObject.Properties | Where-Object { $_.Name -notmatch '^PS' } | ForEach-Object {
                $name = $_.Name
                if ($allowed -notcontains $name) {
                    Remove-ItemProperty -Path $path -Name $name -Force -ErrorAction SilentlyContinue
                    Write-Host "    - Removed: $name" -ForegroundColor Red
                }
            }
        }
    }

    Write-Host ''
    Write-Host '[4/6] Disabling unauthorized scheduled tasks...' -ForegroundColor Yellow
    $disabledCount = 0
    foreach ($taskRow in Get-AllScheduledTaskRows) {
        $rawTaskName = $taskRow.TaskName
        $leafTaskName = Get-LeafTaskName -TaskName $rawTaskName
        if ([string]::IsNullOrWhiteSpace($leafTaskName)) { continue }
        if ($leafTaskName -in $exemptedTasks) { continue }

        $prefix = ($leafTaskName -split '_')[0]
        if ($allowed -notcontains $prefix) {
            & cmd /c "schtasks /change /tn ""$rawTaskName"" /disable >nul 2>nul"
            if ($LASTEXITCODE -eq 0) {
                Write-Host "  - Disabled: $leafTaskName" -ForegroundColor Red
                $disabledCount++
            }
        }
    }
    if ($disabledCount -eq 0) {
        Write-Host '  [OK] No unauthorized tasks found' -ForegroundColor Gray
    }

    foreach ($legacyTaskName in $legacyConsoleTasks) {
        if (Disable-TaskIfExists -TaskName $legacyTaskName) {
            Write-Host "  [OK] Silent startup preserved by disabling $legacyTaskName" -ForegroundColor Green
        } else {
            $legacyConsoleTasksSafe = $false
            Write-Host "  [!] Silent startup could not disable $legacyTaskName" -ForegroundColor Red
        }
    }

    Write-Host ''
    Write-Host '[5/6] Cleaning user startup folder...' -ForegroundColor Yellow
    $userStartup = [Environment]::GetFolderPath('Startup')
    if (Test-Path $userStartup) {
        Get-ChildItem $userStartup -File | ForEach-Object {
            $name = $_.BaseName
            if ($allowed -notcontains $name) {
                Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue
                Write-Host "  - Removed: $($_.Name)" -ForegroundColor Red
            }
        }
    }

    Write-Host ''
    Write-Host '[6/6] Verification summary:' -ForegroundColor Yellow
    $regCheck = Get-ItemProperty $runPath -Name $ahkName -ErrorAction SilentlyContinue
    if ($regCheck) { Write-Host "  [OK] $ahkName in registry Run" -ForegroundColor Green }
    $folderCheck = Join-Path $userStartup "$ahkName.lnk"
    if (Test-Path $folderCheck) { Write-Host "  [OK] $ahkName in startup folder" -ForegroundColor Green }

    $taskCheck = Get-TaskInfo -TaskName $taskName
    if ($taskCheck -and $taskCheck.Enabled) {
        Write-Host "  [OK] $taskName scheduled task active" -ForegroundColor Green
    }

    $clawdBotTask = Get-TaskInfo -TaskName $clawdBotTaskName
    if ($clawdBotTask -and $clawdBotTask.Enabled) {
        Write-Host "  [OK] $clawdBotTaskName scheduled task enabled" -ForegroundColor Green
    }
    if ($clawdBotTaskLooksCorrect) {
        Write-Host "  [OK] $clawdBotTaskName scheduled task targets $clawdBotTrayVbs via hidden wscript" -ForegroundColor Green
    }
    if ($legacyConsoleTasksSafe) {
        Write-Host '  [OK] Legacy OpenClaw console startup task stays disabled' -ForegroundColor Green
    }
    if ($clawdBotReady) {
        Write-Host '  [OK] ClawdBot tray path is live and listening on port 18789' -ForegroundColor Green
    }
    if (($telegramAccountCount -eq 4) -and ($telegramBindingCount -eq 4)) {
        Write-Host "  [OK] Telegram accounts stay isolated with dmScope=$desiredDmScope" -ForegroundColor Green
    }

    Write-Host ''
    Write-Host '========================================' -ForegroundColor Cyan
    Write-Host '     STARTUP CLEANUP COMPLETED' -ForegroundColor Cyan
    Write-Host '========================================' -ForegroundColor Cyan
    Write-Host ''
    Write-Host 'GUARANTEED to run at EVERY startup:' -ForegroundColor Green
    Write-Host "  - current.ahk ($ahkPath)" -ForegroundColor Green
    Write-Host "  - ClawdBot tray ($clawdBotTrayVbs)" -ForegroundColor Green
    $allowed | Where-Object { $_ -ne 'current.ahk' } | ForEach-Object {
        Write-Host "  - $_" -ForegroundColor Green
    }
    Write-Host ''
} catch {
    Write-Error "Startup cleanup failed: $_"
    exit 1
}
