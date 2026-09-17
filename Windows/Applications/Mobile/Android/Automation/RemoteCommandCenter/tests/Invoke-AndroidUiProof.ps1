param(
    [Parameter(Mandatory = $true)]
    [string]$Serial,
    [ValidateSet('UpdateSummary','TerminalIme','YouTube')]
    [string]$TestCase = 'UpdateSummary',
    [string]$SdkRoot = $env:ANDROID_SDK_ROOT,
    [string]$JdkRoot = $env:JAVA_HOME
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
if ([string]::IsNullOrWhiteSpace($Serial)) { throw 'Pass -Serial using the exact authorized ADB transport.' }
if ([string]::IsNullOrWhiteSpace($SdkRoot)) { $SdkRoot = $env:ANDROID_HOME }
if ([string]::IsNullOrWhiteSpace($SdkRoot)) { throw 'Pass -SdkRoot or set ANDROID_SDK_ROOT/ANDROID_HOME.' }
if ([string]::IsNullOrWhiteSpace($JdkRoot)) { throw 'Pass -JdkRoot or set JAVA_HOME.' }
if (-not (Test-Path -LiteralPath $SdkRoot -PathType Container)) { throw "Android SDK root was not found: $SdkRoot" }
if (-not (Test-Path -LiteralPath $JdkRoot -PathType Container)) { throw "JDK root was not found: $JdkRoot" }
$env:JAVA_HOME = $JdkRoot
$env:PATH = "$JdkRoot\bin;$env:PATH"
$adb = Join-Path $SdkRoot 'platform-tools\adb.exe'
if (-not (Test-Path -LiteralPath $adb -PathType Leaf)) { throw "ADB was not found under the selected Android SDK: $adb" }
$deviceState = & $adb -s $Serial get-state 2>$null
if ($LASTEXITCODE -ne 0 -or $deviceState -ne 'device') { throw 'The explicitly selected ADB transport is not ready.' }
$buildTools = Get-ChildItem -LiteralPath (Join-Path $SdkRoot 'build-tools') -Directory |
    Sort-Object Name -Descending | Select-Object -First 1
$platform = Get-ChildItem -LiteralPath (Join-Path $SdkRoot 'platforms') -Directory |
    Sort-Object Name -Descending | Select-Object -First 1
if (-not $buildTools -or -not $platform) { throw 'Android SDK build tools/platform not found.' }

$runId = '{0}-{1}' -f (Get-Date -Format 'yyyyMMdd-HHmmss-fff'), [guid]::NewGuid().ToString('N')
$work = Join-Path $env:TEMP ("RemoteCommandCenter-ui-proof-$runId")
$classes = Join-Path $work 'classes'
$stubs = Join-Path $work 'stubs'
$dex = Join-Path $work 'dex'
New-Item -ItemType Directory -Force -Path $classes, $stubs, $dex | Out-Null

$androidJar = Join-Path $platform.FullName 'android.jar'
$compileUiAutomatorJar = Join-Path $platform.FullName 'uiautomator.jar'
if (-not (Test-Path -LiteralPath $compileUiAutomatorJar)) {
    throw "SDK UiAutomator compile jar not found: $compileUiAutomatorJar"
}
$javac = Join-Path $JdkRoot 'bin\javac.exe'
$jar = Join-Path $JdkRoot 'bin\jar.exe'
$d8 = Join-Path $buildTools.FullName 'd8.bat'
$source = Join-Path $root 'tests\android\RemoteCommandCenterUiTest.java'
$repetitiveTestSource = Join-Path $root 'tests\android\android\test\RepetitiveTest.java'
$testCaseStub = Join-Path $root 'tests\android-stubs\junit\framework\TestCase.java'
& $javac -encoding UTF-8 -source 8 -target 8 -d $stubs $testCaseStub
if ($LASTEXITCODE -ne 0) { throw 'UiAutomator JUnit compile stub failed.' }
& $javac -encoding UTF-8 -source 8 -target 8 -classpath "$androidJar;$compileUiAutomatorJar;$stubs" -d $classes $source $repetitiveTestSource
if ($LASTEXITCODE -ne 0) { throw 'UiAutomator proof javac failed.' }

$classesJar = Join-Path $work 'classes.jar'
Push-Location $classes
try {
    & $jar cf $classesJar .
    if ($LASTEXITCODE -ne 0) { throw 'UiAutomator proof jar failed.' }
} finally {
    Pop-Location
}

& $d8 --min-api 26 --lib $androidJar --classpath $compileUiAutomatorJar --output $dex $classesJar
if ($LASTEXITCODE -ne 0) { throw 'UiAutomator proof d8 failed.' }

$testJar = Join-Path $work 'RemoteCommandCenterUiTest.jar'
Copy-Item -LiteralPath $classesJar -Destination $testJar -Force
Push-Location $dex
try {
    & $jar uf $testJar classes.dex
    if ($LASTEXITCODE -ne 0) { throw 'UiAutomator proof dex packaging failed.' }
} finally {
    Pop-Location
}

$deviceJar = "/data/local/tmp/RemoteCommandCenterUiTest-$runId.jar"
& $adb -s $Serial push $testJar $deviceJar | Out-Host
if ($LASTEXITCODE -ne 0) { throw 'Unable to push UiAutomator proof jar.' }
& $adb -s $Serial shell cmd statusbar collapse
& $adb -s $Serial shell am force-stop com.mich.remotecommandcenter
& $adb -s $Serial shell am start -W -n com.mich.remotecommandcenter/.MainActivity | Out-Host
$testMethod = switch ($TestCase) {
    'UpdateSummary' { 'testWhatChangedDialogShowsInstalledBuildSummary' }
    'TerminalIme' { 'testTerminalImeWaitsForPowerShellLineReturn' }
    'YouTube' { 'testClickYouTubeButtonOnce' }
}
$expectedMarker = switch ($TestCase) {
    'UpdateSummary' { 'REMOTE_COMMAND_CENTER_UPDATE_SUMMARY_PASS' }
    'TerminalIme' { 'REMOTE_COMMAND_CENTER_TERMINAL_IME_COMPLETION_PASS' }
    'YouTube' { 'REMOTE_COMMAND_CENTER_YOUTUBE_ACTION_COMPLETED' }
}
$runnerOutput = @(& $adb -s $Serial shell uiautomator runtest $deviceJar `
    -c "com.mich.remotecommandcenter.test.RemoteCommandCenterUiTest#$testMethod" 2>&1)
$runnerOutput | Out-Host
$runnerText = $runnerOutput -join "`n"
if ($LASTEXITCODE -ne 0 -or
    $runnerText -match 'aborted|FAILURES!!!' -or
    $runnerText -notmatch [regex]::Escape($expectedMarker) -or
    $runnerText -notmatch 'OK \(1 test\)') {
    throw "$TestCase installed-app UiAutomator proof failed. Build/test artifacts are preserved at $work."
}

Write-Output "REMOTE_COMMAND_CENTER_ANDROID_UI_PASS testCase=$TestCase artifacts=$work"
