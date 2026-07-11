# Remote Command Center

Android remote-control app plus Windows tray/receiver agent for controlling a PC from an Android phone.

Project handoff and exact current-state evidence are in [`docs/CONTINUATION.md`](docs/CONTINUATION.md). This project lives inside the larger `F:\study` checkout; do not stage or reset the parent checkout as a whole.

Package: `com.mich.remotecommandcenter`

## What It Does

System buttons:

- Force reboot now
- Sleep
- Hibernate
- Wake by Wake-on-LAN
- Shut down PC
- Restart Explorer
- Reboot to BIOS
- Night mode on/off
- Wireless debugging toggle

Application buttons:

- Restart Codex
- Open or hide Wand / WeMod
- Open or hide OpenSpeedy
- Open qBittorrent and the FitGirl auto-install executable when configured on the PC

The Android Wake button sends Wake-on-LAN magic packets directly. The Windows side also keeps the NIC and power settings re-applied so future power-setting changes do not silently break wake support.

## One Command Setup

Run this from an elevated Command Prompt or PowerShell on the target Windows PC:

```cmd
Install-RemoteCommandCenter.cmd
```

Useful options:

```cmd
Install-RemoteCommandCenter.cmd -PcIp 192.168.1.129 -PcMac 30:56:0F:40:D2:4C
Install-RemoteCommandCenter.cmd -InstallAndroid
Install-RemoteCommandCenter.cmd -SdkRoot C:\Android\sdk -JdkRoot C:\Java\jdk
```

The setup script:

- Generates a fresh shared key and relay topics for that machine.
- Writes `scripts\rcc-config.json`.
- Writes `app\src\main\res\raw\rescue_config.json`.
- Builds `dist\RemoteCommandCenterTray.exe`.
- Installs the Windows tray, local HTTP receiver, action agent, stay-awake tasks, and PowerGuard startup tasks.
- Rebuilds the Android APK when Android SDK and JDK paths are available.
- Optionally installs and launches the APK when `-InstallAndroid` is passed and ADB sees a device.

## Dependencies

Windows:

- Windows PowerShell 5.1
- .NET Framework 4.x compiler (`csc.exe`) for the tray launcher
- Administrator rights for scheduled tasks, firewall rule, WOL, and power policy setup

Android build:

- Android SDK with build-tools, platform, `aapt2`, `d8`, `zipalign`, and `apksigner`
- JDK with `javac`, `jar`, and `keytool`

Android install:

- ADB at `%LOCALAPPDATA%\Android\platform-tools\adb.exe`
- USB debugging or wireless debugging enabled on the Android device

## Generated Local Files

These are intentionally ignored by git because they contain machine-specific secrets or runtime state:

- `scripts\rcc-config.json`
- `app\src\main\res\raw\rescue_config.json`
- `runtime\`
- `artifacts\build-output\debug.keystore`
- `artifacts\build-output\work\`

Use the `.example.json` files only as templates. Do not publish a real generated config from a live PC.

## Build APK Manually

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\build-android.ps1
```

Output:

```text
artifacts\build-output\RemoteCommandCenter-debug.apk
```

## Install APK Manually

```powershell
$adb = "$env:LOCALAPPDATA\Android\platform-tools\adb.exe"
$apk = ".\artifacts\build-output\RemoteCommandCenter-debug.apk"
$serial = (& $adb devices | Select-String "`tdevice$" | Select-Object -First 1).ToString().Split("`t")[0]
& $adb -s $serial install --no-incremental -r -d $apk
& $adb -s $serial shell pm grant com.mich.remotecommandcenter android.permission.WRITE_SECURE_SETTINGS
& $adb -s $serial shell monkey -p com.mich.remotecommandcenter -c android.intent.category.LAUNCHER 1
```

## Verify Wake Packets Without Sleeping The PC

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Test-RemoteCommandCenterWakePackets.ps1 -Seconds 45
```

Then press Wake in the Android app or launch it with the `wake_now` intent. The proof JSON is written to:

```text
runtime\logs\wake-packet-proof.json
```

## Important Limit

Wake from full shutdown, sleep, or hibernate ultimately depends on motherboard firmware, NIC support, router forwarding, and the physical network path. This project configures Windows and sends the correct packets, but it cannot force unsupported hardware or blocked routers to wake a machine.

## Current state

- Moonlighter/Moonlight: the user reported the button working; the source preserves the original connect/disconnect scripts and adds the session-bound focus guardian.
- YouTube/TizenTube: the receiver-side visible-TizenBrew false-positive repair is implemented and contract-tested. The latest Android reinstall succeeded, but the final live tap from the TizenBrew card screen is deliberately recorded as not yet verified.
- Wake, TV reboot, Codex restart, and the remaining controls: source contracts and static checks exist; use the continuation document's evidence matrix before treating any live behavior as proven.
- No generated machine configuration, shared key, relay topic, runtime log, or private Android signing material belongs in GitHub.
