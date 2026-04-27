# aadb Android ADB Bridge

`aadb` is a durable PowerShell bridge around official Google Android Debug Bridge (`adb`). It is designed for fast everyday Android work: copying files and folders, pulling photos, installing APKs, opening shell commands, and recovering from wireless-debugging port changes without needing to remember raw `adb` syntax.

The project is optimized for Windows 11, but the usage model is portable: if an OS can run PowerShell and `adb`, it can use the main bridge script. Windows gets the full automatic installer, profile integration, shims, and logon reconnect task.

## What This Project Solves

Plain `adb` is powerful, but annoying for daily work:

- Wireless debugging ports change.
- Android pairing codes expire.
- `adb connect` failures are cryptic.
- Pulling a whole folder requires exact Android paths.
- Pushing files from PowerShell breaks easily when paths are mistyped or split.
- Reinstalling the setup on a fresh Windows machine is repetitive.

`aadb` wraps those rough edges with a human workflow:

- `aadb push file-or-folder`
- `aadb pull DCIM`
- `aadb repair`
- `aadb shell ls /sdcard/Download`
- `aad connect`

It remembers trusted endpoints, tries multiple reconnect strategies, and only asks for a new Android pairing `IP:PORT` and code when there is no working automatic path left.

## Project Files

```text
Invoke-AndroidAdbBridge.ps1   Main bridge implementation
Install-Aadb.ps1              Windows installer/bootstrapper
README.md                     Full project guide
```

Repository path:

```text
repos/shells/powershell/scripts/android/adb
```

Installed Windows runtime path:

```text
%APPDATA%\CodexAdb\Invoke-AndroidAdbBridge.ps1
```

## Architecture

```text
User command
  |
  | aadb / aad
  v
%USERPROFILE%\bin\aadb.ps1
%USERPROFILE%\bin\aad.ps1
  |
  v
%APPDATA%\CodexAdb\Invoke-AndroidAdbBridge.ps1
  |
  | uses official Google platform-tools
  v
%LOCALAPPDATA%\Android\platform-tools\adb.exe
  |
  v
Android phone over USB or Wireless debugging
```

Persistence state:

```text
%APPDATA%\CodexAdb\wireless-adb.json
%USERPROFILE%\.android\adbkey
Windows scheduled task: CodexAadbAutoConnect
```

## Quick Start: Windows 11

