param(
    [string]$SdkRoot = 'C:\Users\micha\bubblewrap-tools\android_sdk',
    [string]$JdkRoot = 'C:\Users\micha\android-build-tools\jdk'
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$env:JAVA_HOME = $JdkRoot
$env:PATH = "$JdkRoot\bin;$env:PATH"
$env:_JAVA_OPTIONS = '-Xmx128m -XX:ReservedCodeCacheSize=32m -XX:+UseSerialGC'

$buildTools = Get-ChildItem -LiteralPath (Join-Path $SdkRoot 'build-tools') -Directory | Sort-Object Name -Descending | Select-Object -First 1
$platform = Get-ChildItem -LiteralPath (Join-Path $SdkRoot 'platforms') -Directory | Sort-Object Name -Descending | Select-Object -First 1
if (-not $buildTools) { throw "No Android build-tools under $SdkRoot" }
if (-not $platform) { throw "No Android platforms under $SdkRoot" }

$aapt2 = Join-Path $buildTools.FullName 'aapt2.exe'
$d8 = Join-Path $buildTools.FullName 'd8.bat'
$zipalign = Join-Path $buildTools.FullName 'zipalign.exe'
$apksigner = Join-Path $buildTools.FullName 'apksigner.bat'
$androidJar = Join-Path $platform.FullName 'android.jar'
$javac = Join-Path $JdkRoot 'bin\javac.exe'
$jar = Join-Path $JdkRoot 'bin\jar.exe'
$keytool = Join-Path $JdkRoot 'bin\keytool.exe'
$gradleText = Get-Content -LiteralPath (Join-Path $root 'app\build.gradle') -Raw
$versionCodeMatch = [regex]::Match($gradleText, 'versionCode\s+(\d+)')
$versionNameMatch = [regex]::Match($gradleText, 'versionName\s+"([^"]+)"')
if (-not $versionCodeMatch.Success -or -not $versionNameMatch.Success) {
    throw 'Unable to resolve Android versionCode/versionName from app\build.gradle'
}
$versionCode = $versionCodeMatch.Groups[1].Value
$versionName = $versionNameMatch.Groups[1].Value

$out = Join-Path $root 'artifacts\build-output'
$work = Join-Path $out 'work'
$compiled = Join-Path $work 'compiled'
$gen = Join-Path $work 'gen'
$classes = Join-Path $work 'classes'
$dex = Join-Path $work 'dex'
Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path $compiled, $gen, $classes, $dex, $out | Out-Null

& $aapt2 compile --dir (Join-Path $root 'app\src\main\res') -o $compiled
if ($LASTEXITCODE -ne 0) { throw "aapt2 compile failed" }

$unsigned = Join-Path $work 'unsigned.apk'
$flatFiles = Get-ChildItem -LiteralPath $compiled -Filter *.flat | ForEach-Object { $_.FullName }
& $aapt2 link -o $unsigned -I $androidJar --manifest (Join-Path $root 'app\src\main\AndroidManifest.xml') --java $gen --auto-add-overlay --min-sdk-version 26 --target-sdk-version 35 --version-code $versionCode --version-name $versionName $flatFiles
if ($LASTEXITCODE -ne 0) { throw "aapt2 link failed" }

$sources = @()
$sources += Get-ChildItem -LiteralPath (Join-Path $root 'app\src\main\java') -Recurse -Filter *.java | ForEach-Object { $_.FullName }
$sources += Get-ChildItem -LiteralPath $gen -Recurse -Filter *.java | ForEach-Object { $_.FullName }
& $javac -encoding UTF-8 -source 11 -target 11 -classpath $androidJar -d $classes $sources
if ($LASTEXITCODE -ne 0) { throw "javac failed" }

$classesJar = Join-Path $work 'classes.jar'
Push-Location $classes
try {
    & $jar cf $classesJar .
    if ($LASTEXITCODE -ne 0) { throw "jar classes failed" }
} finally {
    Pop-Location
}

& $d8 --min-api 26 --lib $androidJar --output $dex $classesJar
if ($LASTEXITCODE -ne 0) { throw "d8 failed" }

Copy-Item -LiteralPath $unsigned -Destination (Join-Path $work 'with-classes.apk') -Force
Push-Location $dex
try {
    & $jar uf (Join-Path $work 'with-classes.apk') 'classes.dex'
    if ($LASTEXITCODE -ne 0) { throw "jar update failed" }
} finally {
    Pop-Location
}

$aligned = Join-Path $work 'aligned.apk'
& $zipalign -f 4 (Join-Path $work 'with-classes.apk') $aligned
if ($LASTEXITCODE -ne 0) { throw "zipalign failed" }

$keystore = Join-Path $out 'debug.keystore'
if (-not (Test-Path -LiteralPath $keystore)) {
    & $keytool -genkeypair -v -keystore $keystore -storepass android -alias androiddebugkey -keypass android -keyalg RSA -keysize 2048 -validity 10000 -dname 'CN=Android Debug,O=Android,C=US'
    if ($LASTEXITCODE -ne 0) { throw "keytool failed" }
}

$apk = Join-Path $out 'RemoteCommandCenter-debug.apk'
& $apksigner sign --ks $keystore --ks-pass pass:android --key-pass pass:android --out $apk $aligned
if ($LASTEXITCODE -ne 0) { throw "apksigner failed" }
& $apksigner verify --verbose $apk
if ($LASTEXITCODE -ne 0) { throw "apksigner verify failed" }

Write-Output $apk

