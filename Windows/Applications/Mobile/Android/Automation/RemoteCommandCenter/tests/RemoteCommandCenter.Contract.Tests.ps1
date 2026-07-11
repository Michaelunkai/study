$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$receiverPath = Join-Path $projectRoot 'scripts\Start-RemoteCommandCenterHttpReceiver.ps1'
$actionPath = Join-Path $projectRoot 'scripts\Invoke-RemoteCommandCenterAction.ps1'
$trackedActionPath = Join-Path $projectRoot 'scripts\Invoke-RemoteCommandCenterTrackedAction.ps1'
$codexRestartPath = Join-Path $projectRoot 'scripts\Restart-CodexDesktopApp.ps1'
$focusGuardianPath = Join-Path $projectRoot 'scripts\Start-RemoteCommandCenterMoonlightFocusGuardian.ps1'
$wakeSettingsPath = Join-Path $projectRoot 'scripts\Ensure-RemoteCommandCenterWakeSettings.ps1'
$mainActivityPath = Join-Path $projectRoot 'app\src\main\java\com\mich\remotecommandcenter\MainActivity.java'
$gradlePath = Join-Path $projectRoot 'app\build.gradle'
$tizenTubeLauncherPath = 'F:\study\Systems\Windows\Media\GameStreaming\SamsungTizenMoonlightHostKit\scripts\Recovery\Start-TizenTubeAutoLaunch.ps1'
$tizenTubeModuleControlPath = 'F:\study\Systems\Windows\Media\GameStreaming\SamsungTizenMoonlightHostKit\scripts\Recovery\TizenBrewModuleControl.js'

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
$action = Get-Content -LiteralPath $actionPath -Raw
$trackedAction = Get-Content -LiteralPath $trackedActionPath -Raw
$mainActivity = Get-Content -LiteralPath $mainActivityPath -Raw
$gradle = Get-Content -LiteralPath $gradlePath -Raw

Assert-True -Condition (Test-Path -LiteralPath $trackedActionPath -PathType Leaf) -Message 'Tracked action wrapper must exist.'
Assert-Match -Text $receiver -Pattern 'Invoke-RemoteCommandCenterTrackedAction\.ps1' -Message 'Receiver must launch the tracked action wrapper.'
Assert-Match -Text $receiver -Pattern 'duplicate' -Message 'Receiver must return an idempotent duplicate result for a reused nonce.'
Assert-Match -Text $receiver -Pattern 'actionStatus' -Message 'Status endpoint must expose correlated action completion state.'