Open Windows PowerShell 5 or PowerShell 7 in this project folder:

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\Install-Aadb.ps1
```

The installer does all of this:

- Downloads official Google Android platform-tools if `adb.exe` is missing.
- Installs the durable bridge script under `%APPDATA%\CodexAdb`.
- Creates `%USERPROFILE%\bin\aadb.ps1`.
- Creates `%USERPROFILE%\bin\aad.ps1`.
- Adds `%USERPROFILE%\bin` and platform-tools to the user `PATH`.
- Adds `aadb` and `aad` functions to Windows PowerShell 5 and PowerShell 7 profiles.
- Creates the `CodexAadbAutoConnect` logon task.
- Reuses an already authorized Android device when possible.
- Starts pairing repair only when there is no reachable trusted device.

After installation, open a new PowerShell window and run:

```powershell
aadb help
```

## Android Setup Steps

The script prints these steps automatically when pairing is required.

1. Put the phone and computer on the same trusted Wi-Fi network.
2. Open Android Settings.
3. Open About phone.
4. Tap Build number seven times to enable Developer options.
5. Enter your lock screen PIN if Android asks.
6. Open Developer options.
7. Enable Wireless debugging.
8. Open Wireless debugging.
9. Tap Pair device with pairing code.
10. Keep that screen open.
11. Copy the pairing `IP:PORT`, for example `192.168.1.124:41539`.
12. Copy the six-digit pairing code.
13. Enter both values when `aadb` asks.

Important: Android pairing codes are temporary. No script can make the pairing code permanent. `aadb` persists the trusted ADB key, saved endpoints, shims, PATH, profiles, and logon reconnect task. If Android rotates the port or disables Wireless debugging, `aadb` automatically falls back to pairing repair.

## Command Reference

```powershell
aadb help
aadb path
aadb devices
aadb connect
aadb repair
aadb setup
aadb persist
```

`aad` is a short alias for `aadb`:

```powershell
aad connect
aad repair
```

## Push: PC To Android

Push one file:

```powershell
aadb push "C:\path\to\file.zip"
```

Push one folder:

```powershell
aadb push "C:\path\to\folder"
```

Push the current folder:

```powershell
aadb push
```

Default Android destination:

```text
/sdcard/Download/<same-name>
```

Push to an explicit Android destination:

```powershell
aadb push "C:\path\file.zip" "/sdcard/Documents/file.zip"
```

Install or copy the default Todoist APK:

```powershell
aadb apk
```

Install any APK:

```powershell
aadb install "C:\path\app-debug.apk"
```

### Push Path Recovery

If a local push path is wrong, `aadb` tries to recover before failing:

- Removes a trailing slash from a file path.
- Checks the current folder for the same filename.
- Searches under the nearest existing parent folder for that filename.
- Reconstructs accidentally split unquoted Windows paths.

This works:

```powershell
aadb push "F:\study\repos\fullstack\todoist-enhanced\c\todoist-enhanced-private-android-output\app\build\outputs\app-debug.apk"
```

Even if the real APK is here:

```text
F:\study\repos\fullstack\todoist-enhanced\c\todoist-enhanced-private-android-output\app\build\outputs\apk\debug\app-debug.apk
```

This accidental PowerShell split is also handled:

```powershell
aadb push F:\study\repos\fullstack\todoist-enhanced\c\todoist-enhanced- private-android-output\app\build\outputs\app-debug.apk
```

## Pull: Android To PC

Open the interactive Android browser:

```powershell
aadb pull
```

Pull the full camera folder into the current PC folder:

```powershell
aadb pull DCIM
```

Pull another shared-storage folder:

```powershell
aadb pull Download
aadb pull Pictures
aadb pull Documents
```

Any pull source that does not start with `/` is treated as:

```text
/sdcard/<name>
```

Pull an exact Android path:

```powershell
aadb pull "/sdcard/Download/file.zip"
```

Pull an exact Android path to an exact PC destination:

```powershell
aadb pull "/sdcard/Download/file.zip" "C:\Users\me\Downloads"
```

Pull `/sdcard/DCIM` into a specific Windows folder by passing only a Windows folder:

```powershell
aadb pull "F:\target\folder"
```

That means:

```text
/sdcard/DCIM -> F:\target\folder
```

### Interactive Pull Controls

```text
name       Pull that visible file or full folder, for example DCIM
all        Pull the current Android folder in full, then return to the menu
number     Open folder or pull file
p number   Pull that numbered file or full folder
p          Pull current folder, then return to the menu
open name  Open that visible folder without pulling it
..         Go up
q          Quit
```

Examples inside the menu:

```text
DCIM       Pulls /sdcard/DCIM in full
Download   Pulls /sdcard/Download in full
open DCIM  Opens /sdcard/DCIM without pulling
all        Pulls whatever Android folder is currently open
```

## Shell And Pass-Through Commands

Run Android shell commands:

```powershell
aadb shell ls /sdcard/Download
aadb shell pm list packages
aadb shell getprop ro.product.model
```

Pass raw ADB arguments after auto-connect:

```powershell
aadb logcat -d
aadb shell dumpsys battery
```

## Reconnect And Repair Model

Before asking for pairing details, `aadb` follows this ladder:

1. Check already-authorized ADB devices.
2. Try saved wireless endpoints from `%APPDATA%\CodexAdb\wireless-adb.json`.
3. Try Android wireless ADB mDNS discovery.
4. Restart the ADB server.
5. Retry saved endpoints and mDNS with bounded timeouts.
6. Start pairing repair and ask for a new Android pairing `IP:PORT` plus six-digit code.

Force pairing repair:

```powershell
aadb repair
```

Equivalent:

```powershell
aadb pair
aadb setup
```

If `aadb` is running from a non-interactive host that cannot accept `Read-Host`, it exits with a clear message:

```text
Pairing repair requires the Android pairing IP:PORT. Run aadb repair in an interactive PowerShell window.
```

## Persistence Guarantees

`aadb` persists what Windows and Android allow:

- Windows command shims.
- PowerShell profile functions.
- Official platform-tools install path.
- Saved wireless endpoints.
- ADB trusted key material.
- A Windows logon reconnect task.

`aadb` cannot permanently freeze Android's wireless debugging port. Android may rotate the port after:

- phone reboot,
- Wi-Fi reconnect,
- Wireless debugging toggle,
- Developer options reset,
- router DHCP changes,
- OEM battery/security cleanup.

When that happens, run:

```powershell
aadb repair
```

## Install On Any OS

### Windows 11 Or Windows 10

Recommended full install:

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\Install-Aadb.ps1
```

Repair or refresh install:

```powershell
aadb persist
```

Use:

```powershell
aadb connect
aadb push "C:\path\file.zip"
aadb pull DCIM
```

### macOS

Install prerequisites:

```bash
brew install --cask powershell
brew install android-platform-tools
```

Run the bridge directly from the repo:

```bash
pwsh -NoProfile -ExecutionPolicy Bypass -File ./Invoke-AndroidAdbBridge.ps1 connect
pwsh -NoProfile -ExecutionPolicy Bypass -File ./Invoke-AndroidAdbBridge.ps1 push ~/Downloads/file.zip
pwsh -NoProfile -ExecutionPolicy Bypass -File ./Invoke-AndroidAdbBridge.ps1 pull DCIM
```

Optional shell alias:

