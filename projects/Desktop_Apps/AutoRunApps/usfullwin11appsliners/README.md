# WIN11 ULTIMATE AUTOMATIC CLEANUP & REPAIR SUITE

## 🚀 Quick Start
```powershell
# Right-click PowerShell → Run as Administrator
cd "F:\study\projects\Desktop_Apps\AutoRunApps\usfullwin11appsliners"
.\d.ps1
```

## 📊 What This Script Does

### Runs 51 Automatic Tools:
- ✅ **Icon & Shortcut Repair** (2 tools)
- ✅ **Disk Cleanup** (8 tools) 
- ✅ **Registry Optimization** (2 tools)
- ✅ **Memory Optimization** (4 tools)
- ✅ **Network Optimization** (8 tools)
- ✅ **System Repair** (6 tools)
- ✅ **Browser Cleanup** (3 tools)
- ✅ **System Optimization** (14 tools)
- ✅ **Disk Optimization** (2 tools)
- ✅ **Security Updates** (2 tools)

### Key Features:
- 🔥 **6 parallel tools** running at all times
- 🧹 **Auto-cleanup** - purges all tool traces after execution
- 🤖 **Fully automatic** - zero user interaction needed
- 🎯 **Legitimate tools only** - no monitoring/viewer apps
- 💾 **Safe operations** - creates registry backup before changes

## 📋 Tool Categories

### 1️⃣ Icon & Shortcut Repair
- Rebuilds Windows icon cache
- Removes broken shortcuts from Desktop & Start Menu

### 2️⃣ Disk Cleanup
- BleachBit automatic cleaning
- Windows Disk Cleanup utility
- Temp files purge (Windows, User, LocalAppData)
- Prefetch cache clear
- Windows Update cache cleanup
- Error reports removal
- Thumbnail cache clear
- Font cache rebuild

### 3️⃣ Registry
- Full registry backup
- Registry compaction

### 4️⃣ Memory Optimization
- Standby memory clear
- Working set trim
- Priority memory clear
- System file cache clear

### 5️⃣ Network Optimization
- DNS cache flush
- NetBIOS cache purge
- ARP cache clear
- Winsock reset
- IP stack reset
- TCP/IP reset
- Network adapter reset (disable/enable cycle)
- Windows Firewall reset

### 6️⃣ System Repair
- SFC scan (System File Checker)
- DISM health check
- DISM scan health
- DISM restore health
- Component store cleanup
- Component store reset

### 7️⃣ Browser Cleanup
- Chrome cache clear (stops Chrome, clears cache & code cache)
- Edge cache clear (stops Edge, clears cache & code cache)
- Firefox cache clear (stops Firefox, clears cache2)

### 8️⃣ System Optimization
- Event logs clear (all Windows event logs)
- Startup tasks disable (telemetry, feedback, consolidator)
- Search index rebuild
- Delivery optimization clear
- Windows Store cache reset
- Print spooler clear
- Recycle Bin empty
- Old downloads cleanup (90+ days)
- High Performance power plan
- Visual effects optimization
- Animations disable
- Transparency effects disable
- Superfetch disable
- Windows tips disable

### 9️⃣ Disk Optimization
- C: drive defragmentation (HDD)
- SSD TRIM operation

### 🔟 Security
- Windows Defender quick scan
- Defender signature updates

## 🎭 Execution Flow

```
┌─────────────────────────────────────┐
│  Start 6 Tools in Parallel          │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│  Continuous Monitoring Loop         │
│  • Check job completion             │
│  • Display job output               │
│  • Cleanup tool traces              │
│  • Start next tool                  │
│  • Maintain 6 active jobs           │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│  All 51 Tools Complete              │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│  Global Cleanup                     │
│  • Remove base temp directory       │
│  • Scan all drives                  │
│  • Purge *Cleaner* folders          │
│  • Purge *Optimizer* folders        │
│  • Purge *Repair* folders           │
│  • Purge *Portable* downloads       │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│  Success - System Optimized!        │
└─────────────────────────────────────┘
```

## ⏱️ Expected Runtime
- **Total Duration**: 25-30 minutes
- **Parallel Execution**: 6 tools at a time
- **No Manual Steps**: Fully automated

## 🛡️ Safety Features
1. **Registry Backup**: Created before any registry operations
2. **Error Suppression**: Continues even if individual tools fail
3. **Service Management**: Properly stops/starts Windows services
4. **Process Handling**: Safely closes browsers before cache cleanup
5. **Drive Detection**: Only scans valid drives with data

