param(
    [string]$ConfigPath = "$PSScriptRoot\rcc-config.json",
    [switch]$Stop,
    [int]$PollMilliseconds = 80,
    [int]$IntentWindowMilliseconds = 900
)

$ErrorActionPreference = 'Stop'
$config = Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json
New-Item -ItemType Directory -Force -Path $config.StateDir, $config.LogDir | Out-Null
$stopSignal = Join-Path $config.StateDir 'moonlight-focus-guardian.stop'
$log = Join-Path $config.LogDir 'moonlight-focus-guardian.log'

function Write-FocusLog {
    param([string]$Message)
    Add-Content -LiteralPath $log -Encoding UTF8 -Value ("[{0}] {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'), $Message)
}

if ($Stop) {
    [IO.File]::WriteAllText($stopSignal, [DateTimeOffset]::UtcNow.ToString('o'))
    Write-FocusLog 'FOCUS_GUARDIAN_STOP_REQUESTED'
    exit 0
}

if (Test-Path -LiteralPath $stopSignal -PathType Leaf) {
    [IO.File]::Delete($stopSignal)
}

$createdNew = $false
$mutex = New-Object Threading.Mutex($true, 'Global\RemoteCommandCenterMoonlightFocusGuardian', [ref]$createdNew)
if (-not $createdNew) {
    Write-FocusLog 'FOCUS_GUARDIAN_ALREADY_RUNNING'
    exit 0
}

Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class RccFocusNative {
    [StructLayout(LayoutKind.Sequential)]
    public struct RECT { public int Left, Top, Right, Bottom; }
    [StructLayout(LayoutKind.Sequential)]
    public struct LASTINPUTINFO { public uint cbSize; public uint dwTime; }
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] public static extern bool IsWindow(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT rect);
    [DllImport("user32.dll")] public static extern IntPtr MonitorFromWindow(IntPtr hWnd, uint flags);
    [DllImport("user32.dll")] public static extern bool GetMonitorInfo(IntPtr monitor, ref MONITORINFO info);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint processId);
    [DllImport("user32.dll")] public static extern bool AttachThreadInput(uint attach, uint attachTo, bool value);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern bool BringWindowToTop(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern bool GetLastInputInfo(ref LASTINPUTINFO info);
    [DllImport("kernel32.dll")] public static extern ulong GetTickCount64();
    [StructLayout(LayoutKind.Sequential)]
    public struct MONITORINFO {
        public uint cbSize;
        public RECT rcMonitor;
        public RECT rcWork;
        public uint dwFlags;
    }
}
'@

function Get-EncoderSessionCount {
    foreach ($candidate in @(
        (Join-Path $env:SystemRoot 'System32\nvidia-smi.exe'),
        'C:\Program Files\NVIDIA Corporation\NVSMI\nvidia-smi.exe'
    )) {
        if (-not (Test-Path -LiteralPath $candidate -PathType Leaf)) { continue }
        $output = & $candidate '--query-gpu=encoder.stats.sessionCount' '--format=csv,noheader,nounits' 2>$null
        if ($LASTEXITCODE -ne 0) { continue }
        $total = 0
        foreach ($line in @($output)) {
            $value = 0
            if ([int]::TryParse(([string]$line).Trim(), [ref]$value)) { $total += $value }
        }
        return $total
    }
    return 0
}

function Get-WindowInfo {
    param([IntPtr]$Handle)
    if ($Handle -eq [IntPtr]::Zero -or -not [RccFocusNative]::IsWindow($Handle) -or -not [RccFocusNative]::IsWindowVisible($Handle)) {
        return $null
    }
    $processId = [uint32]0
    [void][RccFocusNative]::GetWindowThreadProcessId($Handle, [ref]$processId)
    $process = Get-Process -Id $processId -ErrorAction SilentlyContinue
    if (-not $process) { return $null }
    $windowRect = New-Object RccFocusNative+RECT
    if (-not [RccFocusNative]::GetWindowRect($Handle, [ref]$windowRect)) { return $null }
    $monitor = [RccFocusNative]::MonitorFromWindow($Handle, 2)
    $monitorInfo = New-Object RccFocusNative+MONITORINFO
    $monitorInfo.cbSize = [Runtime.InteropServices.Marshal]::SizeOf([type]'RccFocusNative+MONITORINFO')
    if (-not [RccFocusNative]::GetMonitorInfo($monitor, [ref]$monitorInfo)) { return $null }
    $windowArea = [math]::Max(0, $windowRect.Right - $windowRect.Left) * [math]::Max(0, $windowRect.Bottom - $windowRect.Top)
    $monitorArea = [math]::Max(1, $monitorInfo.rcMonitor.Right - $monitorInfo.rcMonitor.Left) * [math]::Max(1, $monitorInfo.rcMonitor.Bottom - $monitorInfo.rcMonitor.Top)
    [pscustomobject]@{
        Handle = $Handle
        ProcessId = [int]$processId
        ProcessName = $process.ProcessName
        Coverage = [double]$windowArea / [double]$monitorArea
    }
}

