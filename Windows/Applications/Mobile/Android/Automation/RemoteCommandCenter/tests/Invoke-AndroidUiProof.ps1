param(
    [string]$Serial = '192.168.1.124:41521',
    [ValidateSet('YouTube')]
    [string]$Button = 'YouTube',
    [string]$SdkRoot = 'C:\Users\micha\bubblewrap-tools\android_sdk',
    [string]$JdkRoot = 'C:\Users\micha\android-build-tools\jdk'
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$env:JAVA_HOME = $JdkRoot
$env:PATH = "$JdkRoot\bin;$env:PATH"
$adb = 'C:\Users\micha\AppData\Local\Android\platform-tools\adb.exe'
$buildTools = Get-ChildItem -LiteralPath (Join-Path $SdkRoot 'build-tools') -Directory |
    Sort-Object Name -Descending | Select-Object -First 1
$platform = Get-ChildItem -LiteralPath (Join-Path $SdkRoot 'platforms') -Directory |
    Sort-Object Name -Descending | Select-Object -First 1
if (-not $buildTools -or -not $platform) { throw 'Android SDK build tools/platform not found.' }

$work = Join-Path $root 'artifacts\ui-proof'
$classes = Join-Path $work 'classes'
$stubs = Join-Path $work 'stubs'
$dex = Join-Path $work 'dex'
Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue
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

& $adb -s $Serial push $testJar /data/local/tmp/RemoteCommandCenterUiTest.jar | Out-Host
if ($LASTEXITCODE -ne 0) { throw 'Unable to push UiAutomator proof jar.' }
& $adb -s $Serial shell cmd statusbar collapse
& $adb -s $Serial shell am force-stop com.mich.remotecommandcenter
& $adb -s $Serial shell am start -W -n com.mich.remotecommandcenter/.MainActivity | Out-Host
$runnerOutput = @(& $adb -s $Serial shell uiautomator runtest /data/local/tmp/RemoteCommandCenterUiTest.jar `
    -c com.mich.remotecommandcenter.test.RemoteCommandCenterUiTest#testClickYouTubeButtonOnce 2>&1)
$runnerOutput | Out-Host
$runnerText = $runnerOutput -join "`n"
if ($LASTEXITCODE -ne 0 -or
    $runnerText -match 'aborted|FAILURES!!!' -or
    $runnerText -notmatch 'REMOTE_COMMAND_CENTER_YOUTUBE_VIEW_CLICK_INJECTED' -or
    $runnerText -notmatch 'OK \(1 test\)') {
    throw "$Button installed-button UiAutomator proof failed."
}

Write-Output "REMOTE_COMMAND_CENTER_ANDROID_UI_CLICK_PASS button=$Button"
