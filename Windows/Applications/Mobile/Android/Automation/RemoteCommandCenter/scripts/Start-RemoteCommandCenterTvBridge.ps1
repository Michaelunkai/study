param(
    [string]$ConfigPath = "$PSScriptRoot\rcc-config.json",
    [int]$Port = 8781,
    [string]$TvHost = $(if ($env:SAMSUNG_TV_HOST) { $env:SAMSUNG_TV_HOST } else { '192.168.1.173' })
)

$ErrorActionPreference = 'Stop'
$config = Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json
New-Item -ItemType Directory -Force -Path $config.StateDir, $config.LogDir | Out-Null
$log = Join-Path $config.LogDir 'tv-bridge-launcher.log'

function Write-TvBridgeLauncherLog {
    param([string]$Message)
    Add-Content -LiteralPath $log -Encoding UTF8 -Value ("[{0}] {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'), $Message)
}

$createdNew = $false
$mutex = New-Object System.Threading.Mutex($true, 'Global\RemoteCommandCenterTvBridge', [ref]$createdNew)
if (-not $createdNew) {
    Write-TvBridgeLauncherLog 'TV_BRIDGE_ALREADY_RUNNING exit=True'
    exit 0
}

try {
    $nodeCandidates = @(
        (Get-Command node.exe -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -First 1),
        (Join-Path $env:ProgramFiles 'nodejs\node.exe'),
        (Join-Path $env:LOCALAPPDATA 'OpenAI\CodexPatchedMobileSlash\app\resources\node.exe')
    ) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique

    $nodePath = ''
    foreach ($candidate in $nodeCandidates) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            $nodePath = $candidate
            break
        }
    }
    if ([string]::IsNullOrWhiteSpace($nodePath)) {
        throw 'node.exe was not found for RemoteCommandCenter TV bridge.'
    }

    $bridgeScript = Join-Path $PSScriptRoot 'samsung-tv-bridge.js'
    if (-not (Test-Path -LiteralPath $bridgeScript -PathType Leaf)) {
        throw "TV bridge script missing: $bridgeScript"
    }

    $env:RCC_TV_BRIDGE_PORT = [string]$Port
    $env:RCC_LOG_DIR = [string]$config.LogDir
    $env:SAMSUNG_TV_HOST = $TvHost
    $env:SAMSUNG_TV_CLIENT_NAME = 'Codex Samsung Remote'

    Write-TvBridgeLauncherLog "TV_BRIDGE_START node=`"$nodePath`" script=`"$bridgeScript`" port=$Port tvHost=$TvHost"
    & $nodePath $bridgeScript
} catch {
    Write-TvBridgeLauncherLog "TV_BRIDGE_FAILED error=`"$($_.Exception.Message)`""
    exit 1
} finally {
    try { $mutex.ReleaseMutex() | Out-Null } catch {}
    $mutex.Dispose()
    Write-TvBridgeLauncherLog 'TV_BRIDGE_STOPPED'
}