function Test-RecentIntentionalInput {
    $info = New-Object RccFocusNative+LASTINPUTINFO
    $info.cbSize = [Runtime.InteropServices.Marshal]::SizeOf([type]'RccFocusNative+LASTINPUTINFO')
    if (-not [RccFocusNative]::GetLastInputInfo([ref]$info)) { return $false }
    $elapsed = [RccFocusNative]::GetTickCount64() - [uint64]$info.dwTime
    return $elapsed -le [uint64]$IntentWindowMilliseconds
}

function Restore-ProtectedWindow {
    param([IntPtr]$Handle)
    if (-not [RccFocusNative]::IsWindow($Handle)) { return $false }
    $foreground = [RccFocusNative]::GetForegroundWindow()
    $foregroundProcessId = [uint32]0
    $protectedProcessId = [uint32]0
    $foregroundThread = [RccFocusNative]::GetWindowThreadProcessId($foreground, [ref]$foregroundProcessId)
    $protectedThread = [RccFocusNative]::GetWindowThreadProcessId($Handle, [ref]$protectedProcessId)
    $attached = $false
    try {
        if ($foregroundThread -ne $protectedThread) {
            $attached = [RccFocusNative]::AttachThreadInput($foregroundThread, $protectedThread, $true)
        }
        [void][RccFocusNative]::BringWindowToTop($Handle)
        return [RccFocusNative]::SetForegroundWindow($Handle)
    } finally {
        if ($attached) { [void][RccFocusNative]::AttachThreadInput($foregroundThread, $protectedThread, $false) }
    }
}

$excludedProcesses = @(
    'explorer', 'SearchHost', 'StartMenuExperienceHost', 'ShellExperienceHost', 'TextInputHost',
    'ApplicationFrameHost', 'WindowsTerminal', 'OpenConsole', 'conhost', 'cmd', 'powershell', 'pwsh',
    'ChatGPT', 'codex', 'RuntimeBroker', 'SystemSettings'
)
$sunshineOutput = ''
try {
    $match = Select-String -LiteralPath 'C:\Program Files\Sunshine\config\sunshine.conf' -Pattern '^\s*output_name\s*=\s*(.+?)\s*$' | Select-Object -First 1
    if ($match) { $sunshineOutput = $match.Matches[0].Groups[1].Value }
} catch {}

$protected = [IntPtr]::Zero
$protectedPid = 0
$emptySessionChecks = 0
try {
    Write-FocusLog "FOCUS_GUARDIAN_STARTED output=$sunshineOutput pollMs=$PollMilliseconds intentMs=$IntentWindowMilliseconds"
    while (-not (Test-Path -LiteralPath $stopSignal -PathType Leaf)) {
        $sessions = Get-EncoderSessionCount
        if ($sessions -le 0) {
            $emptySessionChecks++
            if ($emptySessionChecks -ge 3) { break }
            Start-Sleep -Milliseconds 500
            continue
        }
        $emptySessionChecks = 0

        $foreground = [RccFocusNative]::GetForegroundWindow()
        $info = Get-WindowInfo -Handle $foreground
        if ($protected -eq [IntPtr]::Zero -or -not [RccFocusNative]::IsWindow($protected)) {
            if ($info -and $info.Coverage -ge 0.82 -and $info.ProcessName -notin $excludedProcesses) {
                $protected = $info.Handle
                $protectedPid = $info.ProcessId
                Write-FocusLog "FOCUS_PROTECTED_SET pid=$protectedPid process=$($info.ProcessName) coverage=$([math]::Round($info.Coverage,3))"
            }
        } elseif ($foreground -ne $protected) {
            if ($info -and $info.ProcessId -eq $protectedPid) {
                $protected = $info.Handle
            } elseif (Test-RecentIntentionalInput) {
                if ($info -and $info.Coverage -ge 0.82 -and $info.ProcessName -notin $excludedProcesses) {
                    $protected = $info.Handle
                    $protectedPid = $info.ProcessId
                    Write-FocusLog "FOCUS_PROTECTED_CHANGED_INTENTIONALLY pid=$protectedPid process=$($info.ProcessName)"
                }
            } else {
                Start-Sleep -Milliseconds 80
                if ([RccFocusNative]::GetForegroundWindow() -ne $protected -and (Restore-ProtectedWindow -Handle $protected)) {
                    Write-FocusLog "FOCUS_STEAL_BLOCKED protectedPid=$protectedPid stealingProcess=$($info.ProcessName)"
                }
            }
        }
        Start-Sleep -Milliseconds ([math]::Max(40, $PollMilliseconds))
    }
} finally {
    Write-FocusLog 'FOCUS_GUARDIAN_STOPPED'
    try { $mutex.ReleaseMutex() | Out-Null } catch {}
    $mutex.Dispose()
}