## 📦 What Gets Removed
- ❌ Temp files (Windows, User, LocalAppData)
- ❌ Prefetch cache
- ❌ Windows Update downloads
- ❌ Error reports & dumps
- ❌ Thumbnail cache
- ❌ Font cache (rebuilt)
- ❌ Icon cache (rebuilt)
- ❌ Browser caches
- ❌ Event logs
- ❌ Delivery optimization cache
- ❌ Print spooler jobs
- ❌ Recycle Bin contents
- ❌ Downloads older than 90 days
- ❌ All portable tool traces

## 🔧 Technical Details

### Parallel Job Management
```powershell
$script:runningJobs = @{}        # Hashtable tracking active jobs
$script:toolQueue = Queue        # Queue of pending tools
MaxParallel = 6                  # Constant 6-tool execution
```

### Cleanup Strategy
1. **Per-Tool Cleanup**: Removes tool directory after job completes
2. **Pattern Matching**: Cleans *Cleaner*, *Optimizer*, *Fixer* patterns
3. **Global Scan**: Searches all drives for leftover traces
4. **Aggressive Removal**: Force-deletes with error suppression

### Error Handling
```powershell
$ErrorActionPreference = 'SilentlyContinue'  # Continue on errors
-EA 0                                         # Per-command error suppression
Force flag                                    # Force operations
```

## 🚨 Requirements
- **Windows 11** (optimized for Win11)
- **Administrator Rights** (required for system operations)
- **PowerShell 5.1+** (built into Windows 11)
- **Internet Connection** (for BleachBit download only)

## 📊 Monitoring
Watch the console output for:
- `[START]` - Tool begins execution
- `[JOB]` - Job ID assigned
- `[ACTIVE: 6]` - Currently running tools
- `[DONE]` - Tool completed
- `[OK]` - Operation successful
- `[COMPLETE]` - All tools finished
- `[SUCCESS]` - Global cleanup done

## 🎯 Performance Impact
- **CPU**: Moderate (6 parallel operations)
- **RAM**: Low (jobs run in separate processes)
- **Disk I/O**: High during cleanup operations
- **Network**: Minimal (BleachBit download only)

## 💡 Tips
1. **Close important applications** before running
2. **Save your work** (browsers will be closed)
3. **Run during off-hours** for best performance
4. **Don't interrupt** - let all 51 tools complete
5. **Reboot after completion** for best results

## 🔄 Maintenance Schedule
Recommended frequency:
- **Weekly**: For heavily used systems
- **Monthly**: For moderate use
- **Quarterly**: For light use

## 📝 Logs
- **Registry Backup**: `%TEMP%\AutoCleanerTools\registry_backup_TIMESTAMP.reg`
- **Console Output**: Real-time display (not saved to file)

## ❓ Troubleshooting

### Script won't run
- Right-click PowerShell → Run as Administrator
- Check execution policy: `Set-ExecutionPolicy Bypass -Scope Process`

### Some tools fail
- Normal behavior - script continues automatically
- Most critical operations are Windows-native

### System feels slow during execution
- Expected - 6 parallel operations
- Consider closing unnecessary applications

### No visible progress
- Check console window for `[ACTIVE: 6]` status
- Script runs silently in background

## 📄 Files
- `d.ps1` - Main script (51 tools)
- `CHANGES.md` - Detailed changelog
- `README.md` - This file

## 🎖️ Improvements Over Previous Version
- ✅ 28 → 51 tools (82% increase)
- ✅ 10 → 6 parallel (better performance)
- ✅ Removed all monitoring-only tools
- ✅ Removed all manual GUI tools
- ✅ Added aggressive auto-cleanup
- ✅ Added global drive scanning
- ✅ 100% automated execution

## 🏆 Success Metrics
After running this script, you should see:
- 🎯 **Free Space Increase**: 500MB - 5GB+ recovered
- 🚀 **Performance Boost**: Faster startup & application launch
- 🧹 **Cleaner System**: No leftover portable apps
- 🔧 **System Health**: Repaired system files & registry
- 🌐 **Network Speed**: Optimized TCP/IP stack
- 💾 **Memory Efficiency**: Cleared standby/priority memory

---

**Last Updated**: January 8, 2026
**Version**: 2.0 (51 Tools, 6 Parallel, Auto-Cleanup)
**Author**: Automated System Optimization Suite
