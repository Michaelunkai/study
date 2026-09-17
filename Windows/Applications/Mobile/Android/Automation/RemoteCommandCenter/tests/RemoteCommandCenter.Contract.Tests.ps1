$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$receiverPath = Join-Path $projectRoot 'scripts\Start-RemoteCommandCenterHttpReceiver.ps1'
$agentPath = Join-Path $projectRoot 'scripts\Start-RemoteCommandCenterAgent.ps1'
$actionPath = Join-Path $projectRoot 'scripts\Invoke-RemoteCommandCenterAction.ps1'
$trackedActionPath = Join-Path $projectRoot 'scripts\Invoke-RemoteCommandCenterTrackedAction.ps1'
$codexRestartPath = Join-Path $projectRoot 'scripts\Restart-CodexDesktopApp.ps1'
$focusGuardianPath = Join-Path $projectRoot 'scripts\Start-RemoteCommandCenterMoonlightFocusGuardian.ps1'
$wakeSettingsPath = Join-Path $projectRoot 'scripts\Ensure-RemoteCommandCenterWakeSettings.ps1'
$mainActivityPath = Join-Path $projectRoot 'app\src\main\java\com\mich\remotecommandcenter\MainActivity.java'
$gradlePath = Join-Path $projectRoot 'app\build.gradle'
$androidBuildPath = Join-Path $projectRoot 'build-android.ps1'
$setupPath = Join-Path $projectRoot 'setup\Install-RemoteCommandCenter.ps1'
$dependencyRestorePath = Join-Path $projectRoot 'scripts\Restore-RemoteCommandCenterDependencies.ps1'
$tvBridgeLauncherPath = Join-Path $projectRoot 'scripts\Start-RemoteCommandCenterTvBridge.ps1'
$tvBridgeStartupTestPath = Join-Path $projectRoot 'tests\samsung-tv-bridge.startup.test.js'
$trayPath = Join-Path $projectRoot 'scripts\Start-RemoteCommandCenterTray.ps1'
$agentInstallerPath = Join-Path $projectRoot 'scripts\Install-RemoteCommandCenterAgent.ps1'
$moonlightGuardPath = Join-Path $projectRoot 'scripts\Start-RemoteCommandCenterMoonlightGuard.ps1'
$wakePacketTestPath = Join-Path $projectRoot 'scripts\Test-RemoteCommandCenterWakePackets.ps1'
$samsungTvControlPath = Join-Path $projectRoot 'scripts\samsung-tv-control.js'
$samsungTvBridgePath = Join-Path $projectRoot 'scripts\samsung-tv-bridge.js'
$protocolPath = Join-Path $projectRoot 'scripts\RemoteCommandCenter.Protocol.ps1'
$terminalRunnerPath = Join-Path $projectRoot 'scripts\Invoke-RemoteCommandCenterTerminalRunner.ps1'

function Assert-True {
    param(
        [Parameter(Mandatory = $true)]
        [bool]$Condition,
        [Parameter(Mandatory = $true)]
        [string]$Message
    )
    if (-not $Condition) {
        throw "ASSERTION FAILED: $Message"
    }
}

function Assert-Match {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text,
        [Parameter(Mandatory = $true)]
        [string]$Pattern,
        [Parameter(Mandatory = $true)]
        [string]$Message
    )
    Assert-True -Condition ([regex]::IsMatch($Text, $Pattern, [Text.RegularExpressions.RegexOptions]::Multiline)) -Message $Message
}

function Assert-NotMatch {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text,
        [Parameter(Mandatory = $true)]
        [string]$Pattern,
        [Parameter(Mandatory = $true)]
        [string]$Message
    )
    Assert-True -Condition (-not [regex]::IsMatch($Text, $Pattern, [Text.RegularExpressions.RegexOptions]::Multiline)) -Message $Message
}

