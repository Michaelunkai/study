# qBittorrent FitGirl Force Auto Install

This project permanently wires qBittorrent completed downloads to FitGirl installer startup on this Windows PC.

When a FitGirl repack finishes in `F:\Downloads`, the qBittorrent completion hook and resident watcher immediately launch every completed repack's `setup.exe` and pass an explicit install target:

```text
/DIR="F:\Downloads\<game name>"
```

The project uses two independent triggers so a missed qBittorrent hook does not leave a completed game idle:

1. qBittorrent's external completion command calls the script once for the finished torrent.
2. A Windows Scheduled Task runs a 250 ms daemon sweep over `F:\Downloads` as a fallback; the qBittorrent completion hook is still the immediate zero-wait path.

It also starts an AutoHotkey v2 dialog watchdog that checks windows every 50 ms, advances normal FitGirl/Inno prompts such as language, OK, Next, Install, folder-exists confirmation, optional redist/download/certificate popups, and keeps the destination path set to `F:\Downloads\<game name>`. Finished installer pages have launch checkboxes cleared and Finish clicked automatically.

Runtime wrappers are generated under this project, not under `%APPDATA%`:

```text
F:\study\Windows\Applications\Gaming\DownloadManagers\qBittorrent\FitGirl\Automation\AutoInstall\qbittorrent-fitgirl-force-auto-install-20260601\runtime\qbit-fitgirl-auto-install
```

qBittorrent, HKCU startup Run entries, and scheduled task actions point to those F-study wrappers. The only remaining C-profile reads are app-owned qBittorrent/FitLauncher state files that those installed applications maintain themselves.

Safety stop contract: `FitGirlAutoClicker.ahk` is a required runtime dependency for launching or relaunching installers. If that exact AHK process is closed, the PowerShell daemon exits and one-shot sweeps pause before target cleanup or setup launch, so unattended installer windows are not started without the clicker.

Current hardening also treats Inno/ISExec temp-helper failures such as `C:\Temp\is-*\FlushFileCache.exe in the module ISExec` as retryable scratch/temp extraction failures rather than permanent archive corruption. New setup launches get an isolated per-source `TEMP`/`TMP` directory under `F:\Downloads\.fitgirl_tmp\qbit-force-auto-install\inno-temp`, stale markers for that exact retryable class are cleared, and the next sweep relaunches every qBittorrent-completed source immediately. The hook path now accepts the exact qBittorrent completion event as authoritative for that source even if `.fastresume` has not flushed `completed_time` yet; non-hook background sweeps still require strict 100% qBittorrent proof.


Current hardening also treats ISDone/Unarc messages that include `Unable to write data to disk`, `write error`, `disk full`, or `not enough disk` as retryable target/temp/lock failures instead of permanent source corruption. The watchdog clears only that stale marker, deletes the separate incomplete install target, and lets the next run retry the qBittorrent-completed source from a clean target. True CRC/checksum/read/corrupt-source errors remain hard blockers.

Current ready-detection hardening no longer permanently skips a finished repack just because qBittorrent has not written or matched `.fastresume` `completed_time` yet. If qBittorrent explicitly says incomplete, the source is skipped. If qBittorrent proof is unavailable/null, the 250 ms watcher uses a conservative two-scan filesystem-complete fallback (`setup.exe`, payload `.bin`, no partial files, unchanged signature) and then launches the ready installer. Setup launches now pass `/COMPONENTS=""` together with `/TASKS=""` so optional DirectX/VC++ web-download components are disabled before they can loop on certificate/TLS failures; the AHK watchdog also handles stuck `Download failed` / `The supplied certificate is invalid` pages with a safe Enter/Escape continuation fallback. Re-running `ins` now dedupes old resident daemon/AHK/rescue helper processes before starting fresh tasks, so repeated installs do not leave several daemon copies racing; the sweep mutex still prevents double-launches.

Current CRC/checksum hardening: the Avatar screenshot showed `ISDone.dll` / `Unarc.dll` error `-12` with `Does not match checksum` and `failed CRC check` for `F:\Downloads\Avatar - Frontiers of Pandora\rogue\sdf\pc\data\sdf-A-0022.sdfdata`. That class is now treated as source-integrity failure, not as a wizard prompt to retry forever. Before launching any source that has `MD5\fitgirl-bins.md5`, the PowerShell sweep verifies the listed `.bin` files with full MD5 and caches the verified signature in `.qbit-force-source-md5-ok.txt`; unchanged verified sources skip rehashing. If a required file is missing or any listed present file mismatches, the source gets `.qbit-force-hard-fail.txt` with `SOURCE_INTEGRITY_FAILED_MD5` and is skipped before `setup.exe` can display an ISDone/Unarc popup. If a checksum/CRC popup still appears at runtime, the AHK watchdog marks only that exact source as `CHECKSUM_CRC_SOURCE_FAILURE`, deletes stale done/hash-cache markers, cleans only its incomplete install target, dismisses the popup, and prevents relaunch until the source is repaired/redownloaded/rechecked.

