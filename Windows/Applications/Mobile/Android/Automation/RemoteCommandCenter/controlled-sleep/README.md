# RemoteCommandCenter Controlled Sleep

This project provides the RemoteCommandCenter sleep helper.

Primary Android mode uses real Windows suspend through
`powrprof.SetSuspendState(hibernate: false, forceCritical: true,
disableWakeEvent: false)` after the RemoteCommandCenter action script arms the
Windows/NIC wake policy. The Android Wake button still sends the existing
Wake-on-LAN burst for shutdown wake and sleep wake.

The helper also includes a fallback controlled overlay mode. That mode does not
call Windows sleep or hibernate. It starts a full-screen black, topmost overlay,
asks Windows to turn monitors off, and exits only from:

- Android Wake command through the local signal file.
- Android Wake command through the relay topic.
- Space key.
- Mouse double-click.

The runtime files, logs, marker file, and wake signal live under the
RemoteCommandCenter `runtime` folder on `F:\study`. There are no project-owned
runtime files under `C:\`.

The executable is:

`controlled-sleep\dist\RccControlledSleep.exe`

Build:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\controlled-sleep\build.ps1
```

Proof-only smoke test:

```powershell
.\controlled-sleep\dist\RccControlledSleep.exe --config .\scripts\rcc-config.json --proof
.\controlled-sleep\dist\RccControlledSleep.exe --config .\scripts\rcc-config.json --actual-sleep --proof
```