$receiver = Get-Content -LiteralPath $receiverPath -Raw
$agent = Get-Content -LiteralPath $agentPath -Raw
$action = Get-Content -LiteralPath $actionPath -Raw
$boundedHttpBodyReader = [regex]::Match($receiver, '(?s)function Read-BoundedRequestBody\s*\{.*?\n\}').Value
Assert-True -Condition ($boundedHttpBodyReader.Length -gt 0) -Message 'HTTP receiver must use a bounded request-body reader.'
Assert-Match -Text $boundedHttpBodyReader -Pattern '\$memory\.Length\s*\+\s*\$read\)\s*-gt\s*\$MaximumBytes' -Message 'HTTP receiver must enforce its size cap while streaming, including chunked requests.'
Assert-Match -Text $receiver -Pattern 'Read-BoundedRequestBody\s+-Stream\s+\$context\.Request\.InputStream' -Message 'HTTP action route must use the streaming body-size cap.'
Assert-Match -Text $receiver -Pattern 'Recovering accepted command without dispatch claim' -Message 'Matching accepted actions without an atomic dispatch claim must be recoverable on retry.'
Assert-Match -Text $receiver -Pattern 'Test-Path\s+-LiteralPath\s+\$dispatchClaimPath' -Message 'Accepted-action recovery must remain fail-closed when a dispatch claim already exists.'
$agentRelayRecoveryTestPath = Join-Path $PSScriptRoot 'RemoteCommandCenter.Agent.RelayRecovery.Tests.ps1'
Assert-True -Condition (Test-Path -LiteralPath $agentRelayRecoveryTestPath -PathType Leaf) -Message 'Agent relay restart recovery must have an isolated regression test.'
Assert-Match -Text $agent -Pattern 'relay-cursors' -Message 'Relay event progress must persist across agent restarts.'
Assert-Match -Text $agent -Pattern 'function Write-RelayCursor' -Message 'Relay cursors must have an atomic durable writer.'
Assert-Match -Text $agent -Pattern 'baselineTime\s*=\s*\$BaselineTime' -Message 'Relay cursor state must preserve its initial timestamp baseline.'
Assert-Match -Text $agent -Pattern 'Relay dispatch remains retryable; cursor was not advanced' -Message 'Retryable relay dispatch failures must not advance the durable cursor.'
$readinessBody = [regex]::Match($receiver, '(?s)function Get-StatusBody\s*\{.*?\n\}').Value
Assert-True -Condition ($readinessBody.Length -gt 0) -Message 'Receiver readiness response builder must exist.'
Assert-NotMatch -Text $readinessBody -Pattern 'machine\s*=|utc\s*=' -Message 'Unauthenticated readiness must not disclose machine identity or time metadata.'
$trackedAction = Get-Content -LiteralPath $trackedActionPath -Raw
$mainActivity = Get-Content -LiteralPath $mainActivityPath -Raw
$gradle = Get-Content -LiteralPath $gradlePath -Raw
$androidBuild = Get-Content -LiteralPath $androidBuildPath -Raw
$setup = Get-Content -LiteralPath $setupPath -Raw
$dependencyRestore = Get-Content -LiteralPath $dependencyRestorePath -Raw
$tvBridgeLauncher = Get-Content -LiteralPath $tvBridgeLauncherPath -Raw
$tray = Get-Content -LiteralPath $trayPath -Raw
$agentInstaller = Get-Content -LiteralPath $agentInstallerPath -Raw
$moonlightGuard = Get-Content -LiteralPath $moonlightGuardPath -Raw
$wakePacketTest = Get-Content -LiteralPath $wakePacketTestPath -Raw

Assert-True -Condition (Test-Path -LiteralPath $trackedActionPath -PathType Leaf) -Message 'Tracked action wrapper must exist.'
Assert-Match -Text $receiver -Pattern 'Invoke-RemoteCommandCenterTrackedAction\.ps1' -Message 'Receiver must launch the tracked action wrapper.'
Assert-Match -Text $receiver -Pattern 'duplicate' -Message 'Receiver must return an idempotent duplicate result for a reused nonce.'
Assert-Match -Text $receiver -Pattern 'actionStatus' -Message 'Status endpoint must expose correlated action completion state.'

Assert-Match -Text $action -Pattern "'tv_force_reboot'\s*\{\s*Invoke-SamsungTvSdbReboot" -Message 'TV reboot must invoke the real SDB reboot path.'
Assert-Match -Text $action -Pattern 'RCC_SDB_PATH' -Message 'TV reboot must allow the portable SDB path to be configured.'
Assert-Match -Text $action -Pattern 'F:\\backup\\windowsapps\\installed\\SamsungSDB\\data\\tools\\sdb\.exe' -Message 'TV reboot must resolve the user-approved portable SDB installation.'
Assert-NotMatch -Text $action -Pattern 'C:\\Users\\[^\\]+' -Message 'TV action paths must not depend on a retired Windows user profile.'
Assert-NotMatch -Text (Get-Content -LiteralPath $samsungTvBridgePath -Raw) -Pattern 'C:\\Users\\[^\\]+' -Message 'TV bridge defaults must use the active user profile.'
Assert-NotMatch -Text $action -Pattern "'tv_force_reboot'\s*\{\s*Invoke-SamsungTvPowerCycleReboot" -Message 'TV reboot must not be implemented as power off plus power on.'

