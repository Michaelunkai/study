# Remote Command Center — continuation handoff

Read this before changing automation. It records exact locations, ownership, evidence, and remaining proof gates.

## Canonical locations

- Windows project: `F:\study\Windows\Applications\Mobile\Android\Automation\RemoteCommandCenter`
- Git root: `F:\study`
- Remote: `https://github.com/Michaelunkai/study`
- Repository: public `Michaelunkai/study`, default branch `main`
- Project path in repo: `Windows/Applications/Mobile/Android/Automation/RemoteCommandCenter`
- Android package/activity: `com.mich.remotecommandcenter/.MainActivity`
- Android version: `versionCode=3`, `versionName=2.1.0`
- APK: `F:\study\Windows\Applications\Mobile\Android\Automation\RemoteCommandCenter\artifacts\build-output\RemoteCommandCenter-debug.apk`
- Tray executable: `F:\study\Windows\Applications\Mobile\Android\Automation\RemoteCommandCenter\dist\RemoteCommandCenterTray.exe`

The parent repository contains unrelated projects and active user changes. Stage only this project path. Never use `git add -A` from `F:\study` unless the user explicitly changes that scope.

## Project map and stable IDs

The Android app is `app/src/main/java/com/mich/remotecommandcenter/MainActivity.java`. The Windows side is under `scripts/`; main entry points are `Install-RemoteCommandCenter.cmd`, `setup/Install-RemoteCommandCenter.ps1`, `scripts/Install-RemoteCommandCenterAgent.ps1`, and `build-android.ps1`.

Keep action IDs stable: `youtube_tizen`, `moonlight_toggle`, `wake_pc`, `tv_force_reboot`, and `restart_codex`. They are referenced by Android, signed receiver requests, logs, and PowerShell dispatch.

## YouTube/TizenTube root cause and fix

The Android YouTube handler is receiver-only: one `youtube_tizen` request, no Android Samsung remote socket. This prevents the Samsung authorization popup.

`Invoke-TizenTubeViaPairedController` in `scripts/Invoke-RemoteCommandCenterAction.ps1` waits for Samsung REST/remote readiness, launches or observes TizenBrew, sends the bounded card navigation sequence, polls DIAL, and uses one bounded recovery/start fallback. Android and the receiver tracked-action wrapper enforce single-flight.

The confirmed failure was a false positive: DIAL returned `running` while the TV visibly still showed the TizenBrew card screen. The old code returned before sending navigation. The current condition short-circuits only when DIAL is running and TizenBrew is not visible; visible TizenBrew always receives navigation. The pre-navigation DIAL state rejects stale `running` responses as a new launch.

Static contracts, parsing, APK signing, and APK reinstall passed. The final user-facing tap from the visible TizenBrew card screen was deliberately not executed in the last repair session. Do not claim live YouTube success until a new action log shows readiness, one card sequence, and authoritative DIAL `running` completion.

## Moonlight and focus isolation

- `moonlight_toggle` preserves the original connect/disconnect scripts.
- `Start-RemoteCommandCenterMoonlightGuard.ps1` is the hidden child worker of the canonical tray.
- `Start-RemoteCommandCenterMoonlightFocusGuardian.ps1` starts after encoder-session detection, resolves Sunshine's configured output instead of permanently assuming `DISPLAY10`, preserves intentional Alt-Tab/Win-key/mouse movement, and exits when the encoder session ends.
- Canonical startup is `RemoteCommandCenterTray.exe` with `RemoteCommandCenterTrayLogon`; do not resurrect duplicate guardians.

The user reported Moonlight working. Treat focus isolation as source/contract verified until a fullscreen-game plus other-monitor terminal soak is recorded.

## Wake, TV reboot, and Codex restart

`Ensure-RemoteCommandCenterWakeSettings.ps1` owns durable NIC/power configuration. It must not restart the adapter repeatedly and must preserve full hibernation, disabled automatic hibernation, shutdown WOL, and Realtek wake settings. A packet proof is not the same as proving two-hour sleep or mobile-data wake.

`tv_force_reboot` must use the real TV SDB reboot path, never power-off followed by power-on. `restart_codex` must use `Restart-CodexDesktopApp.ps1`, not the CLI `codex` command.

## Configuration and secrets

Use `scripts/rcc-config.example.json` and `app/src/main/res/raw/rescue_config.example.json` as templates. Setup generates `scripts/rcc-config.json` and `rescue_config.json`; they contain shared keys, relay topics, and machine-specific addresses and are ignored. `runtime/` and generated APK signing material are also ignored. Never commit live configuration, runtime logs, private keys, or device secrets.

## Verification already performed

During the 2026-07-11 repair session:

- `tests/RemoteCommandCenter.Contract.Tests.ps1` returned `REMOTE_COMMAND_CENTER_CONTRACT_TESTS_PASS`.
- Receiver PowerShell parse/diff check returned `PS_PARSE_AND_DIFF_OK`.
- APK build completed and `apksigner verify` passed v2/v3 signing.
- `adb install -r` returned `Success` for package `com.mich.remotecommandcenter`, version `3 / 2.1.0`.
- After reinstall, the app was not launched and no YouTube/TV action was sent.

The receiver integration and Android UI proof scripts are present, but neither substitutes for a user-facing YouTube tap.

## Safe continuation commands

```powershell
Set-Location 'F:\study\Windows\Applications\Mobile\Android\Automation\RemoteCommandCenter'
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\RemoteCommandCenter.Contract.Tests.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\build-android.ps1
```

For live YouTube proof, start from the TV's visible TizenBrew card screen, press YouTube once, then inspect the matching `runtime\logs\action-*.log`. One press must produce one transaction. Record the log and TV result here after proof.

## Do-not-break rules

- Do not replace `youtube_tizen` with a direct Android Samsung socket.
- Do not treat “TizenBrew opened” as YouTube success.
- Do not reintroduce duplicated Moonlight recovery or focus guardians.
- Do not turn TV reboot into a shutdown/power-on cycle.
- Do not report static contract success as live app success.
- Do not stage unrelated `F:\study` changes.
- Update this handoff whenever live proof changes a status.

## Current status matrix

| Area | Source/contract | Live proof | Current truth |
|---|---|---|---|
| YouTube/TizenTube | Passed; visible-card stale-DIAL repair present | Latest final tap pending | Not live-verified |
| Moonlight toggle | Original scripts and guard paths preserved | User reported working | Reported working; focus soak pending |
| Wake | Single-flight/settings contracts present | Full power-state matrix pending | Not fully live-proven |
| TV reboot | Contract asserts real SDB reboot path | Button proof pending | Not fully live-proven |
| Codex restart | Dedicated helper and contract present | Button proof pending | Not fully live-proven |
| Android UI/icon | APK built, signed, installed | App not launched in last repair | Build/install verified |
