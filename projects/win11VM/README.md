# Windows 11 VM Runner

This folder is a small launcher project for a Hyper-V Windows 11 VM on this PC.

It is designed to keep the repository tiny. The real VM files are generated only when you run the scripts, and the generated `vm`, `logs`, and `state` folders are ignored by Git and can be safely removed.

## What This Project Does

- Creates or reuses a Hyper-V VM named `Codex-Win11-Ready`.
- Boots it from a small differencing disk created from an existing local parent disk. Preferred location:

```text
F:\Downloads\VMREplica\VHDX\VMReplica-CurrentWindows.VHDX
```

- Keeps that parent replica unchanged.
- Searches common locations for that parent disk if you do not pass a path.
- Connects the VM to the external Hyper-V switch `Codex External Ethernet` when possible, so the VM gets a real LAN address.
- Opens the VM console.
- Verifies the guest is Windows 11 by checking the guest OS version build.

## Normal Use

Run this whenever you want to start the VM:

```powershell
cd F:\study\projects\win11VM
.\Start-Win11VM.ps1
```

If the VM files were cleaned before, this recreates what is needed and starts the VM again.

If the parent disk is somewhere else:

```powershell
.\Start-Win11VM.ps1 -ParentVhd "X:\full\path\to\WindowsParent.vhdx"
```

## Rebuild And Run

Use this when you want a fresh generated VM state from the parent replica:

```powershell
cd F:\study\projects\win11VM
.\Rebuild-AndRun-Win11VM.ps1 -CleanFirst
```

To open the Enhanced Session RDP launcher that requests all local drive redirection:

```powershell
cd F:\study\projects\win11VM
.\Rebuild-AndRun-Win11VM.ps1 -OpenAllDrives
```

Drive redirection is safe because it does not pass through or dismount physical host disks. It asks the Windows remote session to expose local drives inside the VM session.

## Clean To Smallest Size

Run this when you are done and want this folder to take the smallest practical amount of space:

```powershell
cd F:\study\projects\win11VM
.\Cleanup-Win11VM.ps1
```

This removes only generated project artifacts:

- `vm\`
- `state\`
- `logs\`
- the local Hyper-V registration for `Codex-Win11-Ready`

It does not remove or modify:

- `F:\Downloads\VMREplica\VHDX\VMReplica-CurrentWindows.VHDX`
- any parent VHD/VHDX passed with `-ParentVhd`
- any host drive such as `C:`, `D:`, `E:`, `F:`, or `G:`
- any unrelated VM
- any Git files outside this project

## Verify

After starting the VM, run:

```powershell
cd F:\study\projects\win11VM
.\Verify-Win11VM.ps1
```

Success means:

- VM state is `Running`
- Hyper-V heartbeat is `OK`
- VMConnect is open
- guest OS version build is Windows 11 build range (`22000+`)

## Files You Should Care About

- `Start-Win11VM.ps1` starts or recreates the VM when needed.
- `Rebuild-AndRun-Win11VM.ps1` optionally cleans first, then runs the VM.
- `Cleanup-Win11VM.ps1` safely removes generated space.
- `Verify-Win11VM.ps1` checks the running VM.
- `Connect-Win11VM-AllDrives.rdp` requests all local drives in Enhanced Session.
- `Open-Win11VM-AllDrives.ps1` opens that RDP launcher.

Everything else is support code.