Assert-True -Condition (Test-Path -LiteralPath $codexRestartPath -PathType Leaf) -Message 'Dedicated Codex desktop restart script must exist.'
Assert-Match -Text $action -Pattern 'Restart-CodexDesktopApp\.ps1' -Message 'Restart Codex action must use the desktop app restart helper.'
Assert-NotMatch -Text $action -Pattern "Start-Process\s+-FilePath\s+'codex'" -Message 'Restart Codex must not launch the CLI command.'
Assert-Match -Text $action -Pattern 'Invoke-TizenTubeViaPairedController' -Message 'YouTube must use the paired PC controller from the receiver worker.'
Assert-Match -Text $action -Pattern 'YOUTUBE_TIZEN_EXECUTING path=paired-controller' -Message 'YouTube must record its paired-controller execution path.'
Assert-Match -Text $action -Pattern 'function Wait-SamsungTvControlReady' -Message 'YouTube must wait for Samsung REST and remote-control readiness before launching.'
Assert-Match -Text $action -Pattern 'YOUTUBE_TIZEN_TV_CONTROL_READY' -Message 'YouTube must log TV control readiness before sending controller commands.'
Assert-NotMatch -Text $action -Pattern '& \$ps .*Start-TizenTubeAutoLaunch\.ps1' -Message 'YouTube must not wait on the non-terminating external launcher process.'
Assert-Match -Text $action -Pattern 'YOUTUBE_TIZEN_CARD_SURFACE_WAIT milliseconds=4500' -Message 'Fresh TizenBrew launches must wait for cards before controller navigation.'
Assert-Match -Text $action -Pattern 'YOUTUBE_TIZEN_CARD_KEY_SEQUENCE_SENT delayMs=\$keyDelay keys=KEY_DOWN,KEY_LEFT,KEY_ENTER' -Message 'YouTube must use one tracked paired-controller sequence.'
Assert-Match -Text $action -Pattern 'YOUTUBE_TIZEN_CARD_RECOVERY_SEQUENCE_SENT' -Message 'YouTube must make one bounded focus-recovery navigation only when the first fresh card sequence did not expose DIAL.'
Assert-Match -Text $action -Pattern '\$cardRecoverySequenceStarted' -Message 'YouTube focus recovery must be explicitly single-use inside one button transaction.'
Assert-Match -Text $action -Pattern 'Start-Process -FilePath \$node' -Message 'Paired-controller commands must run without PowerShell output capture.'
Assert-NotMatch -Text $action -Pattern '\$sequenceOutput\s*=\s*&\s*\$node' -Message 'YouTube card navigation must not block on captured Node output.'
Assert-Match -Text $action -Pattern 'function Invoke-TizenTubeDialStart' -Message 'YouTube must explicitly start a discovered stopped TizenTube DIAL service.'
Assert-Match -Text $action -Pattern 'if \(\$dialState -eq ''running'' -and -not \$brewVisible\)' -Message 'YouTube must only short-circuit when DIAL is running and TizenBrew is not visibly on the card screen.'
Assert-Match -Text $action -Pattern '\$initialDialState = \$dialState' -Message 'YouTube must retain the pre-navigation DIAL state to reject stale running responses.'
Assert-Match -Text $action -Pattern '\$dialTransitionedToRunning = \$initialDialState -ne ''running''' -Message 'YouTube must distinguish a real DIAL transition from a stale running response.'
Assert-Match -Text $action -Pattern 'brewVisible=\$brewVisible' -Message 'YouTube completion logs must retain contemporaneous TizenBrew visibility diagnostics.'
Assert-Match -Text $action -Pattern "Invoke-WebRequest -UseBasicParsing -Method POST -Uri 'http://192\.168\.1\.173:8085/dial/apps/YouTube'" -Message 'YouTube must send the bounded DIAL start request through the paired receiver.'
Assert-Match -Text $action -Pattern 'YOUTUBE_TIZEN_DIAL_START_SENT' -Message 'YouTube must log its one-time DIAL start transition.'
Assert-Match -Text $action -Pattern 'YOUTUBE_TIZEN_DIAL_SERVICE_WAITING' -Message 'YouTube must keep polling an unavailable TizenTube DIAL service after card navigation.'
Assert-Match -Text $action -Pattern '\$dialDeadline\s*=\s*\(Get-Date\)\.AddSeconds\(60\)' -Message 'YouTube must allow the TV DIAL service to recover within the bounded receiver transaction.'
Assert-True -Condition (Test-Path -LiteralPath $samsungTvControlPath -PathType Leaf) -Message 'Samsung TV app and remote-key helper must be present in the project.'
Assert-True -Condition (Test-Path -LiteralPath $samsungTvBridgePath -PathType Leaf) -Message 'Samsung TV bridge helper must be present in the project.'
Assert-NotMatch -Text (Get-Content -LiteralPath $samsungTvControlPath -Raw) -Pattern 'C:\\Users\\[^\\]+' -Message 'Samsung TV CLI must not depend on another user profile.'
$tvKeyHandler = [regex]::Match($action, '(?s)function Invoke-SamsungTvRemoteKey\b.*?(?=\r?\nfunction Invoke-SamsungTvSetVolume)').Value
Assert-Match -Text $tvKeyHandler -Pattern 'SAMSUNG_TV_REMOTE_NOT_RETRIED.*bridgeOutcomeMayBeAmbiguous' -Message 'A failed TV toggle request must not be replayed after an ambiguous bridge outcome.'
Assert-NotMatch -Text $tvKeyHandler -Pattern 'fallback=node-single-shot|& \$nodePath' -Message 'The TV key handler must not retry the same key through a second transport.'
Assert-Match -Text $setup -Pattern 'Restore-RemoteCommandCenterDependencies\.ps1' -Message 'Setup must restore TV dependencies without rotating existing pairing configuration.'
Assert-Match -Text $dependencyRestore -Pattern 'npmCommand\.Source\s+ci\s+--omit=dev\s+--no-audit\s+--no-fund' -Message 'Dependency recovery must restore the pinned TV dependency from package-lock.json.'
Assert-Match -Text $dependencyRestore -Pattern 'node_modules\\ws\\package\.json' -Message 'Dependency recovery must verify the installed websocket dependency version.'
Assert-Match -Text $tvBridgeLauncher -Pattern 'node_modules\\ws\\package\.json' -Message 'TV bridge startup must fail clearly when the pinned dependency is missing.'
Assert-Match -Text $tvBridgeLauncher -Pattern '\$config\.TvHost' -Message 'TV bridge startup must read the host from the protected local configuration.'
Assert-Match -Text $tvBridgeLauncher -Pattern 'RCC_CONFIG_PATH\s*=\s*\$ConfigPath' -Message 'TV bridge must read its saved pairing token from the selected private configuration.'
Assert-Match -Text $tray -Pattern '\[switch\]\$SkipMaintenanceWorkers' -Message 'Core startup must be able to leave power and Moonlight maintenance workers stopped.'
Assert-Match -Text $tray -Pattern 'if \(-not \$SkipMaintenanceWorkers\)' -Message 'Maintenance workers must only start when explicitly included.'
Assert-Match -Text $agentInstaller -Pattern '\[switch\]\$CoreWorkersOnly' -Message 'Startup installation must provide a mode that does not alter power, firewall, or legacy tasks.'
Assert-Match -Text $agentInstaller -Pattern 'Register-ScheduledTask.*RemoteCommandCenterTrayLogon' -Message 'Core startup mode must register the single Remote Command Center tray task.'
Assert-True -Condition (Test-Path -LiteralPath $tvBridgeStartupTestPath -PathType Leaf) -Message 'TV bridge startup and deferred connection behavior must have an integration test.'
Assert-Match -Text $androidBuild -Pattern 'compileSdk\(\?:Version\)\?' -Message 'Manual Android build must derive its compile SDK from app/build.gradle.'
Assert-Match -Text $androidBuild -Pattern 'platforms\\android-\$compileSdk' -Message 'Manual Android build must use the exact declared Android platform.'
Assert-Match -Text $action -Pattern 'RCC_FITGIRL_HELPER_ROOT' -Message 'qBittorrent helper root must be overridable for the installed FitGirl helper tree.'
Assert-Match -Text $action -Pattern 'F:\\study\\projects\\SystemMonitor\\PSProcLasso\\Windows\\Applications\\Gaming\\DownloadManagers\\qBittorrent' -Message 'qBittorrent helper must resolve the recovered canonical source tree.'
Assert-NotMatch -Text $action -Pattern 'F:\\study\\Windows\\Applications\\Gaming\\DownloadManagers\\qBittorrent' -Message 'qBittorrent helper must not retain the obsolete project path.'
Assert-Match -Text $action -Pattern 'RCC_PROFILE_DEFINITIONS_PATH' -Message 'Terminal profile definitions path must be configurable.'
Assert-Match -Text $action -Pattern 'F:\\backup\\windowsapps\\profile\\profile-backup\\ps5-profile-portable\\Microsoft\.PowerShell_profile\.full\.definitions\.ps1' -Message 'Terminal bootstrap must resolve the recovered profile definitions backup.'
Assert-NotMatch -Text $action -Pattern 'F:\\study\\Windows\\PowerShell\\Profile\\ps5-profile-portable' -Message 'Terminal bootstrap must not retain the obsolete profile path.'
Assert-Match -Text $action -Pattern 'RCC_MASTERCHIEF_RESCUE_SCRIPT' -Message 'Unfreeze rescue path must be explicitly configurable after the old checkout was removed.'
Assert-NotMatch -Text $action -Pattern 'F:\\study\\Windows\\Applications\\Mobile\\Android\\Automation\\MasterChiefRescue' -Message 'Unfreeze must not retain its obsolete checkout path.'
Assert-Match -Text $moonlightGuard -Pattern 'RCC_MOONLIGHT_RECOVERY_ROOT' -Message 'Moonlight recovery scripts must allow the recovered root to be configured.'
Assert-NotMatch -Text $moonlightGuard -Pattern 'F:\\study\\Systems\\Windows\\Media\\GameStreaming\\SamsungTizenMoonlightHostKit' -Message 'Moonlight startup must not retain its obsolete recovery checkout path.'
Assert-Match -Text $wakePacketTest -Pattern 'ProofPath\s*=\s*\(Join-Path\s+\(Split-Path\s+-Parent\s+\$PSScriptRoot\)' -Message 'Wake packet proof output must follow the current checkout rather than an obsolete absolute path.'
Assert-NotMatch -Text $wakePacketTest -Pattern 'F:\\study\\Windows\\Applications\\Mobile\\Android\\Automation\\RemoteCommandCenter\\runtime' -Message 'Wake packet proof must not retain its obsolete checkout path.'
Assert-Match -Text $trackedAction -Pattern 'Get-ActionTimeoutSeconds' -Message 'Tracked actions must have an explicit bounded timeout policy.'
Assert-Match -Text $trackedAction -Pattern "'youtube_tizen'\s*\{\s*return\s+180\s*\}" -Message 'YouTube actions must leave enough bounded time for TV-control service recovery without keeping single-flight locked.'
Assert-True -Condition (Test-Path -LiteralPath $focusGuardianPath -PathType Leaf) -Message 'Moonlight focus guardian must exist.'
Assert-Match -Text $action -Pattern 'Start-RemoteCommandCenterMoonlightFocusGuardian\.ps1' -Message 'Moonlight toggle must start and stop the session-bound focus guardian.'
$moonlightProofIndex = $action.IndexOf('PROOF_ONLY active; Moonlight toggle was not launched.')
$moonlightMissingIndex = $action.IndexOf('MOONLIGHT_TOGGLE_SCRIPT_MISSING')
Assert-True -Condition ($moonlightProofIndex -ge 0 -and $moonlightMissingIndex -gt $moonlightProofIndex) -Message 'Moonlight proof-only must report the selected branch and missing dependency before real execution fails closed.'
Assert-Match -Text $action -Pattern 'targetExists=\$targetExists' -Message 'Moonlight proof-only output must expose dependency availability without launching the selected script.'
$focusGuardian = Get-Content -LiteralPath $focusGuardianPath -Raw
Assert-Match -Text $focusGuardian -Pattern 'GetLastInputInfo' -Message 'Focus guardian must preserve intentional user switching.'
Assert-Match -Text $focusGuardian -Pattern 'Get-EncoderSessionCount' -Message 'Focus guardian must stop when the encoder session ends.'
Assert-Match -Text $focusGuardian -Pattern 'output_name' -Message 'Focus guardian must resolve Sunshine configured output instead of hardcoding DISPLAY10.'
Assert-True -Condition (Test-Path -LiteralPath $wakeSettingsPath -PathType Leaf) -Message 'Durable Wake settings verifier must exist.'
$wakeSettings = Get-Content -LiteralPath $wakeSettingsPath -Raw
Assert-Match -Text $wakeSettings -Pattern 'Shutdown Wake-On-Lan' -Message 'Wake settings must preserve shutdown WOL.'
Assert-Match -Text $wakeSettings -Pattern 'hibernateAfter 0' -Message 'Automatic hibernation must remain disabled without disabling full hibernation.'
Assert-NotMatch -Text $wakeSettings -Pattern 'Restart-NetAdapter|Disable-NetAdapter|Enable-NetAdapter' -Message 'Wake maintenance must not restart the adapter.'