Assert-Match -Text $action -Pattern "'tv_force_reboot'\s*\{\s*Invoke-SamsungTvSdbReboot" -Message 'TV reboot must invoke the real SDB reboot path.'
Assert-Match -Text $action -Pattern 'C:\\Users\\micha\\Downloads\\tizen-official-tools\\tizen-sdk-10\\tools\\sdb\.exe' -Message 'Official installed SDB path must be resolved.'
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
Assert-True -Condition (Test-Path -LiteralPath $tizenTubeLauncherPath -PathType Leaf) -Message 'TizenTube launcher must exist.'
$tizenTubeLauncher = Get-Content -LiteralPath $tizenTubeLauncherPath -Raw
Assert-Match -Text $tizenTubeLauncher -Pattern 'function Test-TizenBrewModuleChannelReady' -Message 'TizenTube launcher must preflight the local module channel before using it.'
Assert-Match -Text $tizenTubeLauncher -Pattern 'if \(Test-TizenBrewModuleChannelReady\) \{' -Message 'TizenTube launcher must skip unavailable SDB/module control instead of blocking the launch.'
Assert-Match -Text $tizenTubeLauncher -Pattern 'TIZENBREW_MODULE_CONTROL_SKIPPED reason=local-channel-unavailable' -Message 'TizenTube launcher must record a bounded module-control skip before fallback.'
Assert-Match -Text $tizenTubeLauncher -Pattern '\$sequence\s*=\s*@\(''KEY_DOWN'',\s*''KEY_LEFT'',\s*''KEY_ENTER''\)' -Message 'TizenBrew fallback must use the known-good one-pass card sequence.'
Assert-Match -Text $tizenTubeLauncher -Pattern 'TIZENBREW_CARD_SURFACE_WAIT milliseconds=4500' -Message 'A freshly launched TizenBrew must wait for its card surface before navigation.'
Assert-Match -Text $tizenTubeLauncher -Pattern 'Send-TvKeySequence\s+\(@\(''--delay-ms=900''\)\s+\+\s+\$sequence\)' -Message 'Fresh TizenBrew navigation must use the verified 900 ms card-key cadence.'
Assert-Match -Text $tizenTubeLauncher -Pattern 'TIZENTUBE_LAUNCHER_ERROR' -Message 'TizenTube launcher errors must be surfaced instead of silently swallowed.'
$startTizenBrew = [regex]::Match($tizenTubeLauncher, '(?s)function Start-TizenBrew\s*\{.*?(?=\s*function Enter-TizenTubeModule)').Value
Assert-True -Condition ($startTizenBrew.Length -gt 0) -Message 'TizenBrew launcher function must exist.'
Assert-NotMatch -Text $startTizenBrew -Pattern 'Write-Output' -Message 'TizenBrew launch status must not contaminate the boolean fresh-launch result.'
Assert-Match -Text $trackedAction -Pattern 'Get-ActionTimeoutSeconds' -Message 'Tracked actions must have an explicit bounded timeout policy.'
Assert-Match -Text $trackedAction -Pattern "'youtube_tizen'\s*\{\s*return\s+100\s*\}" -Message 'YouTube actions must leave enough bounded time for TV-control service recovery without keeping single-flight locked.'
Assert-True -Condition (Test-Path -LiteralPath $tizenTubeModuleControlPath -PathType Leaf) -Message 'TizenBrew module-control helper must exist.'
$tizenTubeModuleControl = Get-Content -LiteralPath $tizenTubeModuleControlPath -Raw
Assert-NotMatch -Text $tizenTubeModuleControl -Pattern 'spawnSync|TIZENBREW_SDB|sdbTarget' -Message 'Module control must not create an SDB forward on the button critical path.'
Assert-True -Condition (Test-Path -LiteralPath $focusGuardianPath -PathType Leaf) -Message 'Moonlight focus guardian must exist.'
Assert-Match -Text $action -Pattern 'Start-RemoteCommandCenterMoonlightFocusGuardian\.ps1' -Message 'Moonlight toggle must start and stop the session-bound focus guardian.'
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
Assert-Match -Text $mainActivity -Pattern 'waitForActionCompletion' -Message 'Android must consume correlated action completion state.'
Assert-Match -Text $mainActivity -Pattern 'Timed out waiting for' -Message 'Android must fail visibly when a receiver action never completes instead of reporting queued success.'
Assert-NotMatch -Text $mainActivity -Pattern 'sendWakePacketsBurst\(420,\s*0,\s*0\)' -Message 'Wake must not send a 420-loop packet storm.'
Assert-NotMatch -Text $mainActivity -Pattern 'sendWakePacketsBurst\(0,\s*1200,\s*50\)' -Message 'Wake must not send a 1200-loop background packet storm.'
$youtubeHandler = [regex]::Match($mainActivity, '(?s)private void sendYoutubeTizen\(Command command\).*?(?=\s+private boolean launchTizenBrewDirect)').Value
Assert-True -Condition ($youtubeHandler.Length -gt 0) -Message 'YouTube dispatch handler must exist.'
Assert-Match -Text $youtubeHandler -Pattern 'TIZENTUBE_RECEIVER_ONLY_DISPATCH' -Message 'YouTube must route through the paired PC controller.'
Assert-Match -Text $youtubeHandler -Pattern 'sendCommandViaReceiver\(command\.id\)' -Message 'YouTube must submit exactly one receiver action.'
Assert-NotMatch -Text $youtubeHandler -Pattern 'launchTizenBrewDirect|sendSamsungTv|openSamsungTvSocket' -Message 'YouTube must never open a Samsung remote connection from Android.'
Assert-Match -Text $mainActivity -Pattern '(?s)private boolean canTryDirectTv\(\)\s*\{.*?return false;' -Message 'Android Samsung remote sockets must stay disabled to prevent TV authorization dialogs.'

$versionCodeMatch = [regex]::Match($gradle, 'versionCode\s+(\d+)')
Assert-True -Condition $versionCodeMatch.Success -Message 'Android versionCode must be declared.'
Assert-True -Condition ([int]$versionCodeMatch.Groups[1].Value -ge 2) -Message 'Android versionCode must be incremented for deployment.'
$manifestPath = Join-Path $projectRoot 'app\src\main\AndroidManifest.xml'
$manifest = Get-Content -LiteralPath $manifestPath -Raw
Assert-Match -Text $manifest -Pattern 'ic_launcher_command_center' -Message 'The installed application must use the improved command-center launcher icon.'
Assert-True -Condition (Test-Path -LiteralPath (Join-Path $projectRoot 'app\src\main\res\drawable\ic_launcher_command_center.xml') -PathType Leaf) -Message 'Improved command-center launcher icon must exist.'

Write-Output 'REMOTE_COMMAND_CENTER_CONTRACT_TESTS_PASS'
