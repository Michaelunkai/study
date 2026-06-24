# Fast Windows Update

Real Windows Update automation for Windows PowerShell 5 using the Windows Update Agent COM APIs directly, with live console heartbeat and per-update download or install progress when WUA exposes it.

## What It Does

- Searches Microsoft Update, not only the default Windows Update feed.
- Installs normal visible updates first.
- Searches optional or preview-visible updates in a separate pass.
- Verifies again with an all-visible pass at the end.
- Can auto-reboot and auto-resume itself through a scheduled task.
- Writes live logs under `logs\`.

## Exact Launcher

`F:\study\Windows\Maintenance\WindowsUpdate\update-windows.ps1`

## Mega One-Liner

Run this from any PowerShell prompt:

```powershell
C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -NoProfile -ExecutionPolicy Bypass -File "F:\study\Windows\Maintenance\WindowsUpdate\update-windows.ps1" -AllowReboot -MaxRounds 12 -HeartbeatSeconds 1 -NoOutputTimeoutSeconds 1800
```

## Useful Variants

Preview-only scan of everything visible:

```powershell
C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -NoProfile -ExecutionPolicy Bypass -File "F:\study\Windows\Maintenance\WindowsUpdate\update-windows.ps1" -PreviewOnly -MaxRounds 1 -HeartbeatSeconds 1 -NoOutputTimeoutSeconds 1800
```

Skip the optional or preview pass:

```powershell
C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -NoProfile -ExecutionPolicy Bypass -File "F:\study\Windows\Maintenance\WindowsUpdate\update-windows.ps1" -AllowReboot -SkipOptional -MaxRounds 12 -HeartbeatSeconds 1 -NoOutputTimeoutSeconds 1800
```

Self-test without touching Windows Update:

```powershell
C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -NoProfile -ExecutionPolicy Bypass -File "F:\study\Windows\Maintenance\WindowsUpdate\update-windows.ps1" -SelfTest
```

## Limits

- Search itself does not expose granular percent from WUA. During long searches the wrapper prints a live heartbeat so the run is visibly alive.
- Windows only offers updates that are applicable to the current device, channel, policy, and Microsoft-side targeting state. No tool can install updates Microsoft is not actually offering to this machine.
- Optional or preview updates are searched with `BrowseOnly=1`, which is the Windows Update classification used for optional updates exposed through WUA.
