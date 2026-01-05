# ULTIMATE UNINSTALLER NUCLEAR - C++ Edition

## 🚀 ZERO LEFTOVERS GUARANTEE

This is the **NUCLEAR version** rewritten in C++ that absolutely obliterates every trace of an application as if it never existed on your system.

## 🔥 Key Improvements Over TURBO Version

### What TURBO Missed (That NUCLEAR Destroys):

1. **WinSxS Manifests** - TURBO protected WinSxS, NUCLEAR scans and deletes app-specific manifests
2. **SoftwareDistribution** - Windows Update cache leftovers
3. **DriverStore** - Driver cache in System32\DriverStore\FileRepository
4. **Windows Installer Cache** - C:\Windows\Installer cached MSI files
5. **All User Profiles** - TURBO only scanned current user, NUCLEAR scans ALL users
6. **Taskbar Pins** - Quick Launch pinned items
7. **Start Menu Shortcuts** - Both All Users and Current User
8. **Desktop Shortcuts** - Both All Users and Current User
9. **Startup Items** - Both registry and folder-based
10. **Multiple Registry Hives** - HKEY_USERS, HKEY_CLASSES_ROOT in addition to HKLM/HKCU

## 📦 Compilation

### Requirements:
- **MinGW-w64** or **TDM-GCC** (for g++ compiler)
- Windows 7 or later
- Administrator privileges

### Easy Compilation:
```batch
compile_nuclear.bat
```

### Manual Compilation:
```bash
g++ -O3 -std=c++17 ultimate_uninstaller_NUCLEAR.cpp -o ultimate_uninstaller_NUCLEAR.exe -lshlwapi -ladvapi32 -lkernel32 -lrstrtmgr -lole32 -luuid -lshell32 -lpropsys -static -municode
```

## 🎯 Usage

### Basic Usage:
```batch
ultimate_uninstaller_NUCLEAR.exe "APP NAME"
```

### Advanced Usage (Multiple Search Terms):
```batch
ultimate_uninstaller_NUCLEAR.exe "DRIVER BOOSTER" DRIVERBOOSTER IOBIT
```

### Your Example:
```batch
ultimate_uninstaller_NUCLEAR.exe "DRIVER BOOSTER" DRIVERBOOSTER
```

This will search for:
- "DRIVER BOOSTER" (with spaces)
- "DRIVERBOOSTER" (without spaces)

And obliterate ALL matching files, folders, registry entries, services, processes, and shortcuts.

## 🛡️ Safety Features

NUCLEAR mode is aggressive but still protects:
- Critical Windows system files (ntoskrnl.exe, kernel32.dll, etc.)
- Windows Boot files
- System configuration (registry hives)
- Core Windows services (csrss.exe, lsass.exe, etc.)

**However**, it WILL delete:
- App-specific WinSxS manifests (e.g., ReadyBoost driver manifests installed by your app)
- App-specific entries in SoftwareDistribution
- App drivers from DriverStore
- Vendor subfolders in System32 (like ASUSACCI, IObitUninstaller, etc.)

## 📊 Statistics Reported

After completion, you'll see:
- Files Deleted
- Directories Deleted
- Processes Killed
- Registry Keys Deleted
- Services Deleted
- Shortcuts Removed

## ⚡ Performance

- **Time**: 2-3 minutes (extended from TURBO's 2-minute limit for thoroughness)
- **Depth**: Scans deeper (up to 15 levels in critical directories)
- **Threads**: Uses up to 12 threads for parallel operations

## 🔧 What Gets Scanned

### Directories:
- ✅ C:\Program Files
- ✅ C:\Program Files (x86)
- ✅ C:\ProgramData
- ✅ C:\Windows\System32
- ✅ C:\Windows\SysWOW64
- ✅ C:\Windows\Temp
- ✅ C:\Windows\Prefetch
- ✅ **C:\Windows\WinSxS** (NEW!)
- ✅ **C:\Windows\SoftwareDistribution** (NEW!)
- ✅ **C:\Windows\System32\DriverStore** (NEW!)
- ✅ **C:\Windows\Installer** (NEW!)
- ✅ **C:\Users\*\AppData\Local** (ALL USERS - NEW!)
- ✅ **C:\Users\*\AppData\Roaming** (ALL USERS - NEW!)
- ✅ **C:\Users\*\AppData\LocalLow** (ALL USERS - NEW!)
- ✅ C:\Windows (shallow scan)
- ✅ C:\ (root, shallow scan)

### Shortcuts & Pins:
- ✅ **Desktop (All Users)** (NEW!)
- ✅ **Desktop (Current User)** (NEW!)
- ✅ **Start Menu (All Users)** (NEW!)
- ✅ **Start Menu (Current User)** (NEW!)
- ✅ **Startup (All Users)** (NEW!)
- ✅ **Startup (Current User)** (NEW!)
- ✅ **Taskbar Pins** (NEW!)
- ✅ **Quick Launch Pins** (NEW!)

### Registry Hives:
- ✅ HKEY_LOCAL_MACHINE
- ✅ HKEY_CURRENT_USER
- ✅ **HKEY_USERS** (NEW!)
- ✅ **HKEY_CLASSES_ROOT** (NEW!)

### Registry Paths:
- SOFTWARE (all subkeys)
- SOFTWARE\WOW6432Node
- Uninstall keys (both 32-bit and 64-bit)
- Run/RunOnce keys
- Services
- Device Enumerations
- Class registrations
- Image File Execution Options

## 🔄 Reboot-Scheduled Deletion

Files that are locked or in use will be scheduled for deletion on next reboot using `MOVEFILE_DELAY_UNTIL_REBOOT`.

After completion, NUCLEAR will ask if you want to reboot immediately.

## ⚠️ WARNING

This tool is **EXTREMELY AGGRESSIVE**. Use it only when:
1. You're absolutely sure you want to completely remove an application
2. You've backed up important data
3. You understand it will remove EVERYTHING related to the app, including:
   - User preferences
   - Saved data
   - Configuration files
   - All traces in registry
   - All shortcuts and pins

## 🎯 Example: Driver Booster Removal

```batch
ultimate_uninstaller_NUCLEAR.exe "DRIVER BOOSTER" DRIVERBOOSTER IOBIT ASUSACCI
```

This will obliterate:
- All IObit/Driver Booster files
- ReadyBoost driver leftovers in WinSxS
- ASUS component integration (ASUSACCI folders)
- All registry entries
- All shortcuts and taskbar pins
- All startup entries
- All services
- All drivers from DriverStore

Result: **Your C: drive will be as if Driver Booster was NEVER installed!**

## 🏗️ C++ Advantages Over C

1. **std::wstring** - Safer string handling, no buffer overflows
2. **std::vector** - Dynamic arrays for search terms
3. **Better memory management** - RAII principles
4. **Inline functions** - Better optimization
5. **Type safety** - Compile-time error checking

## 📝 License

Use at your own risk. This tool is provided as-is for educational purposes.

## 🤝 Contributing

This is the NUCLEAR version. If you need even more aggressive cleaning, let me know what's still being missed!
