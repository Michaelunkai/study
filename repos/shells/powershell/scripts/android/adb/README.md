# aadb Android ADB Bridge

`aadb` is a PowerShell wrapper around official Google `adb` for fast Android file transfer, APK install, shell access, and wireless reconnect persistence.

## Fresh Windows 11 Setup

Run from this folder:

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\Install-Aadb.ps1
```

The installer:

- Downloads official Google Android platform-tools if `adb.exe` is missing.
- Installs the durable bridge script under `%APPDATA%\CodexAdb`.
- Creates `%USERPROFILE%\bin\aadb.ps1`.
- Adds `%USERPROFILE%\bin` and Android platform-tools to the user `PATH`.
- Adds `aadb` wrappers to Windows PowerShell 5 and PowerShell 7 profiles.
- Creates the `CodexAadbAutoConnect` scheduled task at Windows logon.
- Reuses an existing trusted/reachable device when possible.
- If saved wireless ADB fails, retries saved endpoints, retries mDNS discovery, restarts the ADB server, retries again, then prints Android pairing steps and waits for pairing `IP:PORT` and code.

## Android Steps When Pairing Is Required

The script prints these steps automatically, but the phone must still approve wireless debugging:

1. Put the phone and Windows PC on the same trusted Wi-Fi network.
2. Open Android Settings, then About phone, then tap Build number seven times.
3. Enter your lock screen PIN if Android asks to enable Developer options.
4. Open Settings, Developer options, then enable the main Developer options switch.
5. Enable Wireless debugging and approve the Android warning dialog.
6. Open Wireless debugging, then tap Pair device with pairing code.
7. Keep that pairing screen open; it shows `IP:PORT` and a six-digit code.
8. Type the IP with dots, for example `192.168.1.124:41539`, never `192:168`.
9. Leave Wireless debugging enabled for future `aadb` reconnects.
10. If Android rotates ports after reboot, `aadb` tries saved endpoints and mDNS discovery.

Android pairing codes are temporary. No Windows script can make the pairing code permanent. `aadb` persists the ADB trust key, saved endpoints, PATH, profile wrapper, and logon reconnect task, which is the maximum practical persistence without rooting or changing Android OS behavior.

## Commands

```powershell
aadb setup
aadb repair
aadb connect
aad connect
aadb apk
aadb push
aadb push "C:\path\file-or-folder"
aadb pull
aadb pull DCIM
aadb pull "C:\target\folder"
aadb pull "/sdcard/Download/file.zip" "C:\Users\me\Downloads"
aadb shell ls /sdcard/Download
aadb devices
aadb persist
aadb path
```

## Defaults

`aadb push <pcPath>` copies to:

```text
/sdcard/Download/<same-name>
```

`aadb push` with no arguments pushes the current PC folder to `/sdcard/Download`.

If `aadb push <pcPath>` points to a missing file, `aadb` tries to recover by:

- removing a trailing slash,
- checking the current directory for the same filename,
- searching under the nearest existing parent folder for that filename.
- reconstructing accidentally split unquoted Windows paths, including missing-space and with-space candidates.

This makes commands like this work when run from the real APK folder:

```powershell
aadb push "F:\study\repos\fullstack\todoist-enhanced\c\todoist-enhanced-private-android-output\app\build\outputs\app-debug.apk"
```

If `app-debug.apk` is actually in the current folder or under `outputs\apk\debug`, `aadb` resolves it and pushes it to `/sdcard/Download/app-debug.apk`.

This also handles accidental PowerShell splitting like:

```powershell
aadb push F:\study\repos\fullstack\todoist-enhanced\c\todoist-enhanced- private-android-output\app\build\outputs\app-debug.apk
```

The two tokens after `push` are reconstructed before path recovery runs.

`aadb pull` with no arguments opens an interactive browser starting at `/home`. On normal Android phones `/home` is usually not readable, so it falls back to `/sdcard`.

`aadb pull <pcFolder>` where `<pcFolder>` is a Windows path pulls `/sdcard/DCIM` into that PC folder. Example:

```powershell
aadb pull "F:\study\repos\fullstack\todoist-enhanced\c\todoist-enhanced-private-android-output\app\build\outputs\apk\debug"
```

That means:

```text
/sdcard/DCIM -> F:\study\repos\fullstack\todoist-enhanced\c\todoist-enhanced-private-android-output\app\build\outputs\apk\debug
```

Interactive pull controls:

```text
name       pull that visible file or full folder, for example DCIM
all        pull the current Android folder in full, then return to the menu
number     open folder / pull file
p number   pull that file or full folder
p          pull current folder, then return to the menu
open name  open that visible folder without pulling it
..         go up
q          quit
```

Examples:

```text
DCIM       pulls /sdcard/DCIM in full to the current PC folder
Download   pulls /sdcard/Download in full to the current PC folder
all        pulls whatever Android folder is currently open
```

Command-line shorthand:

```powershell
aadb pull DCIM
aadb pull Download
aadb pull Pictures
```

Any `aadb pull <name>` value that does not start with `/` is treated as `/sdcard/<name>`.

## Persistence

Installed paths:

```text
%APPDATA%\CodexAdb\Invoke-AndroidAdbBridge.ps1
%APPDATA%\CodexAdb\wireless-adb.json
%USERPROFILE%\bin\aadb.ps1
%LOCALAPPDATA%\Android\platform-tools\adb.exe
```

Windows scheduled task:

```text
CodexAadbAutoConnect
```

If the phone stays on the same Wi-Fi and Wireless debugging remains enabled, `aadb` should reconnect after reboot using the saved endpoint or mDNS discovery. If Android disables Wireless debugging or rotates ports in a way Windows cannot discover, run:

```powershell
aadb setup
```

Most commands do not stop with "run setup" anymore. If no device is reachable, `aadb connect`, `aadb push`, `aadb pull`, `aadb shell`, and pass-through commands automatically start pairing repair and ask for the new Android pairing `IP:PORT` plus six-digit pairing code.

Reconnect ladder before prompting:

1. Check already-authorized ADB devices.
2. Try saved wireless endpoints from `%APPDATA%\CodexAdb\wireless-adb.json`.
3. Try Android wireless ADB mDNS discovery.
4. Restart the ADB server.
5. Retry saved endpoints and mDNS with bounded timeouts so stale ports cannot hang forever.
6. Start pairing repair and ask for the new pairing `IP:PORT` plus six-digit code.

If the command is running from a non-interactive host that cannot accept `Read-Host` input, it exits with a clear message telling you to run `aadb repair` in an interactive PowerShell window.

Use this to force the same pairing repair immediately:

```powershell
aadb repair
```

`aad` is also installed as a short alias for `aadb`, so this works too:

```powershell
aad connect
```

## Project Files

```text
Invoke-AndroidAdbBridge.ps1
Install-Aadb.ps1
README.md
```
