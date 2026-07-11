param(
    [string]$ConfigPath = "$PSScriptRoot\rcc-config.json"
)

$ErrorActionPreference = 'Continue'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$createdNew = $false
$mutex = New-Object System.Threading.Mutex($true, 'Global\RemoteCommandCenterTray', [ref]$createdNew)
if (-not $createdNew) {
    exit 0
}

$config = Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json
New-Item -ItemType Directory -Force -Path $config.StateDir, $config.LogDir | Out-Null
$log = Join-Path $config.LogDir 'tray.log'
$iconPath = Join-Path $config.StateDir 'RemoteCommandCenterTray.ico'

function Write-TrayLog {
    param([string]$Message)
    Add-Content -LiteralPath $log -Encoding UTF8 -Value ("[{0}] {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'), $Message)
}

function New-TrayIconFile {
    param([string]$Path)
    if (Test-Path -LiteralPath $Path) { return }
    $bitmap = New-Object System.Drawing.Bitmap 64, 64
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.Clear([System.Drawing.Color]::FromArgb(8, 17, 31))
    $brush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(20, 184, 166))
    $graphics.FillEllipse($brush, 6, 6, 52, 52)
    $font = New-Object System.Drawing.Font 'Segoe UI', 28, ([System.Drawing.FontStyle]::Bold), ([System.Drawing.GraphicsUnit]::Pixel)
    $textBrush = [System.Drawing.Brushes]::White
    $format = New-Object System.Drawing.StringFormat
    $format.Alignment = [System.Drawing.StringAlignment]::Center
    $format.LineAlignment = [System.Drawing.StringAlignment]::Center
    $graphics.DrawString('R', $font, $textBrush, (New-Object System.Drawing.RectangleF 0, 0, 64, 64), $format)
    $icon = [System.Drawing.Icon]::FromHandle($bitmap.GetHicon())
    $stream = [System.IO.File]::Create($Path)
    try { $icon.Save($stream) } finally { $stream.Dispose(); $graphics.Dispose(); $bitmap.Dispose(); $brush.Dispose(); $font.Dispose(); $format.Dispose() }
}

function Stop-ChildProcess {
    param($Process)
    if ($null -ne $Process -and -not $Process.HasExited) {
        Stop-Process -Id $Process.Id -Force -ErrorAction SilentlyContinue
    }
}

New-TrayIconFile -Path $iconPath
$psExe = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
$agentScript = Join-Path $PSScriptRoot 'Start-RemoteCommandCenterAgent.ps1'
$httpScript = Join-Path $PSScriptRoot 'Start-RemoteCommandCenterHttpReceiver.ps1'
$powerGuardScript = Join-Path $PSScriptRoot 'Start-RemoteCommandCenterPowerGuard.ps1'
$moonlightGuardScript = Join-Path $PSScriptRoot 'Start-RemoteCommandCenterMoonlightGuard.ps1'
$tvBridgeScript = Join-Path $PSScriptRoot 'Start-RemoteCommandCenterTvBridge.ps1'
$commonArgs = @('-NoProfile','-ExecutionPolicy','Bypass')

$agent = Start-Process -FilePath $psExe -ArgumentList ($commonArgs + @('-File', $agentScript, '-ConfigPath', $ConfigPath)) -WindowStyle Hidden -PassThru
$http = Start-Process -FilePath $psExe -ArgumentList ($commonArgs + @('-File', $httpScript, '-ConfigPath', $ConfigPath, '-Port', [string]$config.LocalPort)) -WindowStyle Hidden -PassThru
$powerGuard = Start-Process -FilePath $psExe -ArgumentList ($commonArgs + @('-File', $powerGuardScript, '-ConfigPath', $ConfigPath, '-IntervalSeconds', '5')) -WindowStyle Hidden -PassThru
$moonlightGuard = Start-Process -FilePath $psExe -ArgumentList ($commonArgs + @('-File', $moonlightGuardScript, '-ConfigPath', $ConfigPath, '-IntervalSeconds', '300')) -WindowStyle Hidden -PassThru
$tvBridge = Start-Process -FilePath $psExe -ArgumentList ($commonArgs + @('-File', $tvBridgeScript, '-ConfigPath', $ConfigPath, '-Port', '8781')) -WindowStyle Hidden -PassThru
Write-TrayLog "Tray started agentPid=$($agent.Id) httpPid=$($http.Id) powerGuardPid=$($powerGuard.Id) moonlightGuardPid=$($moonlightGuard.Id) tvBridgePid=$($tvBridge.Id)"

$notify = New-Object System.Windows.Forms.NotifyIcon
$notify.Icon = New-Object System.Drawing.Icon $iconPath
$notify.Text = 'Remote Command Center running'
$notify.Visible = $true

$menu = New-Object System.Windows.Forms.ContextMenuStrip
$statusItem = $menu.Items.Add('Remote Command Center running')
$statusItem.Enabled = $false
$exitItem = $menu.Items.Add('Stop Remote Command Center')
$exitItem.Add_Click({
    Write-TrayLog 'Tray exit requested.'
    $notify.Visible = $false
    [System.Windows.Forms.Application]::Exit()
})
$notify.ContextMenuStrip = $menu
$notify.Add_DoubleClick({
    Write-TrayLog 'Tray double-click stop requested.'
    $notify.Visible = $false
    [System.Windows.Forms.Application]::Exit()
})

try {
    [System.Windows.Forms.Application]::Run()
} finally {
    $notify.Visible = $false
    $notify.Dispose()
    Stop-ChildProcess -Process $agent
    Stop-ChildProcess -Process $http
    Stop-ChildProcess -Process $powerGuard
    Stop-ChildProcess -Process $moonlightGuard
    Stop-ChildProcess -Process $tvBridge
    try { $mutex.ReleaseMutex() | Out-Null } catch {}
    $mutex.Dispose()
    Write-TrayLog 'Tray stopped child processes.'
}