```bash
echo "alias aadb='pwsh -NoProfile -ExecutionPolicy Bypass -File /absolute/path/to/Invoke-AndroidAdbBridge.ps1'" >> ~/.zshrc
source ~/.zshrc
```

Then:

```bash
aadb connect
aadb pull DCIM
```

Note: The Windows scheduled task and Windows PowerShell profile installation are Windows-only. The core bridge logic still works when `pwsh` and `adb` are available.

### Linux

Install prerequisites. Debian/Ubuntu example:

```bash
sudo apt update
sudo apt install -y adb powershell
```

If your distribution does not package PowerShell, install it from Microsoft's package repository, then run:

```bash
pwsh -NoProfile -ExecutionPolicy Bypass -File ./Invoke-AndroidAdbBridge.ps1 connect
pwsh -NoProfile -ExecutionPolicy Bypass -File ./Invoke-AndroidAdbBridge.ps1 push ~/Downloads/file.zip
pwsh -NoProfile -ExecutionPolicy Bypass -File ./Invoke-AndroidAdbBridge.ps1 pull DCIM
```

Optional shell alias:

```bash
echo "alias aadb='pwsh -NoProfile -ExecutionPolicy Bypass -File /absolute/path/to/Invoke-AndroidAdbBridge.ps1'" >> ~/.bashrc
source ~/.bashrc
```

For USB ADB on Linux, you may also need Android udev rules and a reconnect:

```bash
adb devices
```

Approve the RSA prompt on the phone if it appears.

### WSL

For WSL, the most reliable approach is usually to run `aadb` from Windows PowerShell because USB and mDNS visibility can differ inside WSL.

If you still want WSL usage:

```bash
pwsh -NoProfile -ExecutionPolicy Bypass -File /mnt/f/study/repos/shells/powershell/scripts/android/adb/Invoke-AndroidAdbBridge.ps1 connect
```

Use Windows paths from Windows PowerShell for best behavior:

```powershell
aadb push "F:\path\file.zip"
aadb pull DCIM
```

### ChromeOS, BSD, Or Other Systems

Requirements:

- PowerShell 7+ as `pwsh`.
- Android platform-tools / `adb`.
- Network route to the Android phone for wireless debugging, or USB ADB support.

Generic pattern:

```bash
pwsh -NoProfile -ExecutionPolicy Bypass -File ./Invoke-AndroidAdbBridge.ps1 repair
pwsh -NoProfile -ExecutionPolicy Bypass -File ./Invoke-AndroidAdbBridge.ps1 push ./file.zip
pwsh -NoProfile -ExecutionPolicy Bypass -File ./Invoke-AndroidAdbBridge.ps1 pull DCIM
```

## Troubleshooting

### `cannot connect ... actively refused`

The saved wireless debugging port is stale. Run:

```powershell
aadb repair
```

Then open Android Wireless debugging and choose Pair device with pairing code.

### `No authorized Android device`

Run:

```powershell
aadb repair
```

If using USB, approve the RSA fingerprint prompt on the phone.

### `adb` Is Not Recognized

On Windows, run:

```powershell
aadb persist
```

or reinstall:

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\Install-Aadb.ps1
```

### Pairing Prompt Does Not Appear

On Android:

1. Turn Wireless debugging off.
2. Turn Wireless debugging on.
3. Tap Pair device with pairing code.
4. Run `aadb repair`.

### Pulling `/home` Falls Back To `/sdcard`

That is normal on Android phones. `/home` is usually not readable or does not exist. `aadb pull` starts there because it is a familiar desktop concept, then falls back to shared storage:

```text
/sdcard
```

### PowerShell Splits A Path

Quote paths when possible:

```powershell
aadb push "F:\path with spaces\file.apk"
```

If a path is accidentally split, `aadb` tries to reconstruct it anyway.

## Fresh Machine Checklist

1. Clone or copy this project folder.
2. Open PowerShell in `repos/shells/powershell/scripts/android/adb`.
3. Run `powershell.exe -ExecutionPolicy Bypass -File .\Install-Aadb.ps1`.
4. Open a new PowerShell window.
5. Run `aadb connect`.
6. If prompted, follow Android pairing steps.
7. Test with `aadb devices`.
8. Push a file with `aadb push "C:\path\file"`.
9. Pull camera photos with `aadb pull DCIM`.

## Design Principles

- Prefer official Google `adb`.
- Avoid destructive resets.
- Recover automatically before asking for manual pairing.
- Keep Windows setup durable across new shells and reboots.
- Make common file movement one command.
- Keep raw `adb` access available for advanced use.

## Current Known Limits

- Android pairing codes are temporary by OS design.
- Wireless debugging may disable itself on some OEM phones.
- mDNS discovery can be blocked by VPNs, guest Wi-Fi, routers, or firewalls.
- Windows persistence is richer than macOS/Linux persistence because the installer uses Windows profiles and Task Scheduler.
- Cross-platform use requires PowerShell and `adb` to already be installed or installed separately.
