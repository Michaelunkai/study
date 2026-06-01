# qBittorrent FitGirl Force Auto Install

This project permanently wires qBittorrent completed downloads to FitGirl installer startup on this Windows PC.

When a FitGirl repack finishes in `F:\Downloads`, the watcher immediately launches every completed repack's `setup.exe` and passes an explicit install target:

```text
/DIR="F:\Downloads\<game name>"
```

The project uses two independent triggers so a missed qBittorrent hook does not leave a completed game idle:

1. qBittorrent's external completion command calls the script once for the finished torrent.
2. A Windows Scheduled Task runs a 5-second daemon sweep over `F:\Downloads`.

It also starts an AutoHotkey v2 dialog watchdog that advances normal FitGirl/Inno prompts such as language, OK, Next, Install, Finish, and tries to keep the destination path set to `F:\Downloads\<game name>`.

## Prerequisites

- Windows PowerShell 5.1.
- qBittorrent installed and using `F:\Downloads` as its save path.
- AutoHotkey v2 installed at `C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe` for full prompt automation.
- FitGirl repack folders should contain a real `setup.exe` and `fg-*.bin` or `.bin` payload files.

## Install and run

From Windows PowerShell 5:

```powershell
Set-Location -LiteralPath 'F:\study\Windows\Applications\Gaming\DownloadManagers\qBittorrent\FitGirl\Automation\AutoInstall\qbittorrent-fitgirl-force-auto-install-20260601'
.\install.ps1
```

`install.ps1` does all of this:

- Backs up `%APPDATA%\qBittorrent\qBittorrent.ini`.
- Sets `Downloads\RunExternalProgram=true`.
- Sets `Downloads\RunExternalProgramCommand` to call `scripts\Force-QbitFitGirlAutoInstall.ps1 -Once`.
- Creates and starts the Scheduled Task `qBittorrent FitGirl Force AutoInstall Watcher`.
- Creates and starts the Scheduled Task `qBittorrent FitGirl Installer Dialog Watchdog` when AutoHotkey v2 is installed.
- Runs one immediate sweep so already-finished downloads are handled now.

To install the permanent tasks without launching installers during the install step:

```powershell
.\install.ps1 -NoRunOnce
```

## Manual usage

Run a single sweep:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Force-QbitFitGirlAutoInstall.ps1 -Once
```

Run the foreground daemon for testing:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Force-QbitFitGirlAutoInstall.ps1 -Daemon -PollSeconds 5
```

Run the AutoHotkey syntax self-test:

```powershell
& 'C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe' '.\scripts\FitGirlAutoClicker.ahk' --selftest
```

## Inputs and outputs

Input folder:

- `F:\Downloads\* [FitGirl Repack]` or any folder under `F:\Downloads` that contains a real `setup.exe` plus large `.bin` payload files.

Install target:

- `F:\Downloads\<game name>` where `<game name>` is derived by removing FitGirl/Repack suffixes from the download folder name.

Logs and markers:

- `F:\Downloads\.fitgirl_tmp\qbit-force-auto-install\force-auto-install.log`
- `F:\Downloads\.fitgirl_tmp\qbit-force-auto-install\fitgirl-ahk-watchdog.log`
- Each handled repack gets `.qbit-force-install-target.txt` beside its `setup.exe`.

## Important files

- `install.ps1` — one-command permanent installer.
- `scripts\Force-QbitFitGirlAutoInstall.ps1` — qBittorrent hook, scheduled daemon, scanner, and exact setup launcher.
- `scripts\FitGirlAutoClicker.ahk` — interactive AutoHotkey v2 dialog helper.
- `README.md` — this guide.

## Troubleshooting

- If installers launch but wait on a prompt, verify AutoHotkey v2 is installed and the task `qBittorrent FitGirl Installer Dialog Watchdog` is running.
- If a finished download does not launch, run the single sweep command and inspect `force-auto-install.log`.
- Folders with `.parts`, `.!qB`, `.aria2`, or `.part` files are treated as incomplete and skipped.
- Metadata-only or partial torrents are skipped because they do not contain real game payload files.
- qBittorrent may need to be restarted before its external-program setting is visible in the GUI, but the scheduled daemon does not require restarting qBittorrent and starts working immediately.
- This tool intentionally launches every completed repack immediately in parallel, as requested. If too many installers open at once for a specific machine, disable the scheduled task and run `-Once` manually.

## Verification commands

```powershell
powershell.exe -NoProfile -Command "Get-ScheduledTask -TaskName 'qBittorrent FitGirl Force AutoInstall Watcher','qBittorrent FitGirl Installer Dialog Watchdog' | Select TaskName,State"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Force-QbitFitGirlAutoInstall.ps1 -Once
Get-Content -Tail 40 -LiteralPath 'F:\Downloads\.fitgirl_tmp\qbit-force-auto-install\force-auto-install.log'
```