Current retry hardening still prevents temporary installer-state failures from permanently skipping a qBittorrent-completed source, but checksum/CRC/source-integrity failures are now excluded from the retry loop. Write/temp/lock failures are reset from a clean target/temp state. `Does not match checksum`, `failed CRC check`, source MD5 mismatch, and similar source-integrity failures are marked for recheck/redownload and skipped before relaunch so the same ISDone/Unarc popup is not shown repeatedly.

The AHK watchdog click loop stays at 50 ms, but its extra PowerShell safety sweep is throttled to 5 seconds because qBittorrent hook + the resident 250 ms PowerShell daemon are already responsible for immediate launches. This prevents repeated PowerShell child processes from starving installer prompt clicks while still keeping a fallback scan.

The clicker now fast-skips active Installing/Unpacking progress pages even when the installer exposes an enabled Next button, so a real extraction page is left alone instead of being clicked every few minutes. All routine AHK button actions are now background/no-activate control clicks (`ControlClick ... NA`) or background `ControlSend`; the watchdog must not call `WinActivate` or send global `{Enter}`. This keeps games and other foreground apps focused while installers continue on monitor 2.



Current no-rerun/click-latency hardening: the canonical command still refreshes the qBittorrent hook, daemon, AHK watchdog, popup rescue, and runs one immediate sweep, but it must never reinstall/delete a target that is already fully installed in `F:\Downloads\<game name>`. `-RunOnceAfterInstall` opens ready not-yet-installed sources only; fully installed targets log `SKIP already-successfully-installed-never-rerun`. The installed-target check must use credible evidence only: trusted AHK final-page markers or a real main game executable. Small helper files such as `Language Selector.exe`, uninstallers, QuickSFV, redist, DirectX, temp/support helpers, and sub-512KB helper executables must not count as a completed install; if an old done marker only points at such a helper, the next sweep removes it as `STALE_DONE_MARKER_REMOVED ... no-credible-main-exe-or-trusted-finish-marker` and allows the ready source to launch again. The AHK watchdog now checks disabled button style bits and has an extra immediate safe-click path for OK/Yes/Next/Install/Continue after error/final-page handlers, reducing delayed repeated clicks while never pressing Finish/Cancel/Abort/Retry/Back/No.

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
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Force-QbitFitGirlAutoInstall.ps1 -Daemon -PollMilliseconds 250
```

Run the AutoHotkey syntax self-test:

```powershell
& 'C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe' '.\scripts\FitGirlAutoClicker.ahk' --selftest
```

## Future-session handoff / non-negotiable contract

This section is for future Hermes/agent sessions. For any future mission about this project, treat the current behavior below as intentional and preserve it unless the user explicitly asks to change the policy in that same session.

### Canonical run command

The known-good command the user may paste or ask about is:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "F:\study\Windows\Applications\Gaming\DownloadManagers\qBittorrent\FitGirl\Automation\AutoInstall\qbittorrent-fitgirl-force-auto-install-20260601\scripts\Force-QbitFitGirlAutoInstall.ps1" -Install -RunOnceAfterInstall
```

If asked whether this command is the right one, keep it exactly as above unless the script path genuinely changes. It installs/refreshes qBittorrent hook, scheduled watcher, AHK clicker, popup rescue, and runs one immediate completed-download sweep. On this explicit manual/run command, prior `.qbit-force-install-done.txt` markers are cleared for completed ready sources and the filesystem-ready fallback is accepted immediately for complete folders, so a fresh user-triggered run can reinstall every ready source in that same run; background daemon and qBittorrent hook sweeps still keep done markers and the normal two-scan stability gate to avoid automatic relaunch loops after successful installs.

### Intended behavior to preserve

- Project scope: qBittorrent `F:\Downloads` completed FitGirl/Inno repacks only.
- Completion handoff must be immediate:
  - qBittorrent completion hook is the zero-wait path.
  - Resident PowerShell daemon polls every 250 ms as a missed-hook fallback.
  - AHK has only a throttled 5 second safety sweep so it does not slow clicks.
- No artificial installer slot cap: every eligible completed source may launch in the same sweep.
- Never launch incomplete downloads: explicit qBittorrent incomplete proof wins. If qBittorrent proof is unavailable/null, use the conservative stable-filesystem fallback only when `setup.exe` + payload exists, no partial files exist, and the signature is stable across scans.
- Every launched setup must use exact-path launch and arguments like:
  - `/SP-`
  - `/DIR="F:\Downloads\<game name>"`
  - `/NORESTART`
  - `/SUPPRESSMSGBOXES`
  - `/TASKS=""`
  - `/MERGETASKS=""`
  - `/COMPONENTS=""`