Assert-Match -Text $mainActivity -Pattern 'ConcurrentHashMap' -Message 'Android must track in-flight actions independently.'
Assert-Match -Text $mainActivity -Pattern 'wakeSendInFlight' -Message 'Wake must be single-flight.'
$directTvCommandMap = [regex]::Match($mainActivity, '(?s)private boolean isDirectTvRemoteCommand\(String id\).*?(?=\s+private String tvKeyForCommand)').Value
Assert-True -Condition ($directTvCommandMap.Length -gt 0) -Message 'Direct TV command routing table must exist.'
Assert-NotMatch -Text $directTvCommandMap -Pattern 'tv_force_reboot' -Message 'TV reboot must use the authenticated host SDB route, never a held remote power key.'
Assert-NotMatch -Text $mainActivity -Pattern 'sendSamsungTvHeldKey' -Message 'Unreachable held-key TV reboot code must not remain in Android.'
Assert-Match -Text $mainActivity -Pattern 'requestWakeIntentConfirmation\(wakeDelayMs\)' -Message 'External delayed Wake intents must ask for device-user confirmation before scheduling.'
Assert-Match -Text $mainActivity -Pattern 'requestWakeIntentConfirmation\(-1\)' -Message 'External immediate Wake intents must ask for device-user confirmation before sending packets.'
$wakeIntentConfirmation = [regex]::Match($mainActivity, '(?s)private void requestWakeIntentConfirmation\(int delayMs\).*?(?=\s+private void scheduleWakeBurst)').Value
Assert-True -Condition ($wakeIntentConfirmation.Length -gt 0) -Message 'External Wake intent confirmation handler must exist.'
Assert-Match -Text $wakeIntentConfirmation -Pattern 'setNegativeButton\("Cancel"' -Message 'External Wake intent confirmation must allow cancellation.'
Assert-Match -Text $wakeIntentConfirmation -Pattern 'setPositiveButton\(delayed \? "Schedule Wake" : "Wake PC"' -Message 'External Wake intent must execute only after explicit positive confirmation.'
$wakeScheduler = [regex]::Match($mainActivity, '(?s)private void scheduleWakeBurst\(int delayMs\).*?(?=\s+private String runLocalCommand)').Value
Assert-True -Condition ($wakeScheduler.Length -gt 0) -Message 'Bounded delayed Wake scheduler must exist.'
Assert-Match -Text $wakeScheduler -Pattern 'Math\.min\(delayMs, 300000\)' -Message 'Delayed Wake intent must remain capped at five minutes.'
Assert-Match -Text $wakeScheduler -Pattern 'cancelScheduledWakeBurst\(\)' -Message 'A new delayed Wake request must replace and release the prior scheduled request.'
Assert-Match -Text $wakeScheduler -Pattern 'startWakeSend\("Delayed Wake", "Delayed Wake", finalDelayLock\)' -Message 'Delayed Wake must use the same single-flight send path and retain its label.'
Assert-Match -Text $mainActivity -Pattern 'wakeSendInFlight\.compareAndSet\(false, true\)' -Message 'All Wake entry points must acquire the single-flight guard inside the shared sender.'
Assert-Match -Text $mainActivity -Pattern 'cancelScheduledWakeBurst\(\);\s*statusHandler\.removeCallbacksAndMessages\(null\)' -Message 'Destroying the activity must cancel pending Wake work and release its lock.'
Assert-Match -Text $mainActivity -Pattern 'terminalSendInFlight\.compareAndSet\(false, true\)' -Message 'Terminal input and IME submissions must be single-flight.'
$dangerousCommandGate = [regex]::Match($mainActivity, '(?s)private void sendCommand\(Command command\).*?(?=\s+private void confirmDestructivePcCommand)').Value
Assert-True -Condition ($dangerousCommandGate.Length -gt 0) -Message 'Android destructive-command confirmation gate must exist.'
Assert-Match -Text $dangerousCommandGate -Pattern '(?s)if\s*\("shutdown_pc"\.equals\(command\.id\)\).*?confirmDestructivePcCommand\(command,.*?return;\s*\}\s*if\s*\("force_reboot_now"\.equals\(command\.id\)\).*?confirmDestructivePcCommand\(command,.*?return;\s*\}\s*if\s*\("refresh2_logoff"\.equals\(command\.id\)\).*?confirmDestructivePcCommand\(command,.*?return;\s*\}\s*if\s*\("reboot_to_bios"\.equals\(command\.id\)\).*?confirmDestructivePcCommand\(command,.*?return;\s*\}\s*if\s*\("restart_codex"\.equals\(command\.id\)\).*?confirmDestructivePcCommand\(command,' -Message 'Shutdown, forced reboot, logoff, BIOS reboot, and Restart Codex must pass through explicit confirmation before command dispatch.'
Assert-Match -Text $dangerousCommandGate -Pattern 'Remote Commander cannot operate while firmware setup is open; you will need local access to exit' -Message 'BIOS confirmation must explain the local recovery requirement.'
Assert-Match -Text $dangerousCommandGate -Pattern 'current Codex task may disconnect briefly; save or checkpoint work first' -Message 'Restart Codex confirmation must warn about task disconnection and checkpointing.'
$destructiveConfirmation = [regex]::Match($mainActivity, '(?s)private void confirmDestructivePcCommand\(Command command, String title, String message, String positiveLabel\).*?(?=\s+private void dispatchCommand)').Value
Assert-True -Condition ($destructiveConfirmation.Length -gt 0) -Message 'Destructive-command confirmation dialog must exist.'
Assert-Match -Text $destructiveConfirmation -Pattern '(?s)setNegativeButton\("Cancel".*?setPositiveButton\(positiveLabel,\s*\(dialog,\s*which\)\s*->\s*dispatchCommand\(command\)\)' -Message 'Destructive PC actions must be cancellable before dispatch.'
$logoffHandler = [regex]::Match($action, '(?s)function Invoke-Refresh2Logoff\s*\{.*?\n\}').Value
Assert-True -Condition ($logoffHandler.Length -gt 0) -Message 'Safe logoff handler must exist.'
Assert-Match -Text $logoffHandler -Pattern "Invoke-Executable -FilePath \`$shutdown -Arguments @\('/l','/f'\)" -Message 'Logoff must use the shared proof-only executable guard.'
Assert-NotMatch -Text $logoffHandler -Pattern 'Winlogon|DefaultPassword|AutoLogonCount|Set-ItemProperty' -Message 'Logoff must not write credentials or alter automatic sign-in registry settings.'
$terminalHandler = [regex]::Match($mainActivity, '(?s)private void sendTerminalLine\(\).*?(?=\s+private void handleIntent)').Value
Assert-True -Condition ($terminalHandler.Length -gt 0) -Message 'Terminal send handler must exist.'
Assert-Match -Text $terminalHandler -Pattern 'payload\.length\s*>\s*8192' -Message 'Terminal input must be bounded by the receiver UTF-8 byte limit.'
Assert-Match -Text $terminalHandler -Pattern 'sendCommandViaReceiver\(action\)' -Message 'Terminal commands must use the standard authenticated nonce path.'
Assert-Match -Text $terminalHandler -Pattern 'waitForActionCompletion\(nonce,\s*"PC Terminal",\s*action\)' -Message 'Terminal UI must wait for a signed completion correlated to its action and nonce.'
Assert-Match -Text $terminalHandler -Pattern 'confirmed\s*=\s*result\.startsWith\("Line returned: PC Terminal"\)' -Message 'Terminal UI must distinguish a returned PowerShell line from unconfirmed dispatch.'
Assert-Match -Text $terminalHandler -Pattern 'if\s*\(clearInput\s*&&\s*terminalInput\s*!=\s*null\)\s*terminalInput\.setText\(""\)' -Message 'Terminal input must remain available until the command runner reports completion.'
Assert-Match -Text $mainActivity -Pattern 'action\.startsWith\("terminal_line:"\)\s*\?\s*360000L' -Message 'Terminal UI timeout must cover the bounded host runner and route fallback.'
Assert-Match -Text $mainActivity -Pattern 'waitForActionCompletion' -Message 'Android must consume correlated action completion state.'
Assert-Match -Text $mainActivity -Pattern 'Unconfirmed:.*no authenticated completion received' -Message 'Android must report unconfirmed when a receiver action never produces an authenticated completion.'
Assert-Match -Text $mainActivity -Pattern 'rcc-status-query\|' -Message 'Android status reads must carry an authenticated nonce proof.'
Assert-Match -Text $mainActivity -Pattern 'isVerifiedActionStatus' -Message 'Android must verify correlated status signatures before trusting completion.'
Assert-Match -Text $mainActivity -Pattern 'commandRequestHashByNonce' -Message 'Android must bind completion status to the exact signed request fingerprint.'
Assert-Match -Text $mainActivity -Pattern 'expectedRequestHash\.equals\(actionStatus\.optString\("requestHash"' -Message 'Android must reject a signed completion for a different request using the same nonce.'
Assert-Match -Text $mainActivity -Pattern 'since=' -Message 'Android relay polling must use a continuation cursor.'
Assert-NotMatch -Text $mainActivity -Pattern 'sendWakePacketsBurst\(420,\s*0,\s*0\)' -Message 'Wake must not send a 420-loop packet storm.'
Assert-NotMatch -Text $mainActivity -Pattern 'sendWakePacketsBurst\(0,\s*1200,\s*50\)' -Message 'Wake must not send a 1200-loop background packet storm.'
$youtubeHandler = [regex]::Match($mainActivity, '(?s)private void sendYoutubeTizen\(Command command\).*?(?=\s+private boolean launchTizenBrewDirect)').Value
Assert-True -Condition ($youtubeHandler.Length -gt 0) -Message 'YouTube dispatch handler must exist.'
Assert-Match -Text $youtubeHandler -Pattern 'TIZENTUBE_RECEIVER_ONLY_DISPATCH' -Message 'YouTube must route through the paired PC controller.'
Assert-Match -Text $youtubeHandler -Pattern 'sendCommandViaReceiver\(command\.id\)' -Message 'YouTube must submit exactly one receiver action.'
Assert-NotMatch -Text $youtubeHandler -Pattern 'launchTizenBrewDirect|sendSamsungTv|openSamsungTvSocket' -Message 'YouTube must never open a Samsung remote connection from Android.'
Assert-Match -Text $mainActivity -Pattern '(?s)private boolean canTryDirectTv\(\)\s*\{.*?return false;' -Message 'Android Samsung remote sockets must stay disabled to prevent TV authorization dialogs.'

