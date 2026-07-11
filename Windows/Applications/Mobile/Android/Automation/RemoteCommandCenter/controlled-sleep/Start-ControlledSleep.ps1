param(
    [string]$ConfigPath = '',
    [string]$Nonce = '',
    [switch]$ProofOnly
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($ConfigPath)) {
    $projectRoot = Split-Path -Parent $PSScriptRoot
    $ConfigPath = Join-Path $projectRoot 'scripts\rcc-config.json'
}

$config = Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json
$stateDir = [string]$config.StateDir
$logDir = [string]$config.LogDir
New-Item -ItemType Directory -Force -Path $stateDir, $logDir | Out-Null

$log = Join-Path $logDir 'controlled-sleep.log'
$signalPath = Join-Path $stateDir 'controlled-sleep-wake.signal'
$markerPath = Join-Path $stateDir 'controlled-sleep-running.json'

function Write-ControlledSleepLog {
    param([string]$Message)
    $line = '[{0}] {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'), $Message
    Add-Content -LiteralPath $log -Encoding UTF8 -Value $line
    Write-Output $line
}

Write-ControlledSleepLog "CONTROLLED_SLEEP_START nonce=$Nonce proofOnly=$([bool]$ProofOnly)"
Write-ControlledSleepLog "CONTROLLED_SLEEP_SIGNAL path=`"$signalPath`""

if ($ProofOnly) {
    Write-ControlledSleepLog 'CONTROLLED_SLEEP_PROOF_READY mode=fullscreen-black-overlay exit=space-or-double-click-or-android-signal trueWindowsSleep=False'
    exit 0
}

Remove-Item -LiteralPath $signalPath -Force -ErrorAction SilentlyContinue
@{
    pid = $PID
    startedAt = [DateTimeOffset]::UtcNow.ToString('o')
    nonce = $Nonce
    signalPath = $signalPath
    exitInputs = @('space', 'mouse double-click', 'android wake signal')
} | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $markerPath -Encoding UTF8

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

public static class RccControlledSleepNative {
    [DllImport("user32.dll", SetLastError=true)]
    public static extern IntPtr SendMessage(IntPtr hWnd, int Msg, IntPtr wParam, IntPtr lParam);
}
'@

$script:ExitReason = $null
$forms = New-Object 'System.Collections.Generic.List[System.Windows.Forms.Form]'

$script:CloseControlledSleep = {
    param([string]$Reason)
    if (-not $script:ExitReason) {
        $script:ExitReason = $Reason
        Write-ControlledSleepLog "CONTROLLED_SLEEP_EXIT_REQUEST reason=$Reason"
    }
    foreach ($form in @($forms)) {
        try {
            if ($form -and -not $form.IsDisposed) {
                $form.Close()
            }
        } catch {}
    }
}

try {
    [System.Windows.Forms.Application]::EnableVisualStyles()
    [System.Windows.Forms.Cursor]::Hide()

    foreach ($screen in [System.Windows.Forms.Screen]::AllScreens) {
        $form = New-Object System.Windows.Forms.Form
        $form.Text = 'RemoteCommandCenter Controlled Sleep'
        $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None
        $form.StartPosition = [System.Windows.Forms.FormStartPosition]::Manual
        $form.Bounds = $screen.Bounds
        $form.BackColor = [System.Drawing.Color]::Black
        $form.TopMost = $true
        $form.ShowInTaskbar = $false
        $form.KeyPreview = $true

        $label = New-Object System.Windows.Forms.Label
        $label.Dock = [System.Windows.Forms.DockStyle]::Fill
        $label.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
        $label.ForeColor = [System.Drawing.Color]::FromArgb(35, 35, 35)
        $label.BackColor = [System.Drawing.Color]::Black
        $label.Font = New-Object System.Drawing.Font('Segoe UI', 18, [System.Drawing.FontStyle]::Regular)
        $label.Text = 'Controlled Sleep'
        $form.Controls.Add($label)

        $form.Add_KeyDown({
            param($sender, $eventArgs)
            if ($eventArgs.KeyCode -eq [System.Windows.Forms.Keys]::Space) {
                & $script:CloseControlledSleep 'space-key'
            } else {
                $eventArgs.SuppressKeyPress = $true
                $eventArgs.Handled = $true
            }
        })
        $form.Add_MouseDoubleClick({
            & $script:CloseControlledSleep 'mouse-double-click'
        })
        $form.Add_FormClosing({
            param($sender, $eventArgs)
            if (-not $script:ExitReason) {
                $eventArgs.Cancel = $true
            }
        })
        $form.Add_Deactivate({
            param($sender, $eventArgs)
            if (-not $script:ExitReason) {
                try {
                    $sender.TopMost = $true
                    $sender.Activate()
                } catch {}
            }
        })

        $forms.Add($form)
    }

    $timer = New-Object System.Windows.Forms.Timer
    $timer.Interval = 150
    $timer.Add_Tick({
        if (Test-Path -LiteralPath $signalPath) {
            & $script:CloseControlledSleep 'android-wake-signal'
            return
        }
        foreach ($form in @($forms)) {
            try {
                if ($form -and -not $form.IsDisposed -and -not $script:ExitReason) {
                    $form.TopMost = $true
                    $form.BringToFront()
                }
            } catch {}
        }
    })

    foreach ($form in $forms) {
        $form.Show()
        $form.Activate()
    }
    $timer.Start()

    try {
        $hwndBroadcast = [IntPtr]0xffff
        [void][RccControlledSleepNative]::SendMessage($hwndBroadcast, 0x0112, [IntPtr]0xF170, [IntPtr]2)
        Write-ControlledSleepLog 'CONTROLLED_SLEEP_MONITOR_OFF_SENT'
    } catch {
        Write-ControlledSleepLog "CONTROLLED_SLEEP_MONITOR_OFF_FAILED error=`"$($_.Exception.Message)`""
    }

    Write-ControlledSleepLog "CONTROLLED_SLEEP_RUNNING screens=$($forms.Count)"
    while (-not $script:ExitReason) {
        [System.Windows.Forms.Application]::DoEvents()
        Start-Sleep -Milliseconds 40
    }

    foreach ($form in @($forms)) {
        try {
            if ($form -and -not $form.IsDisposed) {
                $form.Close()
            }
        } catch {}
    }
} finally {
    try {
        $hwndBroadcast = [IntPtr]0xffff
        [void][RccControlledSleepNative]::SendMessage($hwndBroadcast, 0x0112, [IntPtr]0xF170, [IntPtr](-1))
        Write-ControlledSleepLog 'CONTROLLED_SLEEP_MONITOR_ON_SENT'
    } catch {
        Write-ControlledSleepLog "CONTROLLED_SLEEP_MONITOR_ON_FAILED error=`"$($_.Exception.Message)`""
    }
    try { [System.Windows.Forms.Cursor]::Show() } catch {}
    Remove-Item -LiteralPath $markerPath -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $signalPath -Force -ErrorAction SilentlyContinue
    Write-ControlledSleepLog "CONTROLLED_SLEEP_DONE reason=$script:ExitReason"
}