- Optional DirectX/VC++/redist/web-download/certificate/TLS failures should be skipped/ignored/continued when safe; do not let certificate errors block installation.
- AHK click loop must stay fast and interactive:
  - Tick every 50 ms.
  - Move installer dialogs to monitor 2.
  - Force the 2 GB RAM limit checkbox when present.
  - Keep destination edit boxes at the marker path.
  - Click language OK, Next, Install, folder-exists Yes/OK, optional Ignore/Continue.
  - Leave finished installer pages open and do not press Finish; uncheck final launch/readme/site boxes.
  - Fast-skip active Installing/Unpacking progress pages before expensive scans so running installers do not delay prompt clicks for other installers.

### Running-install stall and foreground-safety policy

The daemon records a per-source progress signature for every exact running `setup.exe` tree: install-target file count/bytes/latest write time plus setup/helper CPU. A visible percent that does not move is **not** enough to call an installer stuck, because FitGirl external helpers can spend a long time rebuilding one big file while the UI stays on the same percent. If the progress signature changes, the daemon logs `INSTALL_PROGRESS_ACTIVE` and leaves that installer alone. Only if the signature is unchanged for the configured stall threshold (default 6 minutes) does it stop that exact source's setup/helper tree, delete only that separate incomplete install target, remove launch/done markers, and allow the next sweep to relaunch it cleanly.

The AHK watchdog must not steal focus from games or foreground apps. It should move installer windows to monitor 2 when needed, but routine prompt handling must use background `ControlClick ... NA`/`ControlSend` and must not call `WinActivate` or global `Send`. Active progress pages are skipped before clicking even when a `Next` button is visible, preventing repeated `Next` clicks from hijacking input during gameplay.

### Done-marker policy

- Background daemon and qBittorrent hook sweeps should skip `.qbit-force-install-done.txt` sources to prevent endless reinstall loops after a successful installation.
- The explicit user run command with `-Install -RunOnceAfterInstall` accepts complete filesystem-ready sources immediately, but it must not clear done markers or relaunch/delete targets that are already fully installed in their folder.

### Critical policy learned on 2026-06-02

The user corrected that `Still Wakes the Deep` was not to be treated as permanently corrupt. The current required policy is:

- Do **not** permanently skip a qBittorrent-completed source just because a previous ISDone/Unarc/CRC/archive-corrupt marker exists.
- If the user says the source is known-good or asks for no ready download to be missed, clear that source's `.qbit-force-hard-fail.txt`, clean only its separate incomplete install target/temp state, and relaunch from the completed source.
- Future ISDone/Unarc/archive/CRC screens should be dismissed/reset by AHK and retried instead of persisting a permanent skip marker.
- Still be truthful in final answers: no script can make real hardware failure, disk failure, antivirus quarantine, or genuinely bad source bytes impossible. But this project must not leave a completed ready source idle because of the old hard-fail marker policy.

### What to inspect before changing anything

For future debugging, inspect these before editing or claiming behavior:

```powershell
Get-CimInstance Win32_Process | Where-Object { $_.Name -in @('setup.exe','setup.tmp','AutoHotkey64.exe','powershell.exe') -and (''+$_.CommandLine -match 'FitGirl|Force-Qbit|qbit-force|setup\.exe') } | Select ProcessId,Name,CommandLine
Get-Content -Tail 120 -LiteralPath 'F:\Downloads\.fitgirl_tmp\qbit-force-auto-install\force-auto-install.log'
Get-Content -Tail 120 -LiteralPath 'F:\Downloads\.fitgirl_tmp\qbit-force-auto-install\fitgirl-ahk-watchdog.log'
Get-ChildItem -LiteralPath 'F:\Downloads' -Recurse -Force -Filter '.qbit-force-hard-fail.txt'
```

When the user asks for screenshot proof, capture full monitor snapshots and send the monitor that visibly contains the installer windows first. Process proof alone is not enough if the user explicitly asks for screenshots.

### Required verification after code changes

Always run these before finalizing code changes:

```powershell
$script='F:\study\Windows\Applications\Gaming\DownloadManagers\qBittorrent\FitGirl\Automation\AutoInstall\qbittorrent-fitgirl-force-auto-install-20260601\scripts\Force-QbitFitGirlAutoInstall.ps1'
$tokens=$null; $errors=$null
[System.Management.Automation.Language.Parser]::ParseFile($script,[ref]$tokens,[ref]$errors) | Out-Null
if($errors.Count){ $errors | Format-List *; exit 10 }
'PS_PARSE_OK'
& 'C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe' 'F:\study\Windows\Applications\Gaming\DownloadManagers\qBittorrent\FitGirl\Automation\AutoInstall\qbittorrent-fitgirl-force-auto-install-20260601\scripts\FitGirlAutoClicker.ahk' --selftest
'AHK_SELFTEST_OK'
```

If the mission asks to run the project, run the canonical `-Install -RunOnceAfterInstall` command or PowerShell function `ins`, then verify live watcher/clicker/rescue processes, recent log classification, and actual installer windows/screenshot proof.


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
- If a finished download does not launch, inspect `force-auto-install.log`; hook-triggered items should show `HOOK_HINT_COMPLETION_ACCEPTED` when `.fastresume` is late, while background sweeps still skip incomplete torrents.
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