$protocol = Get-Content -LiteralPath $protocolPath -Raw
$terminalRunner = Get-Content -LiteralPath $terminalRunnerPath -Raw
Assert-Match -Text $protocol -Pattern 'function Test-RccAction' -Message 'Local and relay commands must share one strict action allowlist.'
Assert-Match -Text $protocol -Pattern 'function Get-RccRequestFingerprint' -Message 'Nonce reuse must be bound to the exact signed command.'
Assert-Match -Text $protocol -Pattern 'function Test-RccStatusQueryProof' -Message 'Local action status reads must require an HMAC proof.'
Assert-Match -Text $protocol -Pattern 'function Publish-RccActionStatus' -Message 'Completion state must be published over the configured authenticated relay channel.'
Assert-Match -Text $protocol -Pattern 'function Get-RccStatusAction' -Message 'Sensitive terminal text must be omitted from persistent action-status records.'
Assert-Match -Text $protocol -Pattern 'action = Get-RccStatusAction' -Message 'Terminal status records must contain only a safe action label.'
Assert-Match -Text $receiver -Pattern 'statusAction = Get-RccStatusAction' -Message 'Receiver deduplication and logs must use the sanitized action label.'
Assert-Match -Text $agent -Pattern 'statusAction = Get-RccStatusAction' -Message 'Fallback agent must use the same sanitized action label for status correlation.'
Assert-Match -Text $action -Pattern 'RemoteCommandCenterTerminalRunner\.ps1' -Message 'The action must launch the checked-in terminal runner.'
Assert-Match -Text $action -Pattern 'Get-RccWindowsTerminalRunnerArguments -PowerShellPath \$ps -RunnerArguments \$runnerArgs' -Message 'Windows Terminal must use the tested PowerShell command-line argument builder.'
Assert-NotMatch -Text $action -Pattern '\$runner\s*=\s*@"' -Message 'Terminal execution must not generate a per-request runner script.'
Assert-Match -Text $action -Pattern "PROOF_ONLY active; terminal command was not persisted or executed" -Message 'Proof-only terminal dispatch must return before creating command artifacts.'
Assert-Match -Text $action -Pattern 'ConvertFrom-RccBase64Url -Text \$EncodedLine' -Message 'Terminal execution must use the shared strict UTF-8 decoder.'
Assert-NotMatch -Text $action -Pattern 'function ConvertFrom-RccBase64Url' -Message 'Terminal decoding must not duplicate the protocol decoder.'
Assert-Match -Text $terminalRunner -Pattern '(?s)Remove-Item -LiteralPath \$CommandFile.*?Invoke-Expression \$commandText' -Message 'The static runner must delete the command file before invoking its contents.'
Assert-Match -Text $terminalRunner -Pattern 'RESULT_SUPPRESSED after-wait-deadline=True' -Message 'Late terminal completion must not create an orphan result after the bounded wait.'
Assert-NotMatch -Text $terminalRunner -Pattern 'Add-Content[^\r\n]*\$commandText|COMMAND_TEXT|preview=' -Message 'The static terminal runner must not log command contents.'
Assert-Match -Text $action -Pattern 'TERMINAL_RUNNER_RETURNED.*realWorldEffectsVerified=False' -Message 'Terminal completion must not claim real-world side effects were verified.'
Assert-NotMatch -Text $action -Pattern 'TERMINAL_LINE_READY.*preview=' -Message 'Terminal command contents must not be copied into action logs.'
Assert-Match -Text $receiver -Pattern 'test-force-terminal-dispatch-failure\.flag' -Message 'The receiver integration test must exercise terminal fallback dispatch failure.'
Assert-Match -Text $receiver -Pattern 'Terminal dispatch failed.*command body was not persisted to the fallback queue' -Message 'Terminal dispatch failure must not persist command bodies in the fallback queue.'
Assert-Match -Text $agent -Pattern 'Terminal dispatch failed.*command body was not copied into local storage' -Message 'Relay dispatch failure must not persist terminal command bodies locally.'
Assert-Match -Text $agent -Pattern "-State 'unconfirmed'.*-ExitCode 124" -Message 'Relay terminal dispatch failure must publish an unconfirmed signed status.'
Assert-Match -Text $trackedAction -Pattern 'if \(\$Action -like ''terminal_line:\*''\) \{ return 330 \}' -Message 'The tracked terminal worker must allow its bounded completion wait to finish.'
Assert-Match -Text $trackedAction -Pattern "Write-ActionStatus -State 'unconfirmed' -ExitCode 124" -Message 'Terminal completion timeout must be reported as unconfirmed.'

$actionTokens = $null
$actionParseErrors = $null
$actionAst = [System.Management.Automation.Language.Parser]::ParseInput($action, [ref]$actionTokens, [ref]$actionParseErrors)
$terminalArgumentFunction = $actionAst.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Get-RccWindowsTerminalRunnerArguments' }, $true)
Assert-True -Condition ($null -ne $terminalArgumentFunction) -Message 'The Windows Terminal command-line argument builder must exist.'
. ([scriptblock]::Create($terminalArgumentFunction.Extent.Text))
$samplePowerShellPath = 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe'
$sampleRunnerArguments = @('-NoExit','-ExecutionPolicy','Bypass','-File','C:\Rcc\runner.ps1')
$terminalArgumentVector = @(Get-RccWindowsTerminalRunnerArguments -PowerShellPath $samplePowerShellPath -RunnerArguments $sampleRunnerArguments)
Assert-True -Condition ($terminalArgumentVector.Count -eq ($sampleRunnerArguments.Count + 2) -and $terminalArgumentVector[0] -ceq 'new-tab' -and $terminalArgumentVector[1] -ceq $samplePowerShellPath -and $terminalArgumentVector[2] -ceq '-NoExit') -Message 'Windows Terminal must receive an executable first, then its PowerShell arguments.'

$versionCodeMatch = [regex]::Match($gradle, 'versionCode\s+(\d+)')
Assert-True -Condition $versionCodeMatch.Success -Message 'Android versionCode must be declared.'
Assert-True -Condition ([int]$versionCodeMatch.Groups[1].Value -ge 2) -Message 'Android versionCode must be incremented for deployment.'
$manifestPath = Join-Path $projectRoot 'app\src\main\AndroidManifest.xml'
$manifest = Get-Content -LiteralPath $manifestPath -Raw
Assert-Match -Text $manifest -Pattern 'ic_launcher_command_center' -Message 'The installed application must use the improved command-center launcher icon.'
Assert-True -Condition (Test-Path -LiteralPath (Join-Path $projectRoot 'app\src\main\res\drawable\ic_launcher_command_center.xml') -PathType Leaf) -Message 'Improved command-center launcher icon must exist.'

Write-Output 'REMOTE_COMMAND_CENTER_CONTRACT_TESTS_PASS'
