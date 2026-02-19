# MEGACLEAN 5X ULTRA - 1000+ Operations
# NO Docker/WSL - PowerShell v5 Compatible

$ErrorActionPreference = 'SilentlyContinue'
$script:completed = 0
$script:total = 1009
$start = Get-Date
$startFree = [math]::Round(((Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'" -EA 0).FreeSpace/1GB),2)

function Clean {
    param([string]$name, [scriptblock]$action)
    $script:completed++
    Write-Host "[$script:completed/$script:total] " -NoNewline -ForegroundColor Cyan
    Write-Host "$name " -NoNewline -ForegroundColor Yellow
    try {
        & $action
        Write-Host "OK" -ForegroundColor Green
    } catch {
        Write-Host "SKIP" -ForegroundColor Red
    }
}

Write-Host "`n=== MEGACLEAN 5X ULTRA STARTED ===" -ForegroundColor Magenta
Write-Host "C: Free before: ${startFree}GB" -ForegroundColor Gray

# ============================================================================
# PHASE 1: WINDOWS TEMP (25 operations)
# ============================================================================
Write-Host "`n[PHASE 1/20] WINDOWS TEMP" -ForegroundColor White
Clean "win-temp" { Remove-Item "C:\Windows\Temp\*" -Recurse -Force -EA 0 }
Clean "win-temp2" { Remove-Item "C:\Temp\*" -Recurse -Force -EA 0 }
Clean "win-systemtemp" { Remove-Item "C:\Windows\SystemTemp\*" -Recurse -Force -EA 0 }
Clean "win-cbstemp" { Remove-Item "C:\Windows\CbsTemp\*" -Recurse -Force -EA 0 }
Clean "serviceprofile-local" { Remove-Item "C:\Windows\ServiceProfiles\LocalService\AppData\Local\Temp\*" -Recurse -Force -EA 0 }
Clean "serviceprofile-network" { Remove-Item "C:\Windows\ServiceProfiles\NetworkService\AppData\Local\Temp\*" -Recurse -Force -EA 0 }
Clean "serviceprofile-fontcache" { Remove-Item "C:\Windows\ServiceProfiles\LocalService\AppData\Local\FontCache\*" -Recurse -Force -EA 0 }
Clean "win-temp-old" { Get-ChildItem "C:\Windows\Temp" -Directory -EA 0 | Where-Object {$_.LastWriteTime -lt (Get-Date).AddDays(-7)} | Remove-Item -Recurse -Force -EA 0 }
Clean "win-temp-logs" { Remove-Item "C:\Windows\Temp\*.log" -Force -EA 0 }
Clean "win-temp-tmp" { Remove-Item "C:\Windows\Temp\*.tmp" -Force -EA 0 }
Clean "win-temp-etl" { Remove-Item "C:\Windows\Temp\*.etl" -Force -EA 0 }
Clean "win-temp-cab" { Remove-Item "C:\Windows\Temp\*.cab" -Force -EA 0 }
Clean "win-temp-msi" { Remove-Item "C:\Windows\Temp\*.msi" -Force -EA 0 }
Clean "win-temp-msp" { Remove-Item "C:\Windows\Temp\*.msp" -Force -EA 0 }
Clean "win-temp-msu" { Remove-Item "C:\Windows\Temp\*.msu" -Force -EA 0 }
Clean "win-serviceprofile-localcache" { Remove-Item "C:\Windows\ServiceProfiles\LocalService\AppData\LocalLow\*" -Recurse -Force -EA 0 }
Clean "win-serviceprofile-networkcache" { Remove-Item "C:\Windows\ServiceProfiles\NetworkService\AppData\LocalLow\*" -Recurse -Force -EA 0 }
Clean "win-serviceprofile-locallow" { Remove-Item "C:\Windows\ServiceProfiles\LocalService\AppData\Local\Microsoft\*" -Recurse -Force -EA 0 }
Clean "win-temp-dmp" { Remove-Item "C:\Windows\Temp\*.dmp" -Force -EA 0 }
Clean "win-temp-bak" { Remove-Item "C:\Windows\Temp\*.bak" -Force -EA 0 }
Clean "win-temp-chk" { Remove-Item "C:\Windows\Temp\*.chk" -Force -EA 0 }
Clean "win-appcompat-temp" { Remove-Item "C:\Windows\AppCompat\Programs\*.txt" -Force -EA 0 }
Clean "win-appcompat-cache" { Remove-Item "C:\Windows\AppCompat\Programs\Amcache.hve.tmp" -Force -EA 0 }
Clean "win-tracing" { Remove-Item "C:\Windows\tracing\*" -Recurse -Force -EA 0 }
Clean "win-ccmcache" { Remove-Item "C:\Windows\ccmcache\*" -Recurse -Force -EA 0 }

# ============================================================================
# PHASE 2: WINDOWS LOGS (50 operations)
# ============================================================================
Write-Host "`n[PHASE 2/20] WINDOWS LOGS" -ForegroundColor White
Clean "win-logs" { Remove-Item "C:\Windows\Logs\*" -Recurse -Force -EA 0 }
Clean "win-cbs" { Remove-Item "C:\Windows\Logs\CBS\*" -Recurse -Force -EA 0 }
Clean "win-cbs-persist" { Remove-Item "C:\Windows\Logs\CBS\CbsPersist_*.cab" -Force -EA 0 }
Clean "win-dism" { Remove-Item "C:\Windows\Logs\DISM\*" -Recurse -Force -EA 0 }
Clean "win-dpx" { Remove-Item "C:\Windows\Logs\DPX\*" -Recurse -Force -EA 0 }
Clean "win-mosetup" { Remove-Item "C:\Windows\Logs\MoSetup\*" -Recurse -Force -EA 0 }
Clean "win-measuredboot" { Remove-Item "C:\Windows\Logs\MeasuredBoot\*" -Recurse -Force -EA 0 }
Clean "win-sih" { Remove-Item "C:\Windows\Logs\SIH\*" -Recurse -Force -EA 0 }
Clean "win-windowsupdate" { Remove-Item "C:\Windows\Logs\WindowsUpdate\*" -Recurse -Force -EA 0 }
Clean "win-waasmedia" { Remove-Item "C:\Windows\Logs\waasmedic\*" -Recurse -Force -EA 0 }
Clean "win-inf" { Remove-Item "C:\Windows\inf\*.log" -Force -EA 0 }
Clean "win-debug" { Remove-Item "C:\Windows\Debug\*" -Recurse -Force -EA 0 }
Clean "win-panther" { Remove-Item "C:\Windows\Panther\*" -Recurse -Force -EA 0 }
Clean "win-pantherUn" { Remove-Item "C:\Windows\Panther\UnattendGC\*" -Recurse -Force -EA 0 }
Clean "win-minidump" { Remove-Item "C:\Windows\Minidump\*" -Recurse -Force -EA 0 }
Clean "win-memorydmp" { Remove-Item "C:\Windows\MEMORY.DMP" -Force -EA 0 }
Clean "win-livekernelreports" { Remove-Item "C:\Windows\LiveKernelReports\*" -Recurse -Force -EA 0 }
Clean "win-sys32-logfiles" { Remove-Item "C:\Windows\System32\LogFiles\*" -Recurse -Force -EA 0 }
Clean "win-sys32-wdi" { Remove-Item "C:\Windows\System32\WDI\LogFiles\*" -Recurse -Force -EA 0 }
Clean "win-sys32-sru" { Remove-Item "C:\Windows\System32\sru\*" -Recurse -Force -EA 0 }
Clean "win-sys32-spool" { Remove-Item "C:\Windows\System32\spool\PRINTERS\*" -Recurse -Force -EA 0 }
Clean "win-sys32-winevt" { Remove-Item "C:\Windows\System32\winevt\Logs\*.evtx" -Force -EA 0 }
Clean "win-perflogs" { Remove-Item "C:\PerfLogs\*" -Recurse -Force -EA 0 }
Clean "win-setupapi" { Remove-Item "C:\Windows\inf\setupapi*.log" -Force -EA 0 }
Clean "win-pnp" { Remove-Item "C:\Windows\Logs\SystemRestore\*" -Recurse -Force -EA 0 }
Clean "win-appcompat-logs" { Remove-Item "C:\Windows\Logs\AppCompat\*" -Recurse -Force -EA 0 }
Clean "win-appx-logs" { Remove-Item "C:\Windows\Logs\APPX\*" -Recurse -Force -EA 0 }
Clean "win-netsetup-logs" { Remove-Item "C:\Windows\Logs\NetSetup\*" -Recurse -Force -EA 0 }
Clean "win-dosvc-logs" { Remove-Item "C:\Windows\Logs\dosvc\*" -Recurse -Force -EA 0 }
Clean "win-winpne-logs" { Remove-Item "C:\Windows\Logs\WinPN\*" -Recurse -Force -EA 0 }
Clean "win-bits-logs" { Remove-Item "C:\Windows\Logs\bits\*" -Recurse -Force -EA 0 }
Clean "win-wsus-logs" { Remove-Item "C:\Windows\Logs\wsus\*" -Recurse -Force -EA 0 }
Clean "win-sechealth" { Remove-Item "C:\Windows\Logs\SecHealth\*" -Recurse -Force -EA 0 }
Clean "win-wlan-logs" { Remove-Item "C:\Windows\Logs\wlan\*" -Recurse -Force -EA 0 }
Clean "win-sfc-logs" { Remove-Item "C:\Windows\Logs\SFC\*" -Recurse -Force -EA 0 }
Clean "win-bootlog" { Remove-Item "C:\Windows\ntbtlog.txt" -Force -EA 0 }
Clean "win-setuplog" { Remove-Item "C:\Windows\setupact.log" -Force -EA 0 }
Clean "win-setuperr" { Remove-Item "C:\Windows\setuperr.log" -Force -EA 0 }
Clean "win-dpinst" { Remove-Item "C:\Windows\dpinst.log" -Force -EA 0 }
Clean "win-windowsupdate-log" { Remove-Item "C:\Windows\WindowsUpdate.log" -Force -EA 0 }
Clean "win-pfirewall" { Remove-Item "C:\Windows\pfirewall.log" -Force -EA 0 }
Clean "win-debuglog" { Remove-Item "C:\Windows\Debug\*.log" -Force -EA 0 }
Clean "win-debugdmp" { Remove-Item "C:\Windows\Debug\*.dmp" -Force -EA 0 }
Clean "win-debugetl" { Remove-Item "C:\Windows\Debug\*.etl" -Force -EA 0 }
Clean "win-netsetuplog" { Remove-Item "C:\Windows\Debug\netsetup.log" -Force -EA 0 }
Clean "win-mrt-log" { Remove-Item "C:\Windows\Debug\mrt.log" -Force -EA 0 }
Clean "win-dcpromo-logs" { Remove-Item "C:\Windows\Debug\dcpromo*.log" -Force -EA 0 }
Clean "win-mocomp-logs" { Remove-Item "C:\Windows\Logs\MoComp\*" -Recurse -Force -EA 0 }
Clean "win-diagtrace" { Remove-Item "C:\Windows\Logs\DiagTrack\*" -Recurse -Force -EA 0 }
Clean "win-pla-logs" { Remove-Item "C:\Windows\System32\LogFiles\PLA\*" -Recurse -Force -EA 0 }

# ============================================================================
# PHASE 3: WINDOWS SYSTEM (60 operations)
# ============================================================================
Write-Host "`n[PHASE 3/20] WINDOWS SYSTEM" -ForegroundColor White
Clean "win-prefetch" { Remove-Item "C:\Windows\Prefetch\*" -Recurse -Force -EA 0 }
Clean "win-softwaredist" {
    net stop wuauserv 2>$null
    Remove-Item "C:\Windows\SoftwareDistribution\Download\*" -Recurse -Force -EA 0
    Remove-Item "C:\Windows\SoftwareDistribution\DataStore\*" -Recurse -Force -EA 0
    net start wuauserv 2>$null
}
Clean "win-softwaredist-logs" { Remove-Item "C:\Windows\SoftwareDistribution\DataStore\Logs\*" -Recurse -Force -EA 0 }
Clean "win-catroot2" { Remove-Item "C:\Windows\System32\catroot2\*" -Recurse -Force -EA 0 }
Clean "win-wer" { Remove-Item "C:\Windows\WER\*" -Recurse -Force -EA 0 }
Clean "win-wer-reportqueue" { Remove-Item "C:\Windows\WER\ReportQueue\*" -Recurse -Force -EA 0 }
Clean "win-wer-reportarchive" { Remove-Item "C:\Windows\WER\ReportArchive\*" -Recurse -Force -EA 0 }
Clean "win-installer-temp" { Remove-Item "C:\Windows\Installer\`$PatchCache`$\*" -Recurse -Force -EA 0 }
Clean "win-installer-msi" { Get-ChildItem "C:\Windows\Installer\*.msi" -EA 0 | Where-Object {$_.Length -gt 5MB} | Remove-Item -Force -EA 0 }
Clean "win-installer-msp" { Get-ChildItem "C:\Windows\Installer\*.msp" -EA 0 | Where-Object {$_.Length -gt 5MB} | Remove-Item -Force -EA 0 }
Clean "win-installer-log" { Remove-Item "C:\Windows\Installer\*.log" -Force -EA 0 }
Clean "win-assembly-temp" { Remove-Item "C:\Windows\assembly\temp\*" -Recurse -Force -EA 0 }
Clean "win-assembly-tmp" { Remove-Item "C:\Windows\assembly\tmp\*" -Recurse -Force -EA 0 }
Clean "win-winsxs-temp" { Remove-Item "C:\Windows\WinSxS\Temp\*" -Recurse -Force -EA 0 }
Clean "win-winsxs-backup" { Remove-Item "C:\Windows\WinSxS\Backup\*" -Recurse -Force -EA 0 }
Clean "win-winsxs-manifest" { Remove-Item "C:\Windows\WinSxS\ManifestCache\*" -Recurse -Force -EA 0 }
Clean "win-winsxs-pending" { Remove-Item "C:\Windows\WinSxS\pending.xml" -Force -EA 0 }
Clean "win-winsxs-cleanup" { Remove-Item "C:\Windows\WinSxS\cleanup.xml" -Force -EA 0 }
Clean "dism-cleanup" { Dism.exe /online /Cleanup-Image /StartComponentCleanup /quiet 2>$null }
Clean "dism-resetbase" { Dism.exe /online /Cleanup-Image /StartComponentCleanup /ResetBase /quiet 2>$null }
Clean "dism-superseded" { Dism.exe /online /Cleanup-Image /SPSuperseded /quiet 2>$null }
Clean "win-bt" { Remove-Item "C:\`$Windows.~BT\*" -Recurse -Force -EA 0 }
Clean "win-ws" { Remove-Item "C:\`$Windows.~WS\*" -Recurse -Force -EA 0 }
Clean "win-old" { Remove-Item "C:\Windows.old\*" -Recurse -Force -EA 0 }
Clean "win-old2" { Remove-Item "C:\Windows.old.000\*" -Recurse -Force -EA 0 }
Clean "win-sfc-pending" { Remove-Item "C:\Windows\winsxs\pending.xml.bak" -Force -EA 0 }
Clean "win-search-data" { Remove-Item "C:\ProgramData\Microsoft\Search\Data\*" -Recurse -Force -EA 0 }
Clean "win-search-apps" { Remove-Item "C:\ProgramData\Microsoft\Search\Data\Applications\Windows\*" -Recurse -Force -EA 0 }
Clean "win-crypto-keys" { Remove-Item "C:\ProgramData\Microsoft\Crypto\RSA\MachineKeys\*.tmp" -Force -EA 0 }
Clean "win-installer-baseline" { Remove-Item "C:\Windows\Installer\SourceHash\*" -Recurse -Force -EA 0 }
Clean "win-printservice" { Remove-Item "C:\Windows\System32\spool\drivers\color\*.tmp" -Force -EA 0 }
Clean "win-defender-scanhistory" {
    Remove-Item "C:\ProgramData\Microsoft\Windows Defender\Scans\History\*" -Recurse -Force -EA 0
}
Clean "win-defender-quarantine" { Remove-Item "C:\ProgramData\Microsoft\Windows Defender\Quarantine\*" -Recurse -Force -EA 0 }
Clean "win-defender-cache" { Remove-Item "C:\ProgramData\Microsoft\Windows Defender\LocalCopy\*" -Recurse -Force -EA 0 }
Clean "win-defender-support" { Remove-Item "C:\ProgramData\Microsoft\Windows Defender\Support\*" -Recurse -Force -EA 0 }
Clean "win-defender-logs" { Remove-Item "C:\ProgramData\Microsoft\Windows Defender\Scans\History\Service\*" -Recurse -Force -EA 0 }
Clean "win-defender-network" { Remove-Item "C:\ProgramData\Microsoft\Windows Defender\Network Inspection System\Support\*" -Recurse -Force -EA 0 }
Clean "win-sxs-installtemp" { Remove-Item "C:\Windows\WinSxS\InstallTemp\*" -Recurse -Force -EA 0 }
Clean "win-sxs-filemaps" { Remove-Item "C:\Windows\WinSxS\FileMaps\*.tmp" -Force -EA 0 }
Clean "win-deliveryopt" {
    net stop dosvc 2>$null
    Remove-Item "C:\Windows\SoftwareDistribution\DeliveryOptimization\*" -Recurse -Force -EA 0
    net start dosvc 2>$null
}
Clean "win-deliveryopt-cache" { Remove-Item "C:\Windows\ServiceProfiles\NetworkService\AppData\Local\Microsoft\Windows\DeliveryOptimization\Cache\*" -Recurse -Force -EA 0 }
Clean "win-deliveryopt-logs" { Remove-Item "C:\Windows\ServiceProfiles\NetworkService\AppData\Local\Microsoft\Windows\DeliveryOptimization\Logs\*" -Recurse -Force -EA 0 }
Clean "win-usmt-temp" { Remove-Item "C:\Windows\USMT\*" -Recurse -Force -EA 0 }
Clean "win-migwiz" { Remove-Item "C:\Windows\migwiz\*" -Recurse -Force -EA 0 }
Clean "win-bthprops" { Remove-Item "C:\Windows\Branding\Basebrd\*.tmp" -Force -EA 0 }
Clean "win-identitycrl" { Remove-Item "C:\Windows\System32\config\systemprofile\AppData\Local\Microsoft\IdentityCRL\*" -Recurse -Force -EA 0 }
Clean "win-cryptnet" { Remove-Item "C:\Windows\System32\config\systemprofile\AppData\LocalLow\Microsoft\CryptnetUrlCache\*" -Recurse -Force -EA 0 }
Clean "win-oobe" { Remove-Item "C:\Windows\System32\oobe\info\backgrounds\*.tmp" -Force -EA 0 }
Clean "win-servicing-sessions" { Remove-Item "C:\Windows\servicing\Sessions\*.xml" -Force -EA 0 }
Clean "win-dot3svc" { Remove-Item "C:\Windows\System32\config\systemprofile\AppData\Local\Microsoft\Dot3Svc\*" -Recurse -Force -EA 0 }
Clean "win-diagnostic-etl" { Remove-Item "C:\Windows\System32\WDI\*.etl" -Force -EA 0 }
Clean "win-dxgi-cache" { Remove-Item "C:\Windows\System32\dxgi.dll.tmp" -Force -EA 0 }
Clean "win-restore-cleanup" { vssadmin delete shadows /for=c: /oldest /quiet 2>$null }
Clean "win-cleanmgr-cache" { Remove-Item "C:\Windows\System32\cleanmgr\*.tmp" -Force -EA 0 }
Clean "win-msdownld" { Remove-Item "C:\Windows\msdownld.tmp\*" -Recurse -Force -EA 0 }
Clean "win-spool-temp" { Remove-Item "C:\Windows\System32\spool\Temp\*" -Recurse -Force -EA 0 }
Clean "win-spool-low" { Remove-Item "C:\Windows\System32\spool\Low\*" -Recurse -Force -EA 0 }
Clean "win-web-cache" { Remove-Item "C:\Windows\System32\config\systemprofile\AppData\Local\Microsoft\Windows\INetCache\*" -Recurse -Force -EA 0 }

# ============================================================================
# PHASE 4: USER TEMP/CACHE (70 operations)
# ============================================================================
Write-Host "`n[PHASE 4/20] USER TEMP/CACHE" -ForegroundColor White
Clean "user-temp" { Remove-Item "C:\Users\*\AppData\Local\Temp\*" -Recurse -Force -EA 0 }
Clean "user-temp-old" { Get-ChildItem "C:\Users\*\AppData\Local\Temp" -Directory -EA 0 | Where-Object {$_.LastWriteTime -lt (Get-Date).AddDays(-7)} | Remove-Item -Recurse -Force -EA 0 }
Clean "user-temp-log" { Remove-Item "C:\Users\*\AppData\Local\Temp\*.log" -Force -EA 0 }
Clean "user-temp-tmp" { Remove-Item "C:\Users\*\AppData\Local\Temp\*.tmp" -Force -EA 0 }
Clean "user-temp-etl" { Remove-Item "C:\Users\*\AppData\Local\Temp\*.etl" -Force -EA 0 }
Clean "user-recent" { Remove-Item "C:\Users\*\AppData\Roaming\Microsoft\Windows\Recent\*" -Recurse -Force -EA 0 }
Clean "user-recentauto" { Remove-Item "C:\Users\*\AppData\Roaming\Microsoft\Windows\Recent\AutomaticDestinations\*" -Recurse -Force -EA 0 }
Clean "user-recentcustom" { Remove-Item "C:\Users\*\AppData\Roaming\Microsoft\Windows\Recent\CustomDestinations\*" -Recurse -Force -EA 0 }
Clean "user-inetcache" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Windows\INetCache\*" -Recurse -Force -EA 0 }
Clean "user-inetcache-low" { Remove-Item "C:\Users\*\AppData\LocalLow\Microsoft\Internet Explorer\*" -Recurse -Force -EA 0 }
Clean "user-webcache" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Windows\WebCache\*" -Recurse -Force -EA 0 }
Clean "user-caches" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Windows\Caches\*" -Recurse -Force -EA 0 }
Clean "user-tempinet" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Windows\Temporary Internet Files\*" -Recurse -Force -EA 0 }
Clean "user-history" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Windows\History\*" -Recurse -Force -EA 0 }
Clean "user-thumbcache" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Windows\Explorer\thumbcache_*" -Force -EA 0 }
Clean "user-iconcache" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Windows\Explorer\iconcache_*" -Force -EA 0 }
Clean "user-iconcachedb" { Remove-Item "C:\Users\*\AppData\Local\IconCache.db" -Force -EA 0 }
Clean "user-wer" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Windows\WER\*" -Recurse -Force -EA 0 }
Clean "user-wer-reportqueue" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Windows\WER\ReportQueue\*" -Recurse -Force -EA 0 }
Clean "user-wer-reportarchive" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Windows\WER\ReportArchive\*" -Recurse -Force -EA 0 }
Clean "user-crashdumps" { Remove-Item "C:\Users\*\AppData\Local\CrashDumps\*" -Recurse -Force -EA 0 }
Clean "user-d3dscache" { Remove-Item "C:\Users\*\AppData\Local\D3DSCache\*" -Recurse -Force -EA 0 }
Clean "user-fontcache" { Remove-Item "C:\Users\*\AppData\Local\FontCache\*" -Recurse -Force -EA 0 }
Clean "user-notifications" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Windows\Notifications\*" -Recurse -Force -EA 0 }
Clean "user-notifications-db" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Windows\Notifications\wpndatabase.db" -Force -EA 0 }
Clean "user-actioncenter" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Windows\ActionCenterCache\*" -Recurse -Force -EA 0 }
Clean "user-connecteddevices" { Remove-Item "C:\Users\*\AppData\Local\ConnectedDevicesPlatform\*" -Recurse -Force -EA 0 }
Clean "user-comms" { Remove-Item "C:\Users\*\AppData\Local\Comms\*" -Recurse -Force -EA 0 }
Clean "user-dbg" { Remove-Item "C:\Users\*\AppData\Local\DBG\*" -Recurse -Force -EA 0 }
Clean "user-tsclient" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Terminal Server Client\Cache\*" -Recurse -Force -EA 0 }
Clean "user-onedrive-logs" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\OneDrive\logs\*" -Recurse -Force -EA 0 }
Clean "user-onedrive-cache" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\OneDrive\cache\*" -Recurse -Force -EA 0 }
Clean "user-onedrive-setup" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\OneDrive\setup\*" -Recurse -Force -EA 0 }
Clean "user-cmdanalysis" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Windows\PowerShell\CommandAnalysis\*" -Recurse -Force -EA 0 }
Clean "user-squirrel" { Remove-Item "C:\Users\*\AppData\Local\SquirrelTemp\*" -Recurse -Force -EA 0 }
Clean "user-cache" { Remove-Item "C:\Users\*\.cache\*" -Recurse -Force -EA 0 }
Clean "user-dxvk-cache" { Remove-Item "C:\Users\*\AppData\Local\DXVK\*" -Recurse -Force -EA 0 }
Clean "user-cleanmgr" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Windows\DiskCleanup\*" -Recurse -Force -EA 0 }
Clean "user-explorer-cache" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Windows\Explorer\*.db" -Force -EA 0 }
Clean "user-webplatform" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Windows\WebPlatformCache\*" -Recurse -Force -EA 0 }
Clean "user-gameexplorer" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Windows\GameExplorer\*" -Recurse -Force -EA 0 }
Clean "user-windowsapps-temp" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\WindowsApps\*\.tmp" -Force -EA 0 }
Clean "user-cryptneturlcache" { Remove-Item "C:\Users\*\AppData\LocalLow\Microsoft\CryptnetUrlCache\*" -Recurse -Force -EA 0 }
Clean "user-iedownload" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Windows\IEDownloadHistory\*" -Recurse -Force -EA 0 }
Clean "user-ietld" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Internet Explorer\Tiles\*" -Recurse -Force -EA 0 }
Clean "user-ierecovery" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Internet Explorer\Recovery\*" -Recurse -Force -EA 0 }
Clean "user-diagdata" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Windows\DiagnosticLogs\*" -Recurse -Force -EA 0 }
Clean "user-appdiag" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Windows\AppDiagnostics\*" -Recurse -Force -EA 0 }
Clean "user-settingsync" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Windows\SettingSync\*" -Recurse -Force -EA 0 }
Clean "user-clipboard" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Windows\Clipboard\*" -Recurse -Force -EA 0 }
Clean "user-tokens" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\TokenBroker\Cache\*" -Recurse -Force -EA 0 }
Clean "user-media" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Media Player\*" -Recurse -Force -EA 0 }
Clean "user-feeds" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Feeds Cache\*" -Recurse -Force -EA 0 }
Clean "user-appdata-temp" { Remove-Item "C:\Users\*\AppData\Local\*.tmp" -Force -EA 0 }
Clean "user-appdata-log" { Remove-Item "C:\Users\*\AppData\Local\*.log" -Force -EA 0 }
Clean "user-appdata-bak" { Remove-Item "C:\Users\*\AppData\Local\*.bak" -Force -EA 0 }
Clean "user-appdata-old" { Remove-Item "C:\Users\*\AppData\Local\*.old" -Force -EA 0 }
Clean "user-winsearch" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Windows\Explorer\search_*.db" -Force -EA 0 }
Clean "user-activitycache" { Remove-Item "C:\Users\*\AppData\Local\ConnectedDevicesPlatform\*\ActivitiesCache.db" -Force -EA 0 }
Clean "user-packages-temp" { Remove-Item "C:\Users\*\AppData\Local\Packages\*\TempState\*" -Recurse -Force -EA 0 }
Clean "user-packages-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "user-lowdata-temp" { Remove-Item "C:\Users\*\AppData\LocalLow\Temp\*" -Recurse -Force -EA 0 }
Clean "user-lowdata-sun" { Remove-Item "C:\Users\*\AppData\LocalLow\Sun\Java\*" -Recurse -Force -EA 0 }
Clean "user-lowdata-oracle" { Remove-Item "C:\Users\*\AppData\LocalLow\Oracle\Java\*" -Recurse -Force -EA 0 }
Clean "user-start-cache" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Windows\Caches\cversions.*.db" -Force -EA 0 }
Clean "user-backgroundtask" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Windows\BackgroundTaskScheduler\*" -Recurse -Force -EA 0 }
Clean "user-webcachelow" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Windows\WebCacheLow\*" -Recurse -Force -EA 0 }
Clean "user-permissionslog" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Windows\PermissionsData\*" -Recurse -Force -EA 0 }
Clean "user-arp-cache" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Windows\AppCache\*" -Recurse -Force -EA 0 }

# ============================================================================
# PHASE 5: BROWSERS - CHROME (40 operations)
# ============================================================================
Write-Host "`n[PHASE 5/20] BROWSERS - CHROME" -ForegroundColor White
Clean "chrome-cache" { Remove-Item "C:\Users\*\AppData\Local\Google\Chrome\User Data\*\Cache\*" -Recurse -Force -EA 0 }
Clean "chrome-cache2" { Remove-Item "C:\Users\*\AppData\Local\Google\Chrome\User Data\*\Cache\Cache_Data\*" -Recurse -Force -EA 0 }
Clean "chrome-codecache" { Remove-Item "C:\Users\*\AppData\Local\Google\Chrome\User Data\*\Code Cache\*" -Recurse -Force -EA 0 }
Clean "chrome-codecache-js" { Remove-Item "C:\Users\*\AppData\Local\Google\Chrome\User Data\*\Code Cache\js\*" -Recurse -Force -EA 0 }
Clean "chrome-codecache-wasm" { Remove-Item "C:\Users\*\AppData\Local\Google\Chrome\User Data\*\Code Cache\wasm\*" -Recurse -Force -EA 0 }
Clean "chrome-gpucache" { Remove-Item "C:\Users\*\AppData\Local\Google\Chrome\User Data\GPUCache\*" -Recurse -Force -EA 0 }
Clean "chrome-gpucache-profile" { Remove-Item "C:\Users\*\AppData\Local\Google\Chrome\User Data\*\GPUCache\*" -Recurse -Force -EA 0 }
Clean "chrome-shadercache" { Remove-Item "C:\Users\*\AppData\Local\Google\Chrome\User Data\ShaderCache\*" -Recurse -Force -EA 0 }
Clean "chrome-shadercache-profile" { Remove-Item "C:\Users\*\AppData\Local\Google\Chrome\User Data\*\ShaderCache\*" -Recurse -Force -EA 0 }
Clean "chrome-serviceworker" { Remove-Item "C:\Users\*\AppData\Local\Google\Chrome\User Data\*\Service Worker\*" -Recurse -Force -EA 0 }
Clean "chrome-serviceworker-cache" { Remove-Item "C:\Users\*\AppData\Local\Google\Chrome\User Data\*\Service Worker\CacheStorage\*" -Recurse -Force -EA 0 }
Clean "chrome-serviceworker-script" { Remove-Item "C:\Users\*\AppData\Local\Google\Chrome\User Data\*\Service Worker\ScriptCache\*" -Recurse -Force -EA 0 }
Clean "chrome-storage" { Remove-Item "C:\Users\*\AppData\Local\Google\Chrome\User Data\*\Storage\*" -Recurse -Force -EA 0 }
Clean "chrome-storage-ext" { Remove-Item "C:\Users\*\AppData\Local\Google\Chrome\User Data\*\Storage\ext\*" -Recurse -Force -EA 0 }
Clean "chrome-indexeddb" { Remove-Item "C:\Users\*\AppData\Local\Google\Chrome\User Data\*\IndexedDB\*" -Recurse -Force -EA 0 }
Clean "chrome-localstorage" { Remove-Item "C:\Users\*\AppData\Local\Google\Chrome\User Data\*\Local Storage\*" -Recurse -Force -EA 0 }
Clean "chrome-sessionstorage" { Remove-Item "C:\Users\*\AppData\Local\Google\Chrome\User Data\*\Session Storage\*" -Recurse -Force -EA 0 }
Clean "chrome-websql" { Remove-Item "C:\Users\*\AppData\Local\Google\Chrome\User Data\*\databases\*" -Recurse -Force -EA 0 }
Clean "chrome-crashpad" { Remove-Item "C:\Users\*\AppData\Local\Google\Chrome\User Data\Crashpad\*" -Recurse -Force -EA 0 }
Clean "chrome-crashpad-reports" { Remove-Item "C:\Users\*\AppData\Local\Google\Chrome\User Data\Crashpad\reports\*" -Recurse -Force -EA 0 }
Clean "chrome-safetycheck" { Remove-Item "C:\Users\*\AppData\Local\Google\Chrome\User Data\SafetyTips\*" -Recurse -Force -EA 0 }
Clean "chrome-optimization" { Remove-Item "C:\Users\*\AppData\Local\Google\Chrome\User Data\OptimizationGuidePredictionModels\*" -Recurse -Force -EA 0 }
Clean "chrome-mediahistory" { Remove-Item "C:\Users\*\AppData\Local\Google\Chrome\User Data\*\Media History" -Force -EA 0 }
Clean "chrome-mediahistory-j" { Remove-Item "C:\Users\*\AppData\Local\Google\Chrome\User Data\*\Media History-journal" -Force -EA 0 }
Clean "chrome-networkerror" { Remove-Item "C:\Users\*\AppData\Local\Google\Chrome\User Data\*\Network\*" -Recurse -Force -EA 0 }
Clean "chrome-blob" { Remove-Item "C:\Users\*\AppData\Local\Google\Chrome\User Data\*\blob_storage\*" -Recurse -Force -EA 0 }
Clean "chrome-filecache" { Remove-Item "C:\Users\*\AppData\Local\Google\Chrome\User Data\*\File System\*" -Recurse -Force -EA 0 }
Clean "chrome-jumplist" { Remove-Item "C:\Users\*\AppData\Local\Google\Chrome\User Data\*\JumpListIconsOld\*" -Recurse -Force -EA 0 }
Clean "chrome-jumplist2" { Remove-Item "C:\Users\*\AppData\Local\Google\Chrome\User Data\*\JumpListIcons\*" -Recurse -Force -EA 0 }
Clean "chrome-component" { Remove-Item "C:\Users\*\AppData\Local\Google\Chrome\User Data\*\component_crx_cache\*" -Recurse -Force -EA 0 }
Clean "chrome-pnacl" { Remove-Item "C:\Users\*\AppData\Local\Google\Chrome\User Data\PnaclTranslationCache\*" -Recurse -Force -EA 0 }
Clean "chrome-crash" { Remove-Item "C:\Users\*\AppData\Local\Google\CrashReports\*" -Recurse -Force -EA 0 }
Clean "chrome-updatelog" { Remove-Item "C:\Users\*\AppData\Local\Google\Update\Log\*" -Recurse -Force -EA 0 }
Clean "chrome-swreporter" { Remove-Item "C:\Users\*\AppData\Local\Google\Software Reporter Tool\*" -Recurse -Force -EA 0 }
Clean "chrome-gcm" { Remove-Item "C:\Users\*\AppData\Local\Google\Chrome\User Data\*\GCM Store\*" -Recurse -Force -EA 0 }
Clean "chrome-platformnotif" { Remove-Item "C:\Users\*\AppData\Local\Google\Chrome\User Data\*\Platform Notifications\*" -Recurse -Force -EA 0 }
Clean "chrome-downloadmeta" { Remove-Item "C:\Users\*\AppData\Local\Google\Chrome\User Data\*\Download Metadata" -Force -EA 0 }
Clean "chrome-syncdata" { Remove-Item "C:\Users\*\AppData\Local\Google\Chrome\User Data\*\Sync Data\*" -Recurse -Force -EA 0 }
Clean "chrome-visitedsites" { Remove-Item "C:\Users\*\AppData\Local\Google\Chrome\User Data\*\Visited Links" -Force -EA 0 }
Clean "chrome-webrtclogs" { Remove-Item "C:\Users\*\AppData\Local\Google\Chrome\User Data\*\webrtc_event_logs\*" -Recurse -Force -EA 0 }

# ============================================================================
# PHASE 6: BROWSERS - EDGE (40 operations)
# ============================================================================
Write-Host "`n[PHASE 6/20] BROWSERS - EDGE" -ForegroundColor White
Clean "edge-cache" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Edge\User Data\*\Cache\*" -Recurse -Force -EA 0 }
Clean "edge-cache2" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Edge\User Data\*\Cache\Cache_Data\*" -Recurse -Force -EA 0 }
Clean "edge-codecache" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Edge\User Data\*\Code Cache\*" -Recurse -Force -EA 0 }
Clean "edge-codecache-js" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Edge\User Data\*\Code Cache\js\*" -Recurse -Force -EA 0 }
Clean "edge-codecache-wasm" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Edge\User Data\*\Code Cache\wasm\*" -Recurse -Force -EA 0 }
Clean "edge-gpucache" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Edge\User Data\GPUCache\*" -Recurse -Force -EA 0 }
Clean "edge-gpucache-profile" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Edge\User Data\*\GPUCache\*" -Recurse -Force -EA 0 }
Clean "edge-shadercache" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Edge\User Data\ShaderCache\*" -Recurse -Force -EA 0 }
Clean "edge-serviceworker" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Edge\User Data\*\Service Worker\*" -Recurse -Force -EA 0 }
Clean "edge-serviceworker-cache" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Edge\User Data\*\Service Worker\CacheStorage\*" -Recurse -Force -EA 0 }
Clean "edge-storage" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Edge\User Data\*\Storage\*" -Recurse -Force -EA 0 }
Clean "edge-indexeddb" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Edge\User Data\*\IndexedDB\*" -Recurse -Force -EA 0 }
Clean "edge-localstorage" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Edge\User Data\*\Local Storage\*" -Recurse -Force -EA 0 }
Clean "edge-sessionstorage" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Edge\User Data\*\Session Storage\*" -Recurse -Force -EA 0 }
Clean "edge-websql" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Edge\User Data\*\databases\*" -Recurse -Force -EA 0 }
Clean "edge-crashpad" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Edge\User Data\Crashpad\*" -Recurse -Force -EA 0 }
Clean "edge-provenance" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Edge\User Data\ProvenanceData\*" -Recurse -Force -EA 0 }
Clean "edge-blob" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Edge\User Data\*\blob_storage\*" -Recurse -Force -EA 0 }
Clean "edge-filecache" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Edge\User Data\*\File System\*" -Recurse -Force -EA 0 }
Clean "edge-gcm" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Edge\User Data\*\GCM Store\*" -Recurse -Force -EA 0 }
Clean "edge-syncdata" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Edge\User Data\*\Sync Data\*" -Recurse -Force -EA 0 }
Clean "edge-visitedsites" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Edge\User Data\*\Visited Links" -Force -EA 0 }
Clean "edge-mediahistory" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Edge\User Data\*\Media History" -Force -EA 0 }
Clean "edge-topicsdb" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Edge\User Data\*\Topics\*" -Recurse -Force -EA 0 }
Clean "edge-collections" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Edge\User Data\*\Collections\*" -Recurse -Force -EA 0 }
Clean "edge-network" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Edge\User Data\*\Network\*" -Recurse -Force -EA 0 }
Clean "edge-component" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Edge\User Data\*\component_crx_cache\*" -Recurse -Force -EA 0 }
Clean "edge-crashreports" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Edge\User Data\CrashReports\*" -Recurse -Force -EA 0 }
Clean "edge-sxs-cache" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Edge SxS\User Data\*\Cache\*" -Recurse -Force -EA 0 }
Clean "edge-beta-cache" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Edge Beta\User Data\*\Cache\*" -Recurse -Force -EA 0 }
Clean "edge-dev-cache" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Edge Dev\User Data\*\Cache\*" -Recurse -Force -EA 0 }
Clean "edge-canary-cache" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Edge Canary\User Data\*\Cache\*" -Recurse -Force -EA 0 }
Clean "edge-sitelist" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Edge\User Data\*\EdgeSiteSafetyTipsComponentData\*" -Recurse -Force -EA 0 }
Clean "edge-sidebardata" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Edge\User Data\*\SidebarData\*" -Recurse -Force -EA 0 }
Clean "edge-webapps" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Edge\User Data\*\Web Applications\*" -Recurse -Force -EA 0 }
Clean "edge-platformnotif" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Edge\User Data\*\Platform Notifications\*" -Recurse -Force -EA 0 }
Clean "edge-webrtclogs" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Edge\User Data\*\webrtc_event_logs\*" -Recurse -Force -EA 0 }
Clean "edge-readlater" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Edge\User Data\*\Read Later\*" -Recurse -Force -EA 0 }
Clean "edge-autofillstrikes" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Edge\User Data\*\AutofillStrikeDatabase\*" -Recurse -Force -EA 0 }
Clean "edge-optimization" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Edge\User Data\OptimizationGuidePredictionModels\*" -Recurse -Force -EA 0 }

# ============================================================================
# PHASE 7: BROWSERS - FIREFOX (35 operations)
# ============================================================================
Write-Host "`n[PHASE 7/20] BROWSERS - FIREFOX" -ForegroundColor White
Clean "firefox-cache" { Remove-Item "C:\Users\*\AppData\Local\Mozilla\Firefox\Profiles\*\cache2\*" -Recurse -Force -EA 0 }
Clean "firefox-cache-entries" { Remove-Item "C:\Users\*\AppData\Local\Mozilla\Firefox\Profiles\*\cache2\entries\*" -Recurse -Force -EA 0 }
Clean "firefox-shader" { Remove-Item "C:\Users\*\AppData\Local\Mozilla\Firefox\Profiles\*\shader-cache\*" -Recurse -Force -EA 0 }
Clean "firefox-startupCache" { Remove-Item "C:\Users\*\AppData\Local\Mozilla\Firefox\Profiles\*\startupCache\*" -Recurse -Force -EA 0 }
Clean "firefox-thumbnails" { Remove-Item "C:\Users\*\AppData\Local\Mozilla\Firefox\Profiles\*\thumbnails\*" -Recurse -Force -EA 0 }
Clean "firefox-storage" { Remove-Item "C:\Users\*\AppData\Local\Mozilla\Firefox\Profiles\*\storage\*" -Recurse -Force -EA 0 }
Clean "firefox-storage-default" { Remove-Item "C:\Users\*\AppData\Local\Mozilla\Firefox\Profiles\*\storage\default\*" -Recurse -Force -EA 0 }
Clean "firefox-indexeddb" { Remove-Item "C:\Users\*\AppData\Roaming\Mozilla\Firefox\Profiles\*\storage\default\*\idb\*" -Recurse -Force -EA 0 }
Clean "firefox-offlinecache" { Remove-Item "C:\Users\*\AppData\Local\Mozilla\Firefox\Profiles\*\OfflineCache\*" -Recurse -Force -EA 0 }
Clean "firefox-safebrowsing" { Remove-Item "C:\Users\*\AppData\Roaming\Mozilla\Firefox\Profiles\*\safebrowsing\*" -Recurse -Force -EA 0 }
Clean "firefox-datareporting" { Remove-Item "C:\Users\*\AppData\Roaming\Mozilla\Firefox\Profiles\*\datareporting\*" -Recurse -Force -EA 0 }
Clean "firefox-crashes" { Remove-Item "C:\Users\*\AppData\Roaming\Mozilla\Firefox\Crash Reports\*" -Recurse -Force -EA 0 }
Clean "firefox-minidumps" { Remove-Item "C:\Users\*\AppData\Roaming\Mozilla\Firefox\Pending Pings\*" -Recurse -Force -EA 0 }
Clean "firefox-sessionstore" { Remove-Item "C:\Users\*\AppData\Roaming\Mozilla\Firefox\Profiles\*\sessionstore-backups\*" -Recurse -Force -EA 0 }
Clean "firefox-webapps" { Remove-Item "C:\Users\*\AppData\Roaming\Mozilla\Firefox\Profiles\*\webappsstore.sqlite" -Force -EA 0 }
Clean "firefox-localstorage" { Remove-Item "C:\Users\*\AppData\Roaming\Mozilla\Firefox\Profiles\*\storage\ls\*" -Recurse -Force -EA 0 }
Clean "firefox-serviceworkers" { Remove-Item "C:\Users\*\AppData\Roaming\Mozilla\Firefox\Profiles\*\storage\default\*\cache\*" -Recurse -Force -EA 0 }
Clean "firefox-jumplist" { Remove-Item "C:\Users\*\AppData\Local\Mozilla\Firefox\Profiles\*\jumpListCache\*" -Recurse -Force -EA 0 }
Clean "firefox-crashbackup" { Remove-Item "C:\Users\*\AppData\Roaming\Mozilla\Firefox\Profiles\*\crashes\*" -Recurse -Force -EA 0 }
Clean "firefox-addondata" { Remove-Item "C:\Users\*\AppData\Roaming\Mozilla\Firefox\Profiles\*\addonStartup.json.lz4" -Force -EA 0 }
Clean "firefox-favicons" { Remove-Item "C:\Users\*\AppData\Roaming\Mozilla\Firefox\Profiles\*\favicons.sqlite" -Force -EA 0 }
Clean "firefox-certs" { Remove-Item "C:\Users\*\AppData\Roaming\Mozilla\Firefox\Profiles\*\cert_override.txt" -Force -EA 0 }
Clean "firefox-gmp" { Remove-Item "C:\Users\*\AppData\Local\Mozilla\Firefox\Profiles\*\gmp-*\*" -Recurse -Force -EA 0 }
Clean "firefox-temp" { Remove-Item "C:\Users\*\AppData\Local\Mozilla\Firefox\Profiles\*\*.tmp" -Force -EA 0 }
Clean "firefox-cache-old" { Remove-Item "C:\Users\*\AppData\Local\Mozilla\Firefox\Profiles\*\Cache\*" -Recurse -Force -EA 0 }
Clean "firefox-secmoddb" { Remove-Item "C:\Users\*\AppData\Roaming\Mozilla\Firefox\Profiles\*\secmod.db" -Force -EA 0 }
Clean "firefox-webappstore" { Remove-Item "C:\Users\*\AppData\Roaming\Mozilla\Firefox\Profiles\*\webappsstore.sqlite-shm" -Force -EA 0 }
Clean "firefox-webappstore-wal" { Remove-Item "C:\Users\*\AppData\Roaming\Mozilla\Firefox\Profiles\*\webappsstore.sqlite-wal" -Force -EA 0 }
Clean "firefox-sharedarray" { Remove-Item "C:\Users\*\AppData\Local\Mozilla\Firefox\Profiles\*\SharedArrayBuffer\*" -Recurse -Force -EA 0 }
Clean "firefox-webcontent" { Remove-Item "C:\Users\*\AppData\Local\Mozilla\Firefox\Profiles\*\webcontent\*" -Recurse -Force -EA 0 }
Clean "firefox-updatelog" { Remove-Item "C:\Users\*\AppData\Local\Mozilla\updates\*\*.log" -Force -EA 0 }
Clean "firefox-background" { Remove-Item "C:\Users\*\AppData\Local\Mozilla\Firefox\Profiles\*\saved-telemetry-pings\*" -Recurse -Force -EA 0 }
Clean "firefox-clearkey" { Remove-Item "C:\Users\*\AppData\Local\Mozilla\Firefox\Profiles\*\clearkey\*" -Recurse -Force -EA 0 }
Clean "firefox-features" { Remove-Item "C:\Users\*\AppData\Roaming\Mozilla\Firefox\Profiles\*\features\*" -Recurse -Force -EA 0 }
Clean "firefox-downloads-tmp" { Remove-Item "C:\Users\*\AppData\Local\Mozilla\Firefox\Profiles\*\*.download" -Force -EA 0 }

# ============================================================================
# PHASE 8: BROWSERS - BRAVE, OPERA, VIVALDI, ARC (50 operations)
# ============================================================================
Write-Host "`n[PHASE 8/20] BROWSERS - BRAVE, OPERA, VIVALDI, ARC" -ForegroundColor White
# Brave
Clean "brave-cache" { Remove-Item "C:\Users\*\AppData\Local\BraveSoftware\Brave-Browser\User Data\*\Cache\*" -Recurse -Force -EA 0 }
Clean "brave-codecache" { Remove-Item "C:\Users\*\AppData\Local\BraveSoftware\Brave-Browser\User Data\*\Code Cache\*" -Recurse -Force -EA 0 }
Clean "brave-gpucache" { Remove-Item "C:\Users\*\AppData\Local\BraveSoftware\Brave-Browser\User Data\GPUCache\*" -Recurse -Force -EA 0 }
Clean "brave-shadercache" { Remove-Item "C:\Users\*\AppData\Local\BraveSoftware\Brave-Browser\User Data\ShaderCache\*" -Recurse -Force -EA 0 }
Clean "brave-serviceworker" { Remove-Item "C:\Users\*\AppData\Local\BraveSoftware\Brave-Browser\User Data\*\Service Worker\*" -Recurse -Force -EA 0 }
Clean "brave-storage" { Remove-Item "C:\Users\*\AppData\Local\BraveSoftware\Brave-Browser\User Data\*\Storage\*" -Recurse -Force -EA 0 }
Clean "brave-indexeddb" { Remove-Item "C:\Users\*\AppData\Local\BraveSoftware\Brave-Browser\User Data\*\IndexedDB\*" -Recurse -Force -EA 0 }
Clean "brave-localstorage" { Remove-Item "C:\Users\*\AppData\Local\BraveSoftware\Brave-Browser\User Data\*\Local Storage\*" -Recurse -Force -EA 0 }
Clean "brave-sessionstorage" { Remove-Item "C:\Users\*\AppData\Local\BraveSoftware\Brave-Browser\User Data\*\Session Storage\*" -Recurse -Force -EA 0 }
Clean "brave-crashpad" { Remove-Item "C:\Users\*\AppData\Local\BraveSoftware\Brave-Browser\User Data\Crashpad\*" -Recurse -Force -EA 0 }
Clean "brave-blob" { Remove-Item "C:\Users\*\AppData\Local\BraveSoftware\Brave-Browser\User Data\*\blob_storage\*" -Recurse -Force -EA 0 }
Clean "brave-network" { Remove-Item "C:\Users\*\AppData\Local\BraveSoftware\Brave-Browser\User Data\*\Network\*" -Recurse -Force -EA 0 }
# Opera
Clean "opera-cache" { Remove-Item "C:\Users\*\AppData\Local\Opera Software\Opera Stable\Cache\*" -Recurse -Force -EA 0 }
Clean "opera-codecache" { Remove-Item "C:\Users\*\AppData\Local\Opera Software\Opera Stable\Code Cache\*" -Recurse -Force -EA 0 }
Clean "opera-gpucache" { Remove-Item "C:\Users\*\AppData\Local\Opera Software\Opera Stable\GPUCache\*" -Recurse -Force -EA 0 }
Clean "opera-shadercache" { Remove-Item "C:\Users\*\AppData\Local\Opera Software\Opera Stable\ShaderCache\*" -Recurse -Force -EA 0 }
Clean "opera-serviceworker" { Remove-Item "C:\Users\*\AppData\Local\Opera Software\Opera Stable\Service Worker\*" -Recurse -Force -EA 0 }
Clean "opera-storage" { Remove-Item "C:\Users\*\AppData\Local\Opera Software\Opera Stable\Storage\*" -Recurse -Force -EA 0 }
Clean "opera-indexeddb" { Remove-Item "C:\Users\*\AppData\Local\Opera Software\Opera Stable\IndexedDB\*" -Recurse -Force -EA 0 }
Clean "opera-localstorage" { Remove-Item "C:\Users\*\AppData\Local\Opera Software\Opera Stable\Local Storage\*" -Recurse -Force -EA 0 }
Clean "opera-sessionstorage" { Remove-Item "C:\Users\*\AppData\Local\Opera Software\Opera Stable\Session Storage\*" -Recurse -Force -EA 0 }
Clean "opera-crashpad" { Remove-Item "C:\Users\*\AppData\Local\Opera Software\Opera Stable\Crashpad\*" -Recurse -Force -EA 0 }
Clean "opera-blob" { Remove-Item "C:\Users\*\AppData\Local\Opera Software\Opera Stable\blob_storage\*" -Recurse -Force -EA 0 }
Clean "opera-gx-cache" { Remove-Item "C:\Users\*\AppData\Local\Opera Software\Opera GX Stable\Cache\*" -Recurse -Force -EA 0 }
Clean "opera-gx-codecache" { Remove-Item "C:\Users\*\AppData\Local\Opera Software\Opera GX Stable\Code Cache\*" -Recurse -Force -EA 0 }
# Vivaldi
Clean "vivaldi-cache" { Remove-Item "C:\Users\*\AppData\Local\Vivaldi\User Data\*\Cache\*" -Recurse -Force -EA 0 }
Clean "vivaldi-codecache" { Remove-Item "C:\Users\*\AppData\Local\Vivaldi\User Data\*\Code Cache\*" -Recurse -Force -EA 0 }
Clean "vivaldi-gpucache" { Remove-Item "C:\Users\*\AppData\Local\Vivaldi\User Data\GPUCache\*" -Recurse -Force -EA 0 }
Clean "vivaldi-shadercache" { Remove-Item "C:\Users\*\AppData\Local\Vivaldi\User Data\ShaderCache\*" -Recurse -Force -EA 0 }
Clean "vivaldi-serviceworker" { Remove-Item "C:\Users\*\AppData\Local\Vivaldi\User Data\*\Service Worker\*" -Recurse -Force -EA 0 }
Clean "vivaldi-storage" { Remove-Item "C:\Users\*\AppData\Local\Vivaldi\User Data\*\Storage\*" -Recurse -Force -EA 0 }
Clean "vivaldi-indexeddb" { Remove-Item "C:\Users\*\AppData\Local\Vivaldi\User Data\*\IndexedDB\*" -Recurse -Force -EA 0 }
Clean "vivaldi-localstorage" { Remove-Item "C:\Users\*\AppData\Local\Vivaldi\User Data\*\Local Storage\*" -Recurse -Force -EA 0 }
Clean "vivaldi-sessionstorage" { Remove-Item "C:\Users\*\AppData\Local\Vivaldi\User Data\*\Session Storage\*" -Recurse -Force -EA 0 }
Clean "vivaldi-crashpad" { Remove-Item "C:\Users\*\AppData\Local\Vivaldi\User Data\Crashpad\*" -Recurse -Force -EA 0 }
Clean "vivaldi-blob" { Remove-Item "C:\Users\*\AppData\Local\Vivaldi\User Data\*\blob_storage\*" -Recurse -Force -EA 0 }
# Arc
Clean "arc-cache" { Remove-Item "C:\Users\*\AppData\Local\Arc\User Data\*\Cache\*" -Recurse -Force -EA 0 }
Clean "arc-codecache" { Remove-Item "C:\Users\*\AppData\Local\Arc\User Data\*\Code Cache\*" -Recurse -Force -EA 0 }
Clean "arc-gpucache" { Remove-Item "C:\Users\*\AppData\Local\Arc\User Data\GPUCache\*" -Recurse -Force -EA 0 }
Clean "arc-serviceworker" { Remove-Item "C:\Users\*\AppData\Local\Arc\User Data\*\Service Worker\*" -Recurse -Force -EA 0 }
Clean "arc-storage" { Remove-Item "C:\Users\*\AppData\Local\Arc\User Data\*\Storage\*" -Recurse -Force -EA 0 }
Clean "arc-indexeddb" { Remove-Item "C:\Users\*\AppData\Local\Arc\User Data\*\IndexedDB\*" -Recurse -Force -EA 0 }
Clean "arc-localstorage" { Remove-Item "C:\Users\*\AppData\Local\Arc\User Data\*\Local Storage\*" -Recurse -Force -EA 0 }
Clean "arc-crashpad" { Remove-Item "C:\Users\*\AppData\Local\Arc\User Data\Crashpad\*" -Recurse -Force -EA 0 }
# Chromium generic
Clean "chromium-cache" { Remove-Item "C:\Users\*\AppData\Local\Chromium\User Data\*\Cache\*" -Recurse -Force -EA 0 }
Clean "chromium-codecache" { Remove-Item "C:\Users\*\AppData\Local\Chromium\User Data\*\Code Cache\*" -Recurse -Force -EA 0 }
Clean "chromium-gpucache" { Remove-Item "C:\Users\*\AppData\Local\Chromium\User Data\GPUCache\*" -Recurse -Force -EA 0 }
Clean "chromium-serviceworker" { Remove-Item "C:\Users\*\AppData\Local\Chromium\User Data\*\Service Worker\*" -Recurse -Force -EA 0 }
Clean "chromium-storage" { Remove-Item "C:\Users\*\AppData\Local\Chromium\User Data\*\Storage\*" -Recurse -Force -EA 0 }

# ============================================================================
# PHASE 9: DEV - NODE.JS ECOSYSTEM (50 operations)
# ============================================================================
Write-Host "`n[PHASE 9/20] DEV - NODE.JS ECOSYSTEM" -ForegroundColor White
Clean "npm-cache" { Remove-Item "C:\Users\*\AppData\Local\npm-cache\*" -Recurse -Force -EA 0 }
Clean "npm-cache2" { Remove-Item "C:\Users\*\AppData\Roaming\npm-cache\*" -Recurse -Force -EA 0 }
Clean "npm-logs" { Remove-Item "C:\Users\*\.npm\_logs\*" -Recurse -Force -EA 0 }
Clean "npm-cacache" { Remove-Item "C:\Users\*\.npm\_cacache\*" -Recurse -Force -EA 0 }
Clean "npm-tmp" { Remove-Item "C:\Users\*\.npm\tmp\*" -Recurse -Force -EA 0 }
Clean "npm-staging" { Remove-Item "C:\Users\*\.npm\_staging\*" -Recurse -Force -EA 0 }
Clean "npm-locks" { Remove-Item "C:\Users\*\.npm\_locks\*" -Recurse -Force -EA 0 }
Clean "npm-update" { Remove-Item "C:\Users\*\.npm\_update-notifier-last-checked" -Force -EA 0 }
Clean "yarn-cache" { Remove-Item "C:\Users\*\AppData\Local\Yarn\Cache\*" -Recurse -Force -EA 0 }
Clean "yarn-cache2" { Remove-Item "C:\Users\*\.yarn\cache\*" -Recurse -Force -EA 0 }
Clean "yarn-logs" { Remove-Item "C:\Users\*\.yarn\*.log" -Force -EA 0 }
Clean "yarn-berry-cache" { Remove-Item "C:\Users\*\.yarn\berry\cache\*" -Recurse -Force -EA 0 }
Clean "yarn-global" { Remove-Item "C:\Users\*\.yarn\global\*" -Recurse -Force -EA 0 }
Clean "yarn-tmp" { Remove-Item "C:\Users\*\.yarn\tmp\*" -Recurse -Force -EA 0 }
Clean "yarn-install-state" { Remove-Item "C:\Users\*\.yarn\install-state.gz" -Force -EA 0 }
Clean "pnpm-cache" { Remove-Item "C:\Users\*\AppData\Local\pnpm\cache\*" -Recurse -Force -EA 0 }
Clean "pnpm-cache2" { Remove-Item "C:\Users\*\AppData\Local\pnpm-cache\*" -Recurse -Force -EA 0 }
Clean "pnpm-store" { Remove-Item "C:\Users\*\AppData\Local\pnpm-store\*" -Recurse -Force -EA 0 }
Clean "pnpm-store-v3" { Remove-Item "C:\Users\*\AppData\Local\pnpm\store\*" -Recurse -Force -EA 0 }
Clean "pnpm-state" { Remove-Item "C:\Users\*\AppData\Local\pnpm\pnpm-state.json" -Force -EA 0 }
Clean "pnpm-global" { Remove-Item "C:\Users\*\.pnpm-store\*" -Recurse -Force -EA 0 }
Clean "bun-cache" { Remove-Item "C:\Users\*\.bun\install\cache\*" -Recurse -Force -EA 0 }
Clean "bun-tmp" { Remove-Item "C:\Users\*\.bun\tmp\*" -Recurse -Force -EA 0 }
Clean "bun-global-cache" { Remove-Item "C:\Users\*\.bun\install\global\cache\*" -Recurse -Force -EA 0 }
Clean "node-gyp" { Remove-Item "C:\Users\*\AppData\Local\node-gyp\*" -Recurse -Force -EA 0 }
Clean "node-gyp-cache" { Remove-Item "C:\Users\*\.node-gyp\*" -Recurse -Force -EA 0 }
Clean "node-repl" { Remove-Item "C:\Users\*\.node_repl_history" -Force -EA 0 }
Clean "deno-cache" { Remove-Item "C:\Users\*\AppData\Local\deno\deps\*" -Recurse -Force -EA 0 }
Clean "deno-gen" { Remove-Item "C:\Users\*\AppData\Local\deno\gen\*" -Recurse -Force -EA 0 }
Clean "deno-npm" { Remove-Item "C:\Users\*\AppData\Local\deno\npm\*" -Recurse -Force -EA 0 }
Clean "deno-registry" { Remove-Item "C:\Users\*\AppData\Local\deno\registries\*" -Recurse -Force -EA 0 }
Clean "deno-location" { Remove-Item "C:\Users\*\AppData\Local\deno\location_data\*" -Recurse -Force -EA 0 }
Clean "deno-origin" { Remove-Item "C:\Users\*\AppData\Local\deno\origin_data\*" -Recurse -Force -EA 0 }
Clean "deno-tmp" { Remove-Item "C:\Users\*\AppData\Local\deno\tmp\*" -Recurse -Force -EA 0 }
Clean "volta-cache" { Remove-Item "C:\Users\*\.volta\cache\*" -Recurse -Force -EA 0 }
Clean "volta-tmp" { Remove-Item "C:\Users\*\.volta\tmp\*" -Recurse -Force -EA 0 }
Clean "volta-log" { Remove-Item "C:\Users\*\.volta\log\*" -Recurse -Force -EA 0 }
Clean "fnm-cache" { Remove-Item "C:\Users\*\.fnm\node-versions\*\.cache\*" -Recurse -Force -EA 0 }
Clean "nvm-tmp" { Remove-Item "C:\Users\*\.nvm\tmp\*" -Recurse -Force -EA 0 }
Clean "n-cache" { Remove-Item "C:\Users\*\.n\cache\*" -Recurse -Force -EA 0 }
Clean "electron-cache" { Remove-Item "C:\Users\*\AppData\Local\electron\Cache\*" -Recurse -Force -EA 0 }
Clean "electron-builder" { Remove-Item "C:\Users\*\AppData\Local\electron-builder\cache\*" -Recurse -Force -EA 0 }
Clean "cypress-cache" { Remove-Item "C:\Users\*\AppData\Local\Cypress\Cache\*" -Recurse -Force -EA 0 }
Clean "playwright-cache" { Remove-Item "C:\Users\*\AppData\Local\ms-playwright\*" -Recurse -Force -EA 0 }
Clean "puppeteer-cache" { Remove-Item "C:\Users\*\.cache\puppeteer\*" -Recurse -Force -EA 0 }
Clean "typescript-cache" { Remove-Item "C:\Users\*\.cache\typescript\*" -Recurse -Force -EA 0 }
Clean "parcel-cache" { Remove-Item "C:\Users\*\.parcel-cache\*" -Recurse -Force -EA 0 }
Clean "turbo-cache" { Remove-Item "C:\Users\*\.turbo\*" -Recurse -Force -EA 0 }
Clean "nx-cache" { Remove-Item "C:\Users\*\.nx\cache\*" -Recurse -Force -EA 0 }
Clean "next-cache" { Remove-Item "C:\Users\*\.next\cache\*" -Recurse -Force -EA 0 }

# ============================================================================
# PHASE 10: DEV - PYTHON ECOSYSTEM (40 operations)
# ============================================================================
Write-Host "`n[PHASE 10/20] DEV - PYTHON ECOSYSTEM" -ForegroundColor White
Clean "pip-cache" { Remove-Item "C:\Users\*\AppData\Local\pip\cache\*" -Recurse -Force -EA 0 }
Clean "pip-httpCache" { Remove-Item "C:\Users\*\AppData\Local\pip\http\*" -Recurse -Force -EA 0 }
Clean "pip-wheels" { Remove-Item "C:\Users\*\AppData\Local\pip\wheels\*" -Recurse -Force -EA 0 }
Clean "pip-selfcheck" { Remove-Item "C:\Users\*\AppData\Local\pip\selfcheck.json" -Force -EA 0 }
Clean "pip-log" { Remove-Item "C:\Users\*\.pip\pip.log" -Force -EA 0 }
Clean "uv-cache" { Remove-Item "C:\Users\*\AppData\Local\uv\cache\*" -Recurse -Force -EA 0 }
Clean "uv-tools" { Remove-Item "C:\Users\*\AppData\Local\uv\tools\*" -Recurse -Force -EA 0 }
Clean "uv-python" { Remove-Item "C:\Users\*\AppData\Local\uv\python\*" -Recurse -Force -EA 0 }
Clean "pipx-cache" { Remove-Item "C:\Users\*\.local\pipx\.cache\*" -Recurse -Force -EA 0 }
Clean "pipx-logs" { Remove-Item "C:\Users\*\.local\pipx\logs\*" -Recurse -Force -EA 0 }
Clean "poetry-cache" { Remove-Item "C:\Users\*\AppData\Local\pypoetry\Cache\*" -Recurse -Force -EA 0 }
Clean "poetry-cache2" { Remove-Item "C:\Users\*\.cache\pypoetry\cache\*" -Recurse -Force -EA 0 }
Clean "poetry-artifacts" { Remove-Item "C:\Users\*\.cache\pypoetry\artifacts\*" -Recurse -Force -EA 0 }
Clean "conda-pkgs" { Remove-Item "C:\Users\*\.conda\pkgs\*" -Recurse -Force -EA 0 }
Clean "conda-cache" { Remove-Item "C:\Users\*\.conda\pkgs\cache\*" -Recurse -Force -EA 0 }
Clean "conda-notices" { Remove-Item "C:\Users\*\.conda\notices\*" -Recurse -Force -EA 0 }
Clean "conda-envs-cache" { Remove-Item "C:\Users\*\.conda\envs\*\.cache\*" -Recurse -Force -EA 0 }
Clean "miniconda-pkgs" { Remove-Item "C:\Users\*\miniconda3\pkgs\*" -Recurse -Force -EA 0 }
Clean "anaconda-pkgs" { Remove-Item "C:\Users\*\anaconda3\pkgs\*" -Recurse -Force -EA 0 }
Clean "mamba-pkgs" { Remove-Item "C:\Users\*\mambaforge\pkgs\*" -Recurse -Force -EA 0 }
Clean "virtualenv-cache" { Remove-Item "C:\Users\*\.local\share\virtualenv\*" -Recurse -Force -EA 0 }
Clean "virtualenv-wheel" { Remove-Item "C:\Users\*\AppData\Local\virtualenv\*" -Recurse -Force -EA 0 }
Clean "pyenv-cache" { Remove-Item "C:\Users\*\.pyenv\cache\*" -Recurse -Force -EA 0 }
Clean "pyenv-shims" { Remove-Item "C:\Users\*\.pyenv\shims\*.pyc" -Force -EA 0 }
Clean "ruff-cache" { Remove-Item "C:\Users\*\.cache\ruff\*" -Recurse -Force -EA 0 }
Clean "mypy-cache" { Remove-Item "C:\Users\*\.mypy_cache\*" -Recurse -Force -EA 0 }
Clean "pytest-cache" { Remove-Item "C:\Users\*\.pytest_cache\*" -Recurse -Force -EA 0 }
Clean "pylint-cache" { Remove-Item "C:\Users\*\.cache\pylint\*" -Recurse -Force -EA 0 }
Clean "black-cache" { Remove-Item "C:\Users\*\.cache\black\*" -Recurse -Force -EA 0 }
Clean "flake8-cache" { Remove-Item "C:\Users\*\.cache\flake8\*" -Recurse -Force -EA 0 }
Clean "pre-commit-cache" { Remove-Item "C:\Users\*\.cache\pre-commit\*" -Recurse -Force -EA 0 }
Clean "python-history" { Remove-Item "C:\Users\*\.python_history" -Force -EA 0 }
Clean "ipython-cache" { Remove-Item "C:\Users\*\.ipython\profile_default\db\*" -Recurse -Force -EA 0 }
Clean "jupyter-cache" { Remove-Item "C:\Users\*\.cache\jupyter\*" -Recurse -Force -EA 0 }
Clean "jupyter-runtime" { Remove-Item "C:\Users\*\AppData\Roaming\jupyter\runtime\*" -Recurse -Force -EA 0 }
Clean "huggingface-cache" { Remove-Item "C:\Users\*\.cache\huggingface\*" -Recurse -Force -EA 0 }
Clean "torch-cache" { Remove-Item "C:\Users\*\.cache\torch\*" -Recurse -Force -EA 0 }
Clean "keras-cache" { Remove-Item "C:\Users\*\.keras\models\*" -Recurse -Force -EA 0 }
Clean "pycache-global" { Get-ChildItem "C:\Users\*" -Directory -Filter "__pycache__" -Recurse -EA 0 | Remove-Item -Recurse -Force -EA 0 }
Clean "pyc-files" { Get-ChildItem "C:\Users\*\*.pyc" -Recurse -EA 0 | Remove-Item -Force -EA 0 }

# ============================================================================
# PHASE 11: DEV - RUST, GO, JAVA, PHP, RUBY, .NET (60 operations)
# ============================================================================
Write-Host "`n[PHASE 11/20] DEV - RUST, GO, JAVA, PHP, RUBY, .NET" -ForegroundColor White
# Rust
Clean "cargo-registry" { Remove-Item "C:\Users\*\.cargo\registry\cache\*" -Recurse -Force -EA 0 }
Clean "cargo-index" { Remove-Item "C:\Users\*\.cargo\registry\index\*" -Recurse -Force -EA 0 }
Clean "cargo-git" { Remove-Item "C:\Users\*\.cargo\git\*" -Recurse -Force -EA 0 }
Clean "cargo-git-db" { Remove-Item "C:\Users\*\.cargo\git\db\*" -Recurse -Force -EA 0 }
Clean "cargo-git-checkout" { Remove-Item "C:\Users\*\.cargo\git\checkouts\*" -Recurse -Force -EA 0 }
Clean "cargo-advisory-db" { Remove-Item "C:\Users\*\.cargo\advisory-db\*" -Recurse -Force -EA 0 }
Clean "rustup-downloads" { Remove-Item "C:\Users\*\.rustup\downloads\*" -Recurse -Force -EA 0 }
Clean "rustup-tmp" { Remove-Item "C:\Users\*\.rustup\tmp\*" -Recurse -Force -EA 0 }
Clean "rustup-update" { Remove-Item "C:\Users\*\.rustup\update-hashes\*" -Recurse -Force -EA 0 }
Clean "rust-analyzer-cache" { Remove-Item "C:\Users\*\.cache\rust-analyzer\*" -Recurse -Force -EA 0 }
Clean "sccache" { Remove-Item "C:\Users\*\AppData\Local\Mozilla\sccache\*" -Recurse -Force -EA 0 }
# Go
Clean "go-cache" { Remove-Item "C:\Users\*\AppData\Local\go-build\*" -Recurse -Force -EA 0 }
Clean "go-modcache" { Remove-Item "C:\Users\*\go\pkg\mod\cache\*" -Recurse -Force -EA 0 }
Clean "go-sumdb" { Remove-Item "C:\Users\*\go\pkg\sumdb\*" -Recurse -Force -EA 0 }
Clean "go-testcache" { Remove-Item "C:\Users\*\AppData\Local\go\testcache\*" -Recurse -Force -EA 0 }
Clean "gopls-cache" { Remove-Item "C:\Users\*\.cache\gopls\*" -Recurse -Force -EA 0 }
Clean "golangci-lint" { Remove-Item "C:\Users\*\.cache\golangci-lint\*" -Recurse -Force -EA 0 }
# Java
Clean "gradle-cache" { Remove-Item "C:\Users\*\.gradle\caches\*" -Recurse -Force -EA 0 }
Clean "gradle-wrapper" { Remove-Item "C:\Users\*\.gradle\wrapper\dists\*" -Recurse -Force -EA 0 }
Clean "gradle-daemon" { Remove-Item "C:\Users\*\.gradle\daemon\*" -Recurse -Force -EA 0 }
Clean "gradle-native" { Remove-Item "C:\Users\*\.gradle\native\*" -Recurse -Force -EA 0 }
Clean "gradle-notifications" { Remove-Item "C:\Users\*\.gradle\notifications\*" -Recurse -Force -EA 0 }
Clean "gradle-jdks" { Remove-Item "C:\Users\*\.gradle\jdks\*" -Recurse -Force -EA 0 }
Clean "gradle-buildOutputCleanup" { Remove-Item "C:\Users\*\.gradle\buildOutputCleanup\*" -Recurse -Force -EA 0 }
Clean "maven-repo" { Remove-Item "C:\Users\*\.m2\repository\*" -Recurse -Force -EA 0 }
Clean "maven-wrapper" { Remove-Item "C:\Users\*\.m2\wrapper\*" -Recurse -Force -EA 0 }
Clean "sdkman-archives" { Remove-Item "C:\Users\*\.sdkman\archives\*" -Recurse -Force -EA 0 }
Clean "sdkman-tmp" { Remove-Item "C:\Users\*\.sdkman\tmp\*" -Recurse -Force -EA 0 }
Clean "jbang-cache" { Remove-Item "C:\Users\*\.jbang\cache\*" -Recurse -Force -EA 0 }
# PHP
Clean "composer-cache" { Remove-Item "C:\Users\*\AppData\Local\Composer\cache\*" -Recurse -Force -EA 0 }
Clean "composer-cache2" { Remove-Item "C:\Users\*\.composer\cache\*" -Recurse -Force -EA 0 }
Clean "composer-vendor" { Remove-Item "C:\Users\*\AppData\Roaming\Composer\vendor\*" -Recurse -Force -EA 0 }
Clean "phpstan-cache" { Remove-Item "C:\Users\*\.cache\phpstan\*" -Recurse -Force -EA 0 }
Clean "psalm-cache" { Remove-Item "C:\Users\*\.cache\psalm\*" -Recurse -Force -EA 0 }
# Ruby
Clean "gem-cache" { Remove-Item "C:\Users\*\.gem\ruby\*\cache\*" -Recurse -Force -EA 0 }
Clean "gem-doc" { Remove-Item "C:\Users\*\.gem\ruby\*\doc\*" -Recurse -Force -EA 0 }
Clean "bundler-cache" { Remove-Item "C:\Users\*\.bundle\cache\*" -Recurse -Force -EA 0 }
Clean "rubygems-cache" { Remove-Item "C:\Users\*\AppData\Local\rubygems\cache\*" -Recurse -Force -EA 0 }
Clean "rbenv-cache" { Remove-Item "C:\Users\*\.rbenv\cache\*" -Recurse -Force -EA 0 }
Clean "solargraph-cache" { Remove-Item "C:\Users\*\.solargraph\cache\*" -Recurse -Force -EA 0 }
# .NET
Clean "nuget-cache" { Remove-Item "C:\Users\*\.nuget\packages\*" -Recurse -Force -EA 0 }
Clean "nuget-httpcache" { Remove-Item "C:\Users\*\AppData\Local\NuGet\Cache\*" -Recurse -Force -EA 0 }
Clean "nuget-v3cache" { Remove-Item "C:\Users\*\AppData\Local\NuGet\v3-cache\*" -Recurse -Force -EA 0 }
Clean "nuget-plugins-cache" { Remove-Item "C:\Users\*\AppData\Local\NuGet\plugins-cache\*" -Recurse -Force -EA 0 }
Clean "dotnet-tools" { Remove-Item "C:\Users\*\.dotnet\tools\.store\*" -Recurse -Force -EA 0 }
Clean "dotnet-sdk" { Remove-Item "C:\Users\*\.dotnet\sdk-advertising\*" -Recurse -Force -EA 0 }
Clean "dotnet-templateengine" { Remove-Item "C:\Users\*\.dotnet\templateengine\*" -Recurse -Force -EA 0 }
Clean "msbuild-cache" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\MSBuild\*" -Recurse -Force -EA 0 }
Clean "omnisharp-cache" { Remove-Item "C:\Users\*\.omnisharp\*" -Recurse -Force -EA 0 }
# C/C++
Clean "vcpkg-cache" { Remove-Item "C:\Users\*\AppData\Local\vcpkg\*" -Recurse -Force -EA 0 }
Clean "vcpkg-archives" { Remove-Item "C:\Users\*\AppData\Local\vcpkg\archives\*" -Recurse -Force -EA 0 }
Clean "conan-cache" { Remove-Item "C:\Users\*\.conan\data\*" -Recurse -Force -EA 0 }
Clean "conan-download" { Remove-Item "C:\Users\*\.conan\download_cache\*" -Recurse -Force -EA 0 }
Clean "cmake-cache" { Remove-Item "C:\Users\*\.cmake\packages\*" -Recurse -Force -EA 0 }
Clean "ccache" { Remove-Item "C:\Users\*\AppData\Local\ccache\*" -Recurse -Force -EA 0 }
Clean "clangd-cache" { Remove-Item "C:\Users\*\.cache\clangd\*" -Recurse -Force -EA 0 }
# Elixir/Erlang
Clean "hex-cache" { Remove-Item "C:\Users\*\.hex\*" -Recurse -Force -EA 0 }
Clean "mix-cache" { Remove-Item "C:\Users\*\.mix\archives\*" -Recurse -Force -EA 0 }
Clean "rebar3-cache" { Remove-Item "C:\Users\*\.cache\rebar3\*" -Recurse -Force -EA 0 }

# ============================================================================
# PHASE 12: IDE/EDITORS - VS CODE FAMILY (50 operations)
# ============================================================================
Write-Host "`n[PHASE 12/20] IDE/EDITORS - VS CODE FAMILY" -ForegroundColor White
# VS Code
Clean "vscode-cache" { Remove-Item "C:\Users\*\AppData\Roaming\Code\Cache\*" -Recurse -Force -EA 0 }
Clean "vscode-cacheddata" { Remove-Item "C:\Users\*\AppData\Roaming\Code\CachedData\*" -Recurse -Force -EA 0 }
Clean "vscode-cachedext" { Remove-Item "C:\Users\*\AppData\Roaming\Code\CachedExtensions\*" -Recurse -Force -EA 0 }
Clean "vscode-cachedvsix" { Remove-Item "C:\Users\*\AppData\Roaming\Code\CachedExtensionVSIXs\*" -Recurse -Force -EA 0 }
Clean "vscode-logs" { Remove-Item "C:\Users\*\AppData\Roaming\Code\logs\*" -Recurse -Force -EA 0 }
Clean "vscode-workspaceStorage" { Remove-Item "C:\Users\*\AppData\Roaming\Code\User\workspaceStorage\*" -Recurse -Force -EA 0 }
Clean "vscode-history" { Remove-Item "C:\Users\*\AppData\Roaming\Code\User\History\*" -Recurse -Force -EA 0 }
Clean "vscode-cpptools" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\vscode-cpptools\ipch\*" -Recurse -Force -EA 0 }
Clean "vscode-crashreport" { Remove-Item "C:\Users\*\AppData\Roaming\Code\Crashpad\*" -Recurse -Force -EA 0 }
Clean "vscode-gpucache" { Remove-Item "C:\Users\*\AppData\Roaming\Code\GPUCache\*" -Recurse -Force -EA 0 }
Clean "vscode-codecache" { Remove-Item "C:\Users\*\AppData\Roaming\Code\Code Cache\*" -Recurse -Force -EA 0 }
Clean "vscode-storage" { Remove-Item "C:\Users\*\AppData\Roaming\Code\Local Storage\*" -Recurse -Force -EA 0 }
Clean "vscode-blob" { Remove-Item "C:\Users\*\AppData\Roaming\Code\blob_storage\*" -Recurse -Force -EA 0 }
Clean "vscode-serviceworker" { Remove-Item "C:\Users\*\AppData\Roaming\Code\Service Worker\*" -Recurse -Force -EA 0 }
Clean "vscode-network" { Remove-Item "C:\Users\*\AppData\Roaming\Code\Network\*" -Recurse -Force -EA 0 }
# VS Code Insiders
Clean "vscode-insiders-cache" { Remove-Item "C:\Users\*\AppData\Roaming\Code - Insiders\Cache\*" -Recurse -Force -EA 0 }
Clean "vscode-insiders-cacheddata" { Remove-Item "C:\Users\*\AppData\Roaming\Code - Insiders\CachedData\*" -Recurse -Force -EA 0 }
Clean "vscode-insiders-logs" { Remove-Item "C:\Users\*\AppData\Roaming\Code - Insiders\logs\*" -Recurse -Force -EA 0 }
Clean "vscode-insiders-workspace" { Remove-Item "C:\Users\*\AppData\Roaming\Code - Insiders\User\workspaceStorage\*" -Recurse -Force -EA 0 }
Clean "vscode-insiders-history" { Remove-Item "C:\Users\*\AppData\Roaming\Code - Insiders\User\History\*" -Recurse -Force -EA 0 }
Clean "vscode-insiders-gpucache" { Remove-Item "C:\Users\*\AppData\Roaming\Code - Insiders\GPUCache\*" -Recurse -Force -EA 0 }
# Cursor
Clean "cursor-cache" { Remove-Item "C:\Users\*\AppData\Local\Cursor\Cache\*" -Recurse -Force -EA 0 }
Clean "cursor-cache2" { Remove-Item "C:\Users\*\AppData\Roaming\Cursor\Cache\*" -Recurse -Force -EA 0 }
Clean "cursor-logs" { Remove-Item "C:\Users\*\AppData\Roaming\Cursor\logs\*" -Recurse -Force -EA 0 }
Clean "cursor-cacheddata" { Remove-Item "C:\Users\*\AppData\Roaming\Cursor\CachedData\*" -Recurse -Force -EA 0 }
Clean "cursor-cachedext" { Remove-Item "C:\Users\*\AppData\Roaming\Cursor\CachedExtensions\*" -Recurse -Force -EA 0 }
Clean "cursor-workspace" { Remove-Item "C:\Users\*\AppData\Roaming\Cursor\User\workspaceStorage\*" -Recurse -Force -EA 0 }
Clean "cursor-history" { Remove-Item "C:\Users\*\AppData\Roaming\Cursor\User\History\*" -Recurse -Force -EA 0 }
Clean "cursor-gpucache" { Remove-Item "C:\Users\*\AppData\Roaming\Cursor\GPUCache\*" -Recurse -Force -EA 0 }
Clean "cursor-crashpad" { Remove-Item "C:\Users\*\AppData\Roaming\Cursor\Crashpad\*" -Recurse -Force -EA 0 }
Clean "cursor-blob" { Remove-Item "C:\Users\*\AppData\Roaming\Cursor\blob_storage\*" -Recurse -Force -EA 0 }
# Windsurf
Clean "windsurf-cache" { Remove-Item "C:\Users\*\AppData\Roaming\Windsurf\Cache\*" -Recurse -Force -EA 0 }
Clean "windsurf-cacheddata" { Remove-Item "C:\Users\*\AppData\Roaming\Windsurf\CachedData\*" -Recurse -Force -EA 0 }
Clean "windsurf-logs" { Remove-Item "C:\Users\*\AppData\Roaming\Windsurf\logs\*" -Recurse -Force -EA 0 }
Clean "windsurf-workspace" { Remove-Item "C:\Users\*\AppData\Roaming\Windsurf\User\workspaceStorage\*" -Recurse -Force -EA 0 }
Clean "windsurf-history" { Remove-Item "C:\Users\*\AppData\Roaming\Windsurf\User\History\*" -Recurse -Force -EA 0 }
Clean "windsurf-gpucache" { Remove-Item "C:\Users\*\AppData\Roaming\Windsurf\GPUCache\*" -Recurse -Force -EA 0 }
Clean "windsurf-crashpad" { Remove-Item "C:\Users\*\AppData\Roaming\Windsurf\Crashpad\*" -Recurse -Force -EA 0 }
# VSCodium
Clean "vscodium-cache" { Remove-Item "C:\Users\*\AppData\Roaming\VSCodium\Cache\*" -Recurse -Force -EA 0 }
Clean "vscodium-cacheddata" { Remove-Item "C:\Users\*\AppData\Roaming\VSCodium\CachedData\*" -Recurse -Force -EA 0 }
Clean "vscodium-logs" { Remove-Item "C:\Users\*\AppData\Roaming\VSCodium\logs\*" -Recurse -Force -EA 0 }
Clean "vscodium-workspace" { Remove-Item "C:\Users\*\AppData\Roaming\VSCodium\User\workspaceStorage\*" -Recurse -Force -EA 0 }
# Zed
Clean "zed-cache" { Remove-Item "C:\Users\*\AppData\Local\Zed\cache\*" -Recurse -Force -EA 0 }
Clean "zed-logs" { Remove-Item "C:\Users\*\AppData\Local\Zed\logs\*" -Recurse -Force -EA 0 }
# Sublime Text
Clean "sublimetext-cache" { Remove-Item "C:\Users\*\AppData\Local\Sublime Text\Cache\*" -Recurse -Force -EA 0 }
Clean "sublimetext-index" { Remove-Item "C:\Users\*\AppData\Local\Sublime Text\Index\*" -Recurse -Force -EA 0 }
Clean "sublimetext-backup" { Remove-Item "C:\Users\*\AppData\Roaming\Sublime Text\Backup\*" -Recurse -Force -EA 0 }
# Atom (legacy)
Clean "atom-cache" { Remove-Item "C:\Users\*\AppData\Local\atom\*\Cache\*" -Recurse -Force -EA 0 }
Clean "atom-compile" { Remove-Item "C:\Users\*\.atom\compile-cache\*" -Recurse -Force -EA 0 }

# ============================================================================
# PHASE 13: IDE/EDITORS - JETBRAINS & VISUAL STUDIO (60 operations)
# ============================================================================
Write-Host "`n[PHASE 13/20] IDE/EDITORS - JETBRAINS & VISUAL STUDIO" -ForegroundColor White
# JetBrains Generic
Clean "jetbrains-caches" { Remove-Item "C:\Users\*\AppData\Local\JetBrains\*\caches\*" -Recurse -Force -EA 0 }
Clean "jetbrains-index" { Remove-Item "C:\Users\*\AppData\Local\JetBrains\*\index\*" -Recurse -Force -EA 0 }
Clean "jetbrains-transient" { Remove-Item "C:\Users\*\AppData\Local\JetBrains\Transient\*" -Recurse -Force -EA 0 }
Clean "jetbrains-log" { Remove-Item "C:\Users\*\AppData\Local\JetBrains\*\log\*" -Recurse -Force -EA 0 }
Clean "jetbrains-tmp" { Remove-Item "C:\Users\*\AppData\Local\JetBrains\*\tmp\*" -Recurse -Force -EA 0 }
Clean "jetbrains-recovery" { Remove-Item "C:\Users\*\AppData\Local\JetBrains\*\recovery\*" -Recurse -Force -EA 0 }
Clean "jetbrains-plugins-cache" { Remove-Item "C:\Users\*\AppData\Local\JetBrains\*\plugins-sandbox\*" -Recurse -Force -EA 0 }
# IntelliJ IDEA
Clean "idea-cache" { Remove-Item "C:\Users\*\AppData\Local\JetBrains\IntelliJIdea*\caches\*" -Recurse -Force -EA 0 }
Clean "idea-index" { Remove-Item "C:\Users\*\AppData\Local\JetBrains\IntelliJIdea*\index\*" -Recurse -Force -EA 0 }
Clean "idea-log" { Remove-Item "C:\Users\*\AppData\Local\JetBrains\IntelliJIdea*\log\*" -Recurse -Force -EA 0 }
Clean "idea-compile" { Remove-Item "C:\Users\*\AppData\Local\JetBrains\IntelliJIdea*\compile-server\*" -Recurse -Force -EA 0 }
Clean "ideaic-cache" { Remove-Item "C:\Users\*\AppData\Local\JetBrains\IdeaIC*\caches\*" -Recurse -Force -EA 0 }
Clean "ideaic-index" { Remove-Item "C:\Users\*\AppData\Local\JetBrains\IdeaIC*\index\*" -Recurse -Force -EA 0 }
# PyCharm
Clean "pycharm-cache" { Remove-Item "C:\Users\*\AppData\Local\JetBrains\PyCharm*\caches\*" -Recurse -Force -EA 0 }
Clean "pycharm-index" { Remove-Item "C:\Users\*\AppData\Local\JetBrains\PyCharm*\index\*" -Recurse -Force -EA 0 }
Clean "pycharm-log" { Remove-Item "C:\Users\*\AppData\Local\JetBrains\PyCharm*\log\*" -Recurse -Force -EA 0 }
Clean "pycharmce-cache" { Remove-Item "C:\Users\*\AppData\Local\JetBrains\PyCharmCE*\caches\*" -Recurse -Force -EA 0 }
# WebStorm
Clean "webstorm-cache" { Remove-Item "C:\Users\*\AppData\Local\JetBrains\WebStorm*\caches\*" -Recurse -Force -EA 0 }
Clean "webstorm-index" { Remove-Item "C:\Users\*\AppData\Local\JetBrains\WebStorm*\index\*" -Recurse -Force -EA 0 }
Clean "webstorm-log" { Remove-Item "C:\Users\*\AppData\Local\JetBrains\WebStorm*\log\*" -Recurse -Force -EA 0 }
# Rider
Clean "rider-cache" { Remove-Item "C:\Users\*\AppData\Local\JetBrains\Rider*\caches\*" -Recurse -Force -EA 0 }
Clean "rider-index" { Remove-Item "C:\Users\*\AppData\Local\JetBrains\Rider*\index\*" -Recurse -Force -EA 0 }
Clean "rider-log" { Remove-Item "C:\Users\*\AppData\Local\JetBrains\Rider*\log\*" -Recurse -Force -EA 0 }
# GoLand
Clean "goland-cache" { Remove-Item "C:\Users\*\AppData\Local\JetBrains\GoLand*\caches\*" -Recurse -Force -EA 0 }
Clean "goland-index" { Remove-Item "C:\Users\*\AppData\Local\JetBrains\GoLand*\index\*" -Recurse -Force -EA 0 }
Clean "goland-log" { Remove-Item "C:\Users\*\AppData\Local\JetBrains\GoLand*\log\*" -Recurse -Force -EA 0 }
# CLion
Clean "clion-cache" { Remove-Item "C:\Users\*\AppData\Local\JetBrains\CLion*\caches\*" -Recurse -Force -EA 0 }
Clean "clion-index" { Remove-Item "C:\Users\*\AppData\Local\JetBrains\CLion*\index\*" -Recurse -Force -EA 0 }
Clean "clion-log" { Remove-Item "C:\Users\*\AppData\Local\JetBrains\CLion*\log\*" -Recurse -Force -EA 0 }
Clean "clion-cmake" { Remove-Item "C:\Users\*\AppData\Local\JetBrains\CLion*\cmake\*" -Recurse -Force -EA 0 }
# DataGrip
Clean "datagrip-cache" { Remove-Item "C:\Users\*\AppData\Local\JetBrains\DataGrip*\caches\*" -Recurse -Force -EA 0 }
Clean "datagrip-index" { Remove-Item "C:\Users\*\AppData\Local\JetBrains\DataGrip*\index\*" -Recurse -Force -EA 0 }
Clean "datagrip-log" { Remove-Item "C:\Users\*\AppData\Local\JetBrains\DataGrip*\log\*" -Recurse -Force -EA 0 }
# RubyMine
Clean "rubymine-cache" { Remove-Item "C:\Users\*\AppData\Local\JetBrains\RubyMine*\caches\*" -Recurse -Force -EA 0 }
Clean "rubymine-index" { Remove-Item "C:\Users\*\AppData\Local\JetBrains\RubyMine*\index\*" -Recurse -Force -EA 0 }
# PhpStorm
Clean "phpstorm-cache" { Remove-Item "C:\Users\*\AppData\Local\JetBrains\PhpStorm*\caches\*" -Recurse -Force -EA 0 }
Clean "phpstorm-index" { Remove-Item "C:\Users\*\AppData\Local\JetBrains\PhpStorm*\index\*" -Recurse -Force -EA 0 }
# RustRover
Clean "rustrover-cache" { Remove-Item "C:\Users\*\AppData\Local\JetBrains\RustRover*\caches\*" -Recurse -Force -EA 0 }
Clean "rustrover-index" { Remove-Item "C:\Users\*\AppData\Local\JetBrains\RustRover*\index\*" -Recurse -Force -EA 0 }
# Visual Studio
Clean "vs-compmodel" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\VisualStudio\*\ComponentModelCache\*" -Recurse -Force -EA 0 }
Clean "vs-extensions" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\VisualStudio\*\Extensions\*\Temp\*" -Recurse -Force -EA 0 }
Clean "vs-mefcache" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\VisualStudio\*\Mef\*" -Recurse -Force -EA 0 }
Clean "vs-projectcache" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\VisualStudio\*\ProjectCache\*" -Recurse -Force -EA 0 }
Clean "vs-vscc" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\VisualStudio\*\*.vscc" -Force -EA 0 }
Clean "vs-ipch" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\VisualStudio\*\VC\ipch\*" -Recurse -Force -EA 0 }
Clean "vs-squiggle" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\VisualStudio\*\SquiggleLint\*" -Recurse -Force -EA 0 }
Clean "vs-telemetry" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\VisualStudio\*\Telemetry\*" -Recurse -Force -EA 0 }
Clean "vs-experiments" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\VisualStudio\*\RemoteSettings\*" -Recurse -Force -EA 0 }
Clean "vs-webmvc" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\VisualStudio\*\WebCache\*" -Recurse -Force -EA 0 }
Clean "vs-azurefunc" { Remove-Item "C:\Users\*\AppData\Local\AzureFunctions\*" -Recurse -Force -EA 0 }
# Android Studio
Clean "android-cache" { Remove-Item "C:\Users\*\AppData\Local\Google\AndroidStudio*\caches\*" -Recurse -Force -EA 0 }
Clean "android-index" { Remove-Item "C:\Users\*\AppData\Local\Google\AndroidStudio*\index\*" -Recurse -Force -EA 0 }
Clean "android-log" { Remove-Item "C:\Users\*\AppData\Local\Google\AndroidStudio*\log\*" -Recurse -Force -EA 0 }
Clean "android-tmp" { Remove-Item "C:\Users\*\AppData\Local\Google\AndroidStudio*\tmp\*" -Recurse -Force -EA 0 }
Clean "android-avd" { Remove-Item "C:\Users\*\.android\avd\*\cache\*" -Recurse -Force -EA 0 }
Clean "android-build-cache" { Remove-Item "C:\Users\*\.android\build-cache\*" -Recurse -Force -EA 0 }
Clean "android-sdk-cache" { Remove-Item "C:\Users\*\.android\cache\*" -Recurse -Force -EA 0 }

# ============================================================================
# PHASE 14: GAMING PLATFORMS (55 operations)
# ============================================================================
Write-Host "`n[PHASE 14/20] GAMING PLATFORMS" -ForegroundColor White
# Steam
Clean "steam-htmlcache" { Remove-Item "C:\Users\*\AppData\Local\Steam\htmlcache\*" -Recurse -Force -EA 0 }
Clean "steam-appcache" { Remove-Item "C:\Users\*\AppData\Local\Steam\appcache\*" -Recurse -Force -EA 0 }
Clean "steam-depotcache" { Remove-Item "C:\Users\*\AppData\Local\Steam\depotcache\*" -Recurse -Force -EA 0 }
Clean "steam-shadercache" { Remove-Item "C:\Users\*\AppData\Local\Steam\shadercache\*" -Recurse -Force -EA 0 }
Clean "steam-shadercache2" { Remove-Item "C:\Program Files (x86)\Steam\shadercache\*" -Recurse -Force -EA 0 }
Clean "steam-crashdumps" { Remove-Item "C:\Program Files (x86)\Steam\dumps\*" -Recurse -Force -EA 0 }
Clean "steam-logs" { Remove-Item "C:\Program Files (x86)\Steam\logs\*" -Recurse -Force -EA 0 }
Clean "steam-remote" { Remove-Item "C:\Users\*\AppData\Local\Steam\remotecache\*" -Recurse -Force -EA 0 }
Clean "steam-downloading" { Remove-Item "C:\Program Files (x86)\Steam\steamapps\downloading\*" -Recurse -Force -EA 0 }
Clean "steam-workshop-temp" { Remove-Item "C:\Program Files (x86)\Steam\steamapps\workshop\temp\*" -Recurse -Force -EA 0 }
# Epic Games
Clean "epic-webcache" { Remove-Item "C:\Users\*\AppData\Local\EpicGamesLauncher\Saved\webcache\*" -Recurse -Force -EA 0 }
Clean "epic-logs" { Remove-Item "C:\Users\*\AppData\Local\EpicGamesLauncher\Saved\Logs\*" -Recurse -Force -EA 0 }
Clean "epic-cache" { Remove-Item "C:\Users\*\AppData\Local\EpicGamesLauncher\Saved\Cache\*" -Recurse -Force -EA 0 }
Clean "epic-httpcache" { Remove-Item "C:\Users\*\AppData\Local\EpicGamesLauncher\Saved\HTTPCache\*" -Recurse -Force -EA 0 }
Clean "epic-crashreports" { Remove-Item "C:\Users\*\AppData\Local\EpicGamesLauncher\Saved\CrashReportClient\*" -Recurse -Force -EA 0 }
Clean "epic-overlay" { Remove-Item "C:\Users\*\AppData\Local\EpicGamesLauncher\Saved\Overlay\*" -Recurse -Force -EA 0 }
# GOG Galaxy
Clean "gog-webcache" { Remove-Item "C:\Users\*\AppData\Local\GOG.com\Galaxy\webcache\*" -Recurse -Force -EA 0 }
Clean "gog-logs" { Remove-Item "C:\Users\*\AppData\Local\GOG.com\Galaxy\Logs\*" -Recurse -Force -EA 0 }
Clean "gog-cache" { Remove-Item "C:\Users\*\AppData\Local\GOG.com\Galaxy\cache\*" -Recurse -Force -EA 0 }
Clean "gog-storage" { Remove-Item "C:\Users\*\AppData\Local\GOG.com\Galaxy\Storage\*" -Recurse -Force -EA 0 }
# EA App / Origin
Clean "ea-cache" { Remove-Item "C:\Users\*\AppData\Local\Electronic Arts\EA Desktop\cache\*" -Recurse -Force -EA 0 }
Clean "ea-logs" { Remove-Item "C:\Users\*\AppData\Local\Electronic Arts\EA Desktop\Logs\*" -Recurse -Force -EA 0 }
Clean "origin-cache" { Remove-Item "C:\Users\*\AppData\Local\Origin\Origin\cache\*" -Recurse -Force -EA 0 }
Clean "origin-logs" { Remove-Item "C:\Users\*\AppData\Local\Origin\Logs\*" -Recurse -Force -EA 0 }
Clean "origin-thin" { Remove-Item "C:\Users\*\AppData\Local\Origin\ThinSetup\*" -Recurse -Force -EA 0 }
# Ubisoft Connect
Clean "ubisoft-cache" { Remove-Item "C:\Users\*\AppData\Local\Ubisoft Game Launcher\cache\*" -Recurse -Force -EA 0 }
Clean "ubisoft-logs" { Remove-Item "C:\Users\*\AppData\Local\Ubisoft Game Launcher\logs\*" -Recurse -Force -EA 0 }
Clean "ubisoft-savegames-cache" { Remove-Item "C:\Users\*\AppData\Local\Ubisoft Game Launcher\savegames_cache\*" -Recurse -Force -EA 0 }
Clean "ubisoft-spool" { Remove-Item "C:\Users\*\AppData\Local\Ubisoft Game Launcher\spool\*" -Recurse -Force -EA 0 }
Clean "ubisoft-webcache" { Remove-Item "C:\Users\*\AppData\Local\Ubisoft Game Launcher\webcache\*" -Recurse -Force -EA 0 }
# Battle.net
Clean "battlenet-cache" { Remove-Item "C:\Users\*\AppData\Local\Battle.net\Cache\*" -Recurse -Force -EA 0 }
Clean "battlenet-logs" { Remove-Item "C:\Users\*\AppData\Local\Battle.net\Logs\*" -Recurse -Force -EA 0 }
Clean "battlenet-gpucache" { Remove-Item "C:\Users\*\AppData\Local\Battle.net\GPUCache\*" -Recurse -Force -EA 0 }
Clean "battlenet-crashreporter" { Remove-Item "C:\Users\*\AppData\Local\Blizzard Entertainment\Battle.net\CachedData\*" -Recurse -Force -EA 0 }
Clean "blizzard-logs" { Remove-Item "C:\Users\*\AppData\Local\Blizzard Entertainment\Logs\*" -Recurse -Force -EA 0 }
# Xbox App
Clean "xbox-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.GamingApp_*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "xbox-temp" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.GamingApp_*\TempState\*" -Recurse -Force -EA 0 }
Clean "xbox-storage" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.XboxApp_*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "gamebar-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.XboxGamingOverlay_*\LocalCache\*" -Recurse -Force -EA 0 }
# Rockstar Games
Clean "rockstar-launcher" { Remove-Item "C:\Users\*\AppData\Local\Rockstar Games\Launcher\*\webcache\*" -Recurse -Force -EA 0 }
Clean "rockstar-logs" { Remove-Item "C:\Users\*\Documents\Rockstar Games\Launcher\Logs\*" -Recurse -Force -EA 0 }
# Amazon Games
Clean "amazon-cache" { Remove-Item "C:\Users\*\AppData\Local\Amazon Games\cache\*" -Recurse -Force -EA 0 }
Clean "amazon-logs" { Remove-Item "C:\Users\*\AppData\Local\Amazon Games\Logs\*" -Recurse -Force -EA 0 }
# itch.io
Clean "itch-cache" { Remove-Item "C:\Users\*\AppData\Local\itch\Cache\*" -Recurse -Force -EA 0 }
Clean "itch-logs" { Remove-Item "C:\Users\*\AppData\Local\itch\logs\*" -Recurse -Force -EA 0 }
# Riot Games
Clean "riot-logs" { Remove-Item "C:\Users\*\AppData\Local\Riot Games\Riot Client\Logs\*" -Recurse -Force -EA 0 }
Clean "riot-cache" { Remove-Item "C:\Users\*\AppData\Local\Riot Games\Riot Client\Cache\*" -Recurse -Force -EA 0 }
# Nvidia GeForce Experience
Clean "nvidia-cache" { Remove-Item "C:\Users\*\AppData\Local\NVIDIA\NvBackend\*" -Recurse -Force -EA 0 }
Clean "nvidia-glcache" { Remove-Item "C:\Users\*\AppData\Local\NVIDIA\GLCache\*" -Recurse -Force -EA 0 }
Clean "nvidia-dxcache" { Remove-Item "C:\Users\*\AppData\Local\NVIDIA\DXCache\*" -Recurse -Force -EA 0 }
Clean "nvidia-computecache" { Remove-Item "C:\Users\*\AppData\Local\NVIDIA\ComputeCache\*" -Recurse -Force -EA 0 }
Clean "nvidia-optix" { Remove-Item "C:\Users\*\AppData\Local\NVIDIA\OptixCache\*" -Recurse -Force -EA 0 }
# AMD
Clean "amd-dxcache" { Remove-Item "C:\Users\*\AppData\Local\AMD\DxCache\*" -Recurse -Force -EA 0 }
Clean "amd-glcache" { Remove-Item "C:\Users\*\AppData\Local\AMD\GLCache\*" -Recurse -Force -EA 0 }

# ============================================================================
# PHASE 15: COMMUNICATION APPS (50 operations)
# ============================================================================
Write-Host "`n[PHASE 15/20] COMMUNICATION APPS" -ForegroundColor White
# Slack
Clean "slack-cache" { Remove-Item "C:\Users\*\AppData\Local\Slack\Cache\*" -Recurse -Force -EA 0 }
Clean "slack-codecache" { Remove-Item "C:\Users\*\AppData\Local\Slack\Code Cache\*" -Recurse -Force -EA 0 }
Clean "slack-gpucache" { Remove-Item "C:\Users\*\AppData\Local\Slack\GPUCache\*" -Recurse -Force -EA 0 }
Clean "slack-logs" { Remove-Item "C:\Users\*\AppData\Local\Slack\logs\*" -Recurse -Force -EA 0 }
Clean "slack-serviceworker" { Remove-Item "C:\Users\*\AppData\Local\Slack\Service Worker\*" -Recurse -Force -EA 0 }
Clean "slack-storage" { Remove-Item "C:\Users\*\AppData\Local\Slack\Storage\*" -Recurse -Force -EA 0 }
Clean "slack-crashpad" { Remove-Item "C:\Users\*\AppData\Local\Slack\Crashpad\*" -Recurse -Force -EA 0 }
# Discord
Clean "discord-cache" { Remove-Item "C:\Users\*\AppData\Local\Discord\Cache\*" -Recurse -Force -EA 0 }
Clean "discord-codecache" { Remove-Item "C:\Users\*\AppData\Local\Discord\Code Cache\*" -Recurse -Force -EA 0 }
Clean "discord-gpucache" { Remove-Item "C:\Users\*\AppData\Local\Discord\GPUCache\*" -Recurse -Force -EA 0 }
Clean "discord-crashpad" { Remove-Item "C:\Users\*\AppData\Local\Discord\Crashpad\*" -Recurse -Force -EA 0 }
Clean "discord-blob" { Remove-Item "C:\Users\*\AppData\Local\Discord\blob_storage\*" -Recurse -Force -EA 0 }
Clean "discord-serviceworker" { Remove-Item "C:\Users\*\AppData\Local\Discord\Service Worker\*" -Recurse -Force -EA 0 }
# Microsoft Teams
Clean "teams-cache" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Teams\Cache\*" -Recurse -Force -EA 0 }
Clean "teams-tmp" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Teams\tmp\*" -Recurse -Force -EA 0 }
Clean "teams-blob" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Teams\blob_storage\*" -Recurse -Force -EA 0 }
Clean "teams-gpucache" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Teams\GPUCache\*" -Recurse -Force -EA 0 }
Clean "teams-codecache" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Teams\Code Cache\*" -Recurse -Force -EA 0 }
Clean "teams-serviceworker" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Teams\Service Worker\*" -Recurse -Force -EA 0 }
Clean "teams-logs" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Teams\logs\*" -Recurse -Force -EA 0 }
Clean "teams-watchdog" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Teams\watchdog\*" -Recurse -Force -EA 0 }
Clean "teams-media-stack" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Teams\media-stack\*" -Recurse -Force -EA 0 }
# Zoom
Clean "zoom-logs" { Remove-Item "C:\Users\*\AppData\Roaming\Zoom\logs\*" -Recurse -Force -EA 0 }
Clean "zoom-data" { Remove-Item "C:\Users\*\AppData\Roaming\Zoom\data\*" -Recurse -Force -EA 0 }
Clean "zoom-cache" { Remove-Item "C:\Users\*\AppData\Roaming\Zoom\bin\*\aomhost.exe.log" -Force -EA 0 }
Clean "zoom-crashdump" { Remove-Item "C:\Users\*\AppData\Roaming\Zoom\crashDump\*" -Recurse -Force -EA 0 }
# Telegram
Clean "telegram-cache" { Remove-Item "C:\Users\*\AppData\Roaming\Telegram Desktop\tdata\user_data\cache\*" -Recurse -Force -EA 0 }
Clean "telegram-temp" { Remove-Item "C:\Users\*\AppData\Roaming\Telegram Desktop\tdata\temp\*" -Recurse -Force -EA 0 }
Clean "telegram-logs" { Remove-Item "C:\Users\*\AppData\Roaming\Telegram Desktop\log*" -Force -EA 0 }
# WhatsApp Desktop
Clean "whatsapp-cache" { Remove-Item "C:\Users\*\AppData\Local\WhatsApp\Cache\*" -Recurse -Force -EA 0 }
Clean "whatsapp-gpucache" { Remove-Item "C:\Users\*\AppData\Local\WhatsApp\GPUCache\*" -Recurse -Force -EA 0 }
Clean "whatsapp-codecache" { Remove-Item "C:\Users\*\AppData\Local\WhatsApp\Code Cache\*" -Recurse -Force -EA 0 }
Clean "whatsapp-crashpad" { Remove-Item "C:\Users\*\AppData\Local\WhatsApp\Crashpad\*" -Recurse -Force -EA 0 }
Clean "whatsapp-logs" { Remove-Item "C:\Users\*\AppData\Local\WhatsApp\logs\*" -Recurse -Force -EA 0 }
# Signal
Clean "signal-cache" { Remove-Item "C:\Users\*\AppData\Roaming\Signal\Cache\*" -Recurse -Force -EA 0 }
Clean "signal-gpucache" { Remove-Item "C:\Users\*\AppData\Roaming\Signal\GPUCache\*" -Recurse -Force -EA 0 }
Clean "signal-logs" { Remove-Item "C:\Users\*\AppData\Roaming\Signal\logs\*" -Recurse -Force -EA 0 }
Clean "signal-crashpad" { Remove-Item "C:\Users\*\AppData\Roaming\Signal\Crashpad\*" -Recurse -Force -EA 0 }
# Skype
Clean "skype-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.SkypeApp_*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "skype-temp" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.SkypeApp_*\TempState\*" -Recurse -Force -EA 0 }
Clean "skype-roaming-cache" { Remove-Item "C:\Users\*\AppData\Roaming\Skype\*\cache\*" -Recurse -Force -EA 0 }
# Webex
Clean "webex-cache" { Remove-Item "C:\Users\*\AppData\Local\CiscoSpark\Cache\*" -Recurse -Force -EA 0 }
Clean "webex-logs" { Remove-Item "C:\Users\*\AppData\Local\CiscoSpark\logs\*" -Recurse -Force -EA 0 }
# Google Chat
Clean "chat-cache" { Remove-Item "C:\Users\*\AppData\Local\Google\Chrome\User Data\*\Chat\Cache\*" -Recurse -Force -EA 0 }
# Element / Matrix
Clean "element-cache" { Remove-Item "C:\Users\*\AppData\Roaming\Element\Cache\*" -Recurse -Force -EA 0 }
Clean "element-logs" { Remove-Item "C:\Users\*\AppData\Roaming\Element\logs\*" -Recurse -Force -EA 0 }

# ============================================================================
# PHASE 16: MEDIA & CREATIVE APPS (55 operations)
# ============================================================================
Write-Host "`n[PHASE 16/20] MEDIA & CREATIVE APPS" -ForegroundColor White
# Spotify
Clean "spotify-data" { Remove-Item "C:\Users\*\AppData\Local\Spotify\Data\*" -Recurse -Force -EA 0 }
Clean "spotify-storage" { Remove-Item "C:\Users\*\AppData\Local\Spotify\Storage\*" -Recurse -Force -EA 0 }
Clean "spotify-cache" { Remove-Item "C:\Users\*\AppData\Local\Spotify\Browser\Cache\*" -Recurse -Force -EA 0 }
Clean "spotify-gpucache" { Remove-Item "C:\Users\*\AppData\Local\Spotify\Browser\GPUCache\*" -Recurse -Force -EA 0 }
Clean "spotify-offline" { Remove-Item "C:\Users\*\AppData\Local\Spotify\offline.bnk" -Force -EA 0 }
Clean "spotify-watchdog" { Remove-Item "C:\Users\*\AppData\Local\Spotify\Watchdog\*" -Recurse -Force -EA 0 }
# Adobe Creative Cloud
Clean "adobe-cache" { Remove-Item "C:\Users\*\AppData\Local\Adobe\*\Cache\*" -Recurse -Force -EA 0 }
Clean "adobe-temp" { Remove-Item "C:\Users\*\AppData\Local\Temp\Adobe\*" -Recurse -Force -EA 0 }
Clean "adobe-logs" { Remove-Item "C:\Users\*\AppData\Local\Adobe\*\Logs\*" -Recurse -Force -EA 0 }
Clean "adobe-mediascache" { Remove-Item "C:\Users\*\AppData\Local\Adobe\Common\Media Cache\*" -Recurse -Force -EA 0 }
Clean "adobe-mediascache-files" { Remove-Item "C:\Users\*\AppData\Local\Adobe\Common\Media Cache Files\*" -Recurse -Force -EA 0 }
Clean "adobe-peakcache" { Remove-Item "C:\Users\*\AppData\Local\Adobe\Common\Peak Cache\*" -Recurse -Force -EA 0 }
Clean "adobe-ptx" { Remove-Item "C:\Users\*\AppData\Local\Adobe\Common\PTX\*" -Recurse -Force -EA 0 }
Clean "adobe-dynamiclink" { Remove-Item "C:\Users\*\AppData\Local\Adobe\Common\dynamiclink\*" -Recurse -Force -EA 0 }
Clean "photoshop-temp" { Remove-Item "C:\Users\*\AppData\Local\Temp\Photoshop Temp*" -Force -EA 0 }
Clean "premiere-temp" { Remove-Item "C:\Users\*\AppData\Local\Adobe\Premiere Pro\*\Media Cache\*" -Recurse -Force -EA 0 }
Clean "aftereffects-temp" { Remove-Item "C:\Users\*\AppData\Local\Adobe\After Effects\*\Cache\*" -Recurse -Force -EA 0 }
Clean "illustrator-temp" { Remove-Item "C:\Users\*\AppData\Local\Adobe\Illustrator\*\Cache\*" -Recurse -Force -EA 0 }
Clean "lightroom-cache" { Remove-Item "C:\Users\*\AppData\Local\Adobe\Lightroom\*\Cache\*" -Recurse -Force -EA 0 }
Clean "indesign-recovery" { Remove-Item "C:\Users\*\AppData\Local\Adobe\InDesign\*\Caches\*" -Recurse -Force -EA 0 }
Clean "acrobat-cache" { Remove-Item "C:\Users\*\AppData\Local\Adobe\Acrobat\*\Cache\*" -Recurse -Force -EA 0 }
# OBS Studio
Clean "obs-logs" { Remove-Item "C:\Users\*\AppData\Roaming\obs-studio\logs\*" -Recurse -Force -EA 0 }
Clean "obs-crash" { Remove-Item "C:\Users\*\AppData\Roaming\obs-studio\crashes\*" -Recurse -Force -EA 0 }
Clean "obs-profiler" { Remove-Item "C:\Users\*\AppData\Roaming\obs-studio\profiler_data\*" -Recurse -Force -EA 0 }
Clean "obs-updates" { Remove-Item "C:\Users\*\AppData\Roaming\obs-studio\updates\*" -Recurse -Force -EA 0 }
# VLC
Clean "vlc-cache" { Remove-Item "C:\Users\*\AppData\Roaming\vlc\art\*" -Recurse -Force -EA 0 }
Clean "vlc-crashlog" { Remove-Item "C:\Users\*\AppData\Roaming\vlc\crashlog*.txt" -Force -EA 0 }
# Blender
Clean "blender-cache" { Remove-Item "C:\Users\*\AppData\Roaming\Blender Foundation\Blender\*\cache\*" -Recurse -Force -EA 0 }
Clean "blender-scripts" { Remove-Item "C:\Users\*\AppData\Roaming\Blender Foundation\Blender\*\scripts\presets\*\.tmp" -Force -EA 0 }
Clean "blender-temp" { Remove-Item "C:\Users\*\AppData\Local\Temp\blender_*" -Recurse -Force -EA 0 }
# Unity
Clean "unity-cache" { Remove-Item "C:\Users\*\AppData\Local\Unity\cache\*" -Recurse -Force -EA 0 }
Clean "unity-logs" { Remove-Item "C:\Users\*\AppData\Local\Unity\Editor\*" -Recurse -Force -EA 0 }
Clean "unity-asset-store" { Remove-Item "C:\Users\*\AppData\Roaming\Unity\Asset Store-5.x\*" -Recurse -Force -EA 0 }
Clean "unity-shader-cache" { Remove-Item "C:\Users\*\AppData\Local\Unity\ShaderCache\*" -Recurse -Force -EA 0 }
# Unreal Engine
Clean "unreal-deriveddata" { Remove-Item "C:\Users\*\AppData\Local\UnrealEngine\*\DerivedDataCache\*" -Recurse -Force -EA 0 }
Clean "unreal-logs" { Remove-Item "C:\Users\*\AppData\Local\UnrealEngine\*\Saved\Logs\*" -Recurse -Force -EA 0 }
Clean "unreal-crash" { Remove-Item "C:\Users\*\AppData\Local\UnrealEngine\*\Saved\CrashReports\*" -Recurse -Force -EA 0 }
# DaVinci Resolve
Clean "davinci-cache" { Remove-Item "C:\Users\*\AppData\Roaming\Blackmagic Design\DaVinci Resolve\CacheClip\*" -Recurse -Force -EA 0 }
Clean "davinci-logs" { Remove-Item "C:\Users\*\AppData\Roaming\Blackmagic Design\DaVinci Resolve\logs\*" -Recurse -Force -EA 0 }
# GIMP
Clean "gimp-cache" { Remove-Item "C:\Users\*\AppData\Roaming\GIMP\*\cache\*" -Recurse -Force -EA 0 }
Clean "gimp-tmp" { Remove-Item "C:\Users\*\AppData\Roaming\GIMP\*\tmp\*" -Recurse -Force -EA 0 }
# Audacity
Clean "audacity-temp" { Remove-Item "C:\Users\*\AppData\Local\Temp\audacity_temp_*" -Recurse -Force -EA 0 }
# HandBrake
Clean "handbrake-logs" { Remove-Item "C:\Users\*\AppData\Roaming\HandBrake\logs\*" -Recurse -Force -EA 0 }
# ImageMagick
Clean "imagemagick-cache" { Remove-Item "C:\Users\*\AppData\Local\ImageMagick\*" -Recurse -Force -EA 0 }
# FFmpeg logs
Clean "ffmpeg-temp" { Remove-Item "C:\Users\*\AppData\Local\Temp\ffmpeg*" -Force -EA 0 }
# Figma
Clean "figma-cache" { Remove-Item "C:\Users\*\AppData\Local\Figma\Cache\*" -Recurse -Force -EA 0 }
Clean "figma-gpucache" { Remove-Item "C:\Users\*\AppData\Local\Figma\GPUCache\*" -Recurse -Force -EA 0 }
Clean "figma-logs" { Remove-Item "C:\Users\*\AppData\Local\Figma\logs\*" -Recurse -Force -EA 0 }
# Canva
Clean "canva-cache" { Remove-Item "C:\Users\*\AppData\Local\Canva\Cache\*" -Recurse -Force -EA 0 }
# iTunes
Clean "itunes-cache" { Remove-Item "C:\Users\*\AppData\Local\Apple Computer\iTunes\*Cache*" -Recurse -Force -EA 0 }
Clean "itunes-temp" { Remove-Item "C:\Users\*\AppData\Local\Apple Computer\iTunes\Temp\*" -Recurse -Force -EA 0 }
Clean "apple-logs" { Remove-Item "C:\Users\*\AppData\Local\Apple Computer\Logs\*" -Recurse -Force -EA 0 }

# ============================================================================
# PHASE 17: CLOUD STORAGE & PRODUCTIVITY (40 operations)
# ============================================================================
Write-Host "`n[PHASE 17/20] CLOUD STORAGE & PRODUCTIVITY" -ForegroundColor White
# OneDrive
Clean "onedrive-logs" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\OneDrive\logs\*" -Recurse -Force -EA 0 }
Clean "onedrive-cache" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\OneDrive\cache\*" -Recurse -Force -EA 0 }
Clean "onedrive-setup" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\OneDrive\setup\*" -Recurse -Force -EA 0 }
Clean "onedrive-standalone" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\OneDrive\StandaloneUpdater\*" -Recurse -Force -EA 0 }
Clean "onedrive-telemetry" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\OneDrive\*\Telemetry\*" -Recurse -Force -EA 0 }
# Dropbox
Clean "dropbox-cache" { Remove-Item "C:\Users\*\AppData\Local\Dropbox\*\cache\*" -Recurse -Force -EA 0 }
Clean "dropbox-logs" { Remove-Item "C:\Users\*\AppData\Local\Dropbox\logs\*" -Recurse -Force -EA 0 }
Clean "dropbox-crash" { Remove-Item "C:\Users\*\AppData\Local\Dropbox\CrashReports\*" -Recurse -Force -EA 0 }
Clean "dropbox-temp" { Remove-Item "C:\Users\*\AppData\Local\Dropbox\temp\*" -Recurse -Force -EA 0 }
# Google Drive
Clean "gdrive-cache" { Remove-Item "C:\Users\*\AppData\Local\Google\DriveFS\*\content_cache\*" -Recurse -Force -EA 0 }
Clean "gdrive-logs" { Remove-Item "C:\Users\*\AppData\Local\Google\DriveFS\Logs\*" -Recurse -Force -EA 0 }
Clean "gdrive-metadata" { Remove-Item "C:\Users\*\AppData\Local\Google\DriveFS\*\metadata_sqlite_db*" -Force -EA 0 }
Clean "gdrive-temp" { Remove-Item "C:\Users\*\AppData\Local\Google\DriveFS\Temp\*" -Recurse -Force -EA 0 }
# iCloud
Clean "icloud-cache" { Remove-Item "C:\Users\*\AppData\Local\Apple Inc\iCloud\*\Cache\*" -Recurse -Force -EA 0 }
Clean "icloud-logs" { Remove-Item "C:\Users\*\AppData\Local\Apple Inc\iCloud\Logs\*" -Recurse -Force -EA 0 }
# Box
Clean "box-cache" { Remove-Item "C:\Users\*\AppData\Local\Box\Box\cache\*" -Recurse -Force -EA 0 }
Clean "box-logs" { Remove-Item "C:\Users\*\AppData\Local\Box\Box\logs\*" -Recurse -Force -EA 0 }
# pCloud
Clean "pcloud-cache" { Remove-Item "C:\Users\*\AppData\Local\pCloud\Cache\*" -Recurse -Force -EA 0 }
# Notion
Clean "notion-cache" { Remove-Item "C:\Users\*\AppData\Roaming\Notion\Cache\*" -Recurse -Force -EA 0 }
Clean "notion-gpucache" { Remove-Item "C:\Users\*\AppData\Roaming\Notion\GPUCache\*" -Recurse -Force -EA 0 }
Clean "notion-logs" { Remove-Item "C:\Users\*\AppData\Roaming\Notion\logs\*" -Recurse -Force -EA 0 }
# Obsidian
Clean "obsidian-cache" { Remove-Item "C:\Users\*\AppData\Roaming\obsidian\Cache\*" -Recurse -Force -EA 0 }
Clean "obsidian-gpucache" { Remove-Item "C:\Users\*\AppData\Roaming\obsidian\GPUCache\*" -Recurse -Force -EA 0 }
# Evernote
Clean "evernote-cache" { Remove-Item "C:\Users\*\AppData\Local\Evernote\Evernote\Cache\*" -Recurse -Force -EA 0 }
Clean "evernote-logs" { Remove-Item "C:\Users\*\AppData\Local\Evernote\Evernote\logs\*" -Recurse -Force -EA 0 }
# OneNote
Clean "onenote-cache" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\OneNote\*\cache\*" -Recurse -Force -EA 0 }
Clean "onenote-backup" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\OneNote\*\Backup\*" -Recurse -Force -EA 0 }
# Office
Clean "office-cache" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Office\*\OfficeFileCache\*" -Recurse -Force -EA 0 }
Clean "office-upload" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Office\*\UnsavedFiles\*" -Recurse -Force -EA 0 }
Clean "office-webcache" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Office\16.0\Wef\*" -Recurse -Force -EA 0 }
Clean "outlook-cache" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Outlook\RoamCache\*" -Recurse -Force -EA 0 }
Clean "outlook-offline" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Outlook\Offline Address Books\*" -Recurse -Force -EA 0 }
# GitHub Desktop
Clean "github-cache" { Remove-Item "C:\Users\*\AppData\Local\GitHubDesktop\Cache\*" -Recurse -Force -EA 0 }
Clean "github-logs" { Remove-Item "C:\Users\*\AppData\Local\GitHubDesktop\logs\*" -Recurse -Force -EA 0 }
# Postman
Clean "postman-cache" { Remove-Item "C:\Users\*\AppData\Local\Postman\Cache\*" -Recurse -Force -EA 0 }
Clean "postman-logs" { Remove-Item "C:\Users\*\AppData\Local\Postman\logs\*" -Recurse -Force -EA 0 }
# Insomnia
Clean "insomnia-cache" { Remove-Item "C:\Users\*\AppData\Roaming\Insomnia\Cache\*" -Recurse -Force -EA 0 }
Clean "insomnia-logs" { Remove-Item "C:\Users\*\AppData\Roaming\Insomnia\logs\*" -Recurse -Force -EA 0 }

# ============================================================================
# PHASE 18: WINDOWS STORE & UWP APPS (35 operations)
# ============================================================================
Write-Host "`n[PHASE 18/20] WINDOWS STORE & UWP APPS" -ForegroundColor White
Clean "store-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.WindowsStore_*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "store-temp" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.WindowsStore_*\TempState\*" -Recurse -Force -EA 0 }
Clean "photos-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.Windows.Photos_*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "photos-temp" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.Windows.Photos_*\TempState\*" -Recurse -Force -EA 0 }
Clean "calculator-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.WindowsCalculator_*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "camera-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.WindowsCamera_*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "maps-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.WindowsMaps_*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "maps-temp" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.WindowsMaps_*\TempState\*" -Recurse -Force -EA 0 }
Clean "news-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.BingNews_*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "weather-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.BingWeather_*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "weather-temp" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.BingWeather_*\TempState\*" -Recurse -Force -EA 0 }
Clean "alarms-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.WindowsAlarms_*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "mail-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\microsoft.windowscommunicationsapps_*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "mail-temp" { Remove-Item "C:\Users\*\AppData\Local\Packages\microsoft.windowscommunicationsapps_*\TempState\*" -Recurse -Force -EA 0 }
Clean "calendar-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.OutlookForWindows_*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "people-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.People_*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "feedback-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.WindowsFeedbackHub_*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "sticky-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.MicrosoftStickyNotes_*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "todo-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.Todos_*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "your-phone-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.YourPhone_*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "your-phone-temp" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.YourPhone_*\TempState\*" -Recurse -Force -EA 0 }
Clean "cortana-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.549981C3F5F10_*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "clipchamp-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\Clipchamp.Clipchamp_*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "terminal-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.WindowsTerminal_*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "terminal-temp" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.WindowsTerminal_*\TempState\*" -Recurse -Force -EA 0 }
Clean "snip-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.ScreenSketch_*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "paint-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.Paint_*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "notepad-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.WindowsNotepad_*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "notepad-temp" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.WindowsNotepad_*\TempState\*" -Recurse -Force -EA 0 }
Clean "clock-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.WindowsClock_*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "sound-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.WindowsSoundRecorder_*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "movies-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.ZuneVideo_*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "music-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.ZuneMusic_*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "getstarted-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.Getstarted_*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "office-uwp-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.MicrosoftOfficeHub_*\LocalCache\*" -Recurse -Force -EA 0 }

# ============================================================================
# PHASE 19: PROGRAMDATA & MISC SYSTEM (45 operations)
# ============================================================================
Write-Host "`n[PHASE 19/20] PROGRAMDATA & MISC SYSTEM" -ForegroundColor White
Clean "pd-wer" { Remove-Item "C:\ProgramData\Microsoft\Windows\WER\*" -Recurse -Force -EA 0 }
Clean "pd-wer-queue" { Remove-Item "C:\ProgramData\Microsoft\Windows\WER\ReportQueue\*" -Recurse -Force -EA 0 }
Clean "pd-wer-archive" { Remove-Item "C:\ProgramData\Microsoft\Windows\WER\ReportArchive\*" -Recurse -Force -EA 0 }
Clean "pd-search" { Remove-Item "C:\ProgramData\Microsoft\Search\Data\Applications\Windows\*.log" -Force -EA 0 }
Clean "pd-diagnosis" { Remove-Item "C:\ProgramData\Microsoft\Diagnosis\*" -Recurse -Force -EA 0 }
Clean "pd-diagtriggers" { Remove-Item "C:\ProgramData\Microsoft\Diagnosis\DownloadedSettings\*" -Recurse -Force -EA 0 }
Clean "pd-usoshared" { Remove-Item "C:\ProgramData\USOShared\Logs\*" -Recurse -Force -EA 0 }
Clean "pd-usoprivate" { Remove-Item "C:\ProgramData\USOPrivate\UpdateStore\*" -Recurse -Force -EA 0 }
Clean "pd-nvidia-dl" { Remove-Item "C:\ProgramData\NVIDIA Corporation\Downloader\*" -Recurse -Force -EA 0 }
Clean "pd-nvidia-updatus" { Remove-Item "C:\ProgramData\NVIDIA\Updatus\*" -Recurse -Force -EA 0 }
Clean "pd-nvidia-geforce" { Remove-Item "C:\ProgramData\NVIDIA Corporation\GeForce Experience\Update\*" -Recurse -Force -EA 0 }
Clean "pd-nvidia-logs" { Remove-Item "C:\ProgramData\NVIDIA Corporation\NvProfileUpdater\*" -Recurse -Force -EA 0 }
Clean "pd-amd-logs" { Remove-Item "C:\ProgramData\AMD\Logs\*" -Recurse -Force -EA 0 }
Clean "pd-pkgcache" { Remove-Item "C:\ProgramData\Package Cache\*" -Recurse -Force -EA 0 }
Clean "pd-choco-logs" { Remove-Item "C:\ProgramData\chocolatey\logs\*" -Recurse -Force -EA 0 }
Clean "pd-choco-temp" { Remove-Item "C:\ProgramData\chocolatey\tmp\*" -Recurse -Force -EA 0 }
Clean "pd-choco-cache" { Remove-Item "C:\ProgramData\chocolatey\.cache\*" -Recurse -Force -EA 0 }
Clean "pd-eset" { Remove-Item "C:\Users\*\AppData\Local\ESET\ESETOnlineScanner\*" -Recurse -Force -EA 0 }
Clean "pd-kaspersky" { Remove-Item "C:\KVRT2020_Data\*" -Recurse -Force -EA 0 }
Clean "pd-adw" { Remove-Item "C:\AdwCleaner\*" -Recurse -Force -EA 0 }
Clean "pd-defender-scans" { Remove-Item "C:\ProgramData\Microsoft\Windows Defender\Scans\*" -Recurse -Force -EA 0 }
Clean "pd-sophos" { Remove-Item "C:\ProgramData\Sophos\*\Logs\*" -Recurse -Force -EA 0 }
Clean "pd-malwarebytes" { Remove-Item "C:\ProgramData\Malwarebytes\MBAMService\logs\*" -Recurse -Force -EA 0 }
Clean "pd-ccleanerlogs" { Remove-Item "C:\ProgramData\CCleaner\*" -Recurse -Force -EA 0 }
Clean "pd-crashplan" { Remove-Item "C:\ProgramData\CrashPlan\log\*" -Recurse -Force -EA 0 }
Clean "pd-intel-logs" { Remove-Item "C:\ProgramData\Intel\ShaderCache\*" -Recurse -Force -EA 0 }
Clean "pd-windowsapps-temp" { Remove-Item "C:\ProgramData\Microsoft\Windows\AppRepository\*.tmp" -Force -EA 0 }
Clean "pd-dotnet" { Remove-Item "C:\ProgramData\Microsoft\NetFramework\*\v*\Cache\*" -Recurse -Force -EA 0 }
Clean "pd-windows-cache" { Remove-Item "C:\ProgramData\Microsoft\Windows\Caches\*" -Recurse -Force -EA 0 }
Clean "pd-windows-netcache" { Remove-Item "C:\ProgramData\Microsoft\Windows\NetCache\*" -Recurse -Force -EA 0 }
Clean "pd-windows-update" { Remove-Item "C:\ProgramData\Microsoft\Windows\Update\*" -Recurse -Force -EA 0 }
Clean "pd-hyper-v" { Remove-Item "C:\ProgramData\Microsoft\Windows\Hyper-V\*\Snapshots\*" -Recurse -Force -EA 0 }
Clean "pd-sandbox" { Remove-Item "C:\ProgramData\Microsoft\Windows\Containers\Sandboxes\*" -Recurse -Force -EA 0 }
Clean "pd-rdp-cache" { Remove-Item "C:\ProgramData\Microsoft\Windows\RemoteDesktopCacheStore\*" -Recurse -Force -EA 0 }
Clean "pd-gppolicy" { Remove-Item "C:\ProgramData\Microsoft\Group Policy\History\*" -Recurse -Force -EA 0 }
Clean "pd-netassembly" { Remove-Item "C:\Windows\Microsoft.NET\Framework64\v*\Temporary ASP.NET Files\*" -Recurse -Force -EA 0 }
Clean "pd-netassembly32" { Remove-Item "C:\Windows\Microsoft.NET\Framework\v*\Temporary ASP.NET Files\*" -Recurse -Force -EA 0 }
Clean "winget-cache" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\WinGet\Packages\*" -Recurse -Force -EA 0 }
Clean "winget-logs" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\WinGet\Logs\*" -Recurse -Force -EA 0 }
Clean "scoop-cache" { Remove-Item "C:\Users\*\scoop\cache\*" -Recurse -Force -EA 0 }
Clean "powershell-history" { Remove-Item "C:\Users\*\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadLine\*" -Recurse -Force -EA 0 }
Clean "powershell-modules-temp" { Remove-Item "C:\Users\*\Documents\PowerShell\Modules\*\*.tmp" -Force -EA 0 }
Clean "wsl-logs" { Remove-Item "C:\Users\*\AppData\Local\Packages\*CanonicalGroupLimited*\LocalState\rootfs\tmp\*" -Recurse -Force -EA 0 }
Clean "terminal-state" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Windows Terminal\state.json" -Force -EA 0 }

# ============================================================================
# PHASE 20: ADDITIONAL SYSTEM CLEANUP (80+ operations)
# ============================================================================
Write-Host "`n[PHASE 20/21] ADDITIONAL SYSTEM CLEANUP" -ForegroundColor White
# Windows Prefetch
Clean "prefetch-all" { Remove-Item "C:\Windows\Prefetch\*" -Force -EA 0 }
Clean "prefetch-pf" { Remove-Item "C:\Windows\Prefetch\*.pf" -Force -EA 0 }
Clean "prefetch-db" { Remove-Item "C:\Windows\Prefetch\PfSvPerfStats.bin" -Force -EA 0 }
# Recent Items
Clean "recent-items" { Remove-Item "C:\Users\*\AppData\Roaming\Microsoft\Windows\Recent\*" -Recurse -Force -EA 0 }
Clean "recent-auto" { Remove-Item "C:\Users\*\AppData\Roaming\Microsoft\Windows\Recent\AutomaticDestinations\*" -Force -EA 0 }
Clean "recent-custom" { Remove-Item "C:\Users\*\AppData\Roaming\Microsoft\Windows\Recent\CustomDestinations\*" -Force -EA 0 }
# Jump Lists
Clean "jumplist-auto" { Remove-Item "C:\Users\*\AppData\Roaming\Microsoft\Windows\Recent\AutomaticDestinations\*.automaticDestinations-ms" -Force -EA 0 }
Clean "jumplist-custom" { Remove-Item "C:\Users\*\AppData\Roaming\Microsoft\Windows\Recent\CustomDestinations\*.customDestinations-ms" -Force -EA 0 }
# Notification Cache
Clean "notification-cache" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Windows\Notifications\*" -Recurse -Force -EA 0 }
Clean "notification-wpn" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Windows\Notifications\wpnidm\*" -Recurse -Force -EA 0 }
# Clipboard History
Clean "clipboard-history" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Windows\Clipboard\*" -Recurse -Force -EA 0 }
# Timeline/Activity History
Clean "activity-history" { Remove-Item "C:\Users\*\AppData\Local\ConnectedDevicesPlatform\*\ActivitiesCache.db*" -Force -EA 0 }
Clean "activity-history2" { Remove-Item "C:\Users\*\AppData\Local\ConnectedDevicesPlatform\*\*.db" -Force -EA 0 }
# Certificate Cache
Clean "cert-cache" { Remove-Item "C:\Users\*\AppData\LocalLow\Microsoft\CryptnetUrlCache\*" -Recurse -Force -EA 0 }
Clean "cert-content" { Remove-Item "C:\Users\*\AppData\LocalLow\Microsoft\CryptnetUrlCache\Content\*" -Force -EA 0 }
Clean "cert-metadata" { Remove-Item "C:\Users\*\AppData\LocalLow\Microsoft\CryptnetUrlCache\MetaData\*" -Force -EA 0 }
# Windows Search Index Temp
Clean "search-temp" { Remove-Item "C:\ProgramData\Microsoft\Search\Data\Applications\Windows\tmp.edb" -Force -EA 0 }
Clean "search-logs" { Remove-Item "C:\ProgramData\Microsoft\Search\Data\Applications\Windows\*.log" -Force -EA 0 }
Clean "search-cidump" { Remove-Item "C:\ProgramData\Microsoft\Search\Data\Applications\Windows\*.cidump" -Force -EA 0 }
# Diagnostic Data Viewer Cache
Clean "diagnostic-viewer" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.DiagnosticDataViewer_*\LocalCache\*" -Recurse -Force -EA 0 }
# Windows.old Remnants
Clean "windows-old" { Remove-Item "C:\Windows.old\*" -Recurse -Force -EA 0 }
Clean "windows-bt" { Remove-Item "C:\`$Windows.~BT\*" -Recurse -Force -EA 0 }
Clean "windows-ws" { Remove-Item "C:\`$Windows.~WS\*" -Recurse -Force -EA 0 }
Clean "windows-recycleold" { Remove-Item "C:\`$WINDOWS.~Q\*" -Recurse -Force -EA 0 }
# Windows Installer Cleanup
Clean "installer-temp" { Remove-Item "C:\Windows\Installer\*.tmp" -Force -EA 0 }
Clean "installer-patch" { Remove-Item "C:\Windows\Installer\`$PatchCache`$\*" -Recurse -Force -EA 0 }
Clean "installer-config" { Remove-Item "C:\Config.Msi\*" -Recurse -Force -EA 0 }
# DISM Logs
Clean "dism-logs-all" { Remove-Item "C:\Windows\Logs\DISM\dism.log*" -Force -EA 0 }
# SFC Logs
Clean "sfc-logs" { Remove-Item "C:\Windows\Logs\SFC\*" -Force -EA 0 }
# Windows Upgrade Logs
Clean "upgrade-logs" { Remove-Item "C:\Windows\Logs\MoSetup\*" -Force -EA 0 }
# Superfetch
Clean "superfetch-cache" { Remove-Item "C:\Windows\Prefetch\AgAppLaunch.db" -Force -EA 0 }
Clean "superfetch-globs" { Remove-Item "C:\Windows\Prefetch\Ag*.db" -Force -EA 0 }
Clean "superfetch-pfs" { Remove-Item "C:\Windows\Prefetch\PfSvPerfStats.bin" -Force -EA 0 }
# Windows Update Cleanup - Additional
Clean "wu-download" { Remove-Item "C:\Windows\SoftwareDistribution\Download\*" -Recurse -Force -EA 0 }
Clean "wu-datastore" { Remove-Item "C:\Windows\SoftwareDistribution\DataStore\*" -Recurse -Force -EA 0 }
Clean "wu-postren" { Remove-Item "C:\Windows\SoftwareDistribution\PostRebootEventCache.V2\*" -Recurse -Force -EA 0 }
# Compatibility Assistant
Clean "compat-assistant" { Remove-Item "C:\ProgramData\Microsoft\Windows\AppCompat\*" -Recurse -Force -EA 0 }
Clean "compat-appraiser" { Remove-Item "C:\ProgramData\Microsoft\Windows\Appraiser\*" -Recurse -Force -EA 0 }
# WDI Logs
Clean "wdi-perf" { Remove-Item "C:\Windows\System32\WDI\LogFiles\BootCKCL.etl" -Force -EA 0 }
Clean "wdi-startup" { Remove-Item "C:\Windows\System32\WDI\LogFiles\StartupInfo\*" -Recurse -Force -EA 0 }
Clean "wdi-shutdown" { Remove-Item "C:\Windows\System32\WDI\LogFiles\ShutdownCKCL.etl" -Force -EA 0 }
# Network Profile Cache
Clean "network-profiles" { Remove-Item "C:\ProgramData\Microsoft\WlanSvc\Profiles\*" -Recurse -Force -EA 0 }
Clean "network-logs" { Remove-Item "C:\ProgramData\Microsoft\WlanSvc\Logs\*" -Recurse -Force -EA 0 }
# User Profile Temp Files
Clean "profile-temp" { Remove-Item "C:\Users\*\*.tmp" -Force -EA 0 }
Clean "profile-log" { Remove-Item "C:\Users\*\*.log" -Force -EA 0 }
Clean "profile-bak" { Remove-Item "C:\Users\*\*.bak" -Force -EA 0 }
# AppX Package Temp
Clean "appx-temp" { Remove-Item "C:\Users\*\AppData\Local\Temp\*appx*" -Recurse -Force -EA 0 }
Clean "appx-staging" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Windows\AppPackages\*" -Recurse -Force -EA 0 }
# DirectX Shader Cache (User)
Clean "dx-shadercache-user" { Remove-Item "C:\Users\*\AppData\LocalLow\AMD\DXCache\*" -Recurse -Force -EA 0 }
Clean "dx-shadercache-intel" { Remove-Item "C:\Users\*\AppData\LocalLow\Intel\ShaderCache\*" -Recurse -Force -EA 0 }
Clean "dx-shadercache-nvidia" { Remove-Item "C:\Users\*\AppData\LocalLow\NVIDIA\PerDriverVersion\DXCache\*" -Recurse -Force -EA 0 }
# GL Shader Cache
Clean "gl-shadercache-amd" { Remove-Item "C:\Users\*\AppData\LocalLow\AMD\GLCache\*" -Recurse -Force -EA 0 }
Clean "gl-shadercache-nvidia" { Remove-Item "C:\Users\*\AppData\Local\NVIDIA\GLCache\*" -Recurse -Force -EA 0 }
Clean "gl-shadercache-intel" { Remove-Item "C:\Users\*\AppData\LocalLow\Intel\GLCache\*" -Recurse -Force -EA 0 }
# System Error Reports
Clean "system-error-reports" { Remove-Item "C:\Windows\System32\config\systemprofile\AppData\Local\Microsoft\Windows\WER\*" -Recurse -Force -EA 0 }
# Font Cache Extended
Clean "fontcache-user" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Windows\Fonts\*.cache*" -Force -EA 0 }
# D3D Shader Cache System
Clean "d3d-cache-system" { Remove-Item "C:\Windows\System32\config\systemprofile\AppData\LocalLow\Microsoft\DirectX\ShaderCache\*" -Recurse -Force -EA 0 }
# WebCache Extended
Clean "webcache-v01" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Windows\WebCache\V01*" -Force -EA 0 }
Clean "webcache-all" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Windows\WebCache\*.log" -Force -EA 0 }
# Credential Manager Temp
Clean "credential-temp" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Credentials\*.tmp" -Force -EA 0 }
Clean "credential-protect" { Remove-Item "C:\Users\*\AppData\Roaming\Microsoft\Protect\*\*.tmp" -Force -EA 0 }
# Language Model Cache
Clean "language-model" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\LanguageModel\*" -Recurse -Force -EA 0 }
# Input Personalization
Clean "input-personal" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\InputPersonalization\*" -Recurse -Force -EA 0 }
# Narrator Data
Clean "narrator-data" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Narrator\*" -Recurse -Force -EA 0 }
# File History Temp
Clean "filehistory-temp" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Windows\FileHistory\Configuration\*.tmp" -Force -EA 0 }
# Touch Keyboard
Clean "touch-keyboard" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\InputMethod\*\*\*Cache*" -Recurse -Force -EA 0 }
# INetCache Extended
Clean "inetcache-content" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Windows\INetCache\Content.IE5\*" -Recurse -Force -EA 0 }
Clean "inetcache-lo" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Windows\INetCache\Low\Content.IE5\*" -Recurse -Force -EA 0 }
# Windows App Runtime
Clean "winappruntime-temp" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\WindowsApps\*.tmp" -Force -EA 0 }
# Gaming Services Cache
Clean "gaming-services" { Remove-Item "C:\ProgramData\Microsoft\Windows\GamingServices\*\Temp\*" -Recurse -Force -EA 0 }
# Radeon Cache
Clean "radeon-cache" { Remove-Item "C:\Users\*\AppData\Local\AMD\CN\*" -Recurse -Force -EA 0 }
Clean "radeon-dx9" { Remove-Item "C:\Users\*\AppData\Local\AMD\DX9Cache\*" -Recurse -Force -EA 0 }
Clean "radeon-ogl" { Remove-Item "C:\Users\*\AppData\Local\AMD\OglCache\*" -Recurse -Force -EA 0 }
# GeForce Experience
Clean "gfe-cache" { Remove-Item "C:\Users\*\AppData\Local\NVIDIA Corporation\GeForce Experience\CefCache\*" -Recurse -Force -EA 0 }
Clean "gfe-thumbs" { Remove-Item "C:\Users\*\AppData\Local\NVIDIA Corporation\GeForce Experience\Thumbnails\*" -Recurse -Force -EA 0 }
# Windows Sandbox Temp
Clean "sandbox-temp" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.Windows.ContentDeliveryManager_*\LocalState\StagedAssets\*" -Recurse -Force -EA 0 }

# ============================================================================
# PHASE 21: ROOT CLEANUP & FINAL OPS (47 operations)
# ============================================================================
Write-Host "`n[PHASE 21/21] ROOT CLEANUP & FINAL OPS" -ForegroundColor White
Clean "root-esd" { Remove-Item "C:\ESD\*" -Recurse -Force -EA 0 }
Clean "root-swsetup" { Remove-Item "C:\swsetup\*" -Recurse -Force -EA 0 }
Clean "root-amd" { Remove-Item "C:\AMD\*" -Recurse -Force -EA 0 }
Clean "root-intel" { Remove-Item "C:\Intel\*" -Recurse -Force -EA 0 }
Clean "root-nvidia" { Remove-Item "C:\NVIDIA\*" -Recurse -Force -EA 0 }
Clean "root-dell" { Remove-Item "C:\dell\*" -Recurse -Force -EA 0 }
Clean "root-hp" { Remove-Item "C:\HP\*" -Recurse -Force -EA 0 }
Clean "root-lenovo" { Remove-Item "C:\Lenovo\*" -Recurse -Force -EA 0 }
Clean "root-asus" { Remove-Item "C:\ASUS\*" -Recurse -Force -EA 0 }
Clean "root-acer" { Remove-Item "C:\Acer\*" -Recurse -Force -EA 0 }
Clean "root-drivers" { Remove-Item "C:\drivers\*" -Recurse -Force -EA 0 }
Clean "root-temp" { Remove-Item "C:\temp\*" -Recurse -Force -EA 0 }
Clean "root-tmp" { Remove-Item "C:\tmp\*" -Recurse -Force -EA 0 }
Clean "root-inetpub" { Remove-Item "C:\inetpub\logs\*" -Recurse -Force -EA 0 }
Clean "root-logs" { Get-ChildItem "C:\*.log" -Force -EA 0 | Remove-Item -Force -EA 0 }
Clean "root-txt" { Get-ChildItem "C:\*.txt" -Force -EA 0 | Where-Object {$_.Name -match 'log|install|setup|debug'} | Remove-Item -Force -EA 0 }
Clean "root-dmp" { Get-ChildItem "C:\*.dmp" -Force -EA 0 | Remove-Item -Force -EA 0 }
Clean "root-tmp-files" { Get-ChildItem "C:\*.tmp" -Force -EA 0 | Remove-Item -Force -EA 0 }
Clean "root-bak" { Get-ChildItem "C:\*.bak" -Force -EA 0 | Remove-Item -Force -EA 0 }
Clean "root-recovery" { Remove-Item "C:\Recovery\*" -Recurse -Force -EA 0 }
Clean "root-msocache" { Remove-Item "C:\MSOCache\*" -Recurse -Force -EA 0 }
Clean "root-perf" { Remove-Item "C:\PerfLogs\*" -Recurse -Force -EA 0 }
Clean "recycle-bin" { Clear-RecycleBin -Force -EA 0 }
Clean "event-app" { wevtutil cl Application 2>$null }
Clean "event-sec" { wevtutil cl Security 2>$null }
Clean "event-sys" { wevtutil cl System 2>$null }
Clean "event-setup" { wevtutil cl Setup 2>$null }
Clean "event-forwarded" { wevtutil cl ForwardedEvents 2>$null }
Clean "event-powershell" { wevtutil cl "Windows PowerShell" 2>$null }
Clean "delivery-opt" { Delete-DeliveryOptimizationCache -Force -EA 0 }
Clean "shadow-copies" { vssadmin delete shadows /all /quiet 2>$null }
Clean "dns-cache" { ipconfig /flushdns 2>$null }
Clean "arp-cache" { netsh interface ip delete arpcache 2>$null }
Clean "thumbnail-cache" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Windows\Explorer\thumbcache_*" -Force -EA 0 }
Clean "icon-cache" {
    taskkill /IM explorer.exe /F 2>$null
    Remove-Item "C:\Users\*\AppData\Local\Microsoft\Windows\Explorer\iconcache*" -Force -EA 0
    Remove-Item "C:\Users\*\AppData\Local\IconCache.db" -Force -EA 0
    ie4uinit.exe -ClearIconCache 2>$null
    Start-Sleep 2
    Start-Process explorer 2>$null
}
Clean "font-cache" {
    net stop FontCache 2>$null
    Remove-Item "C:\Windows\ServiceProfiles\LocalService\AppData\Local\FontCache\*" -Force -EA 0
    net start FontCache 2>$null
}
Clean "bits-cache" {
    net stop bits 2>$null
    Remove-Item "C:\ProgramData\Microsoft\Network\Downloader\qmgr*.dat" -Force -EA 0
    net start bits 2>$null
}
Clean "wsus-offline" { Remove-Item "C:\wsusoffline\*\client\software\*" -Recurse -Force -EA 0 }
Clean "compact-os" { compact /compactos:always 2>$null }
Clean "ngen-queue" { ngen.exe executeQueuedItems 2>$null }
Clean "fix-downloads-path" {
    New-Item -Path "F:\Downloads" -ItemType Directory -Force 2>$null
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "{374DE290-123F-4565-9164-39C4925E467B}" -Value "F:\Downloads" -EA 0
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" -Name "{374DE290-123F-4565-9164-39C4925E467B}" -Value "F:\Downloads" -EA 0
}
Clean "reset-quickaccess" {
    Remove-Item "$env:APPDATA\Microsoft\Windows\Recent\AutomaticDestinations\*" -Force -Recurse -EA 0
    Start-Sleep -Seconds 1
    $shell = New-Object -ComObject Shell.Application
    $folders = @("F:\backup\windowsapps","F:\backup\windowsapps\installed","F:\backup\windowsapps\install","F:\backup\windowsapps\profile","C:\users\micha\Videos","C:\games","F:\study","F:\backup","C:\Users\micha","F:\games")
    foreach ($folder in $folders) {
        if ($folder -like "C:\*") {
            if (($folder -notlike "*micha*") -and ($folder -ne "C:\games")) {
                $folder = $folder -replace "^C:", "F:"
            }
        }
        $ns = $shell.Namespace($folder)
        if ($ns) { $ns.Self.InvokeVerb("pintohome") }
    }
}
Clean "restart-explorer" {
    Get-Process explorer -EA 0 | Stop-Process -Force -EA 0
    Start-Sleep 1
    Start-Process explorer -EA 0
}

# Cleanup memory
[System.GC]::Collect()
[System.GC]::WaitForPendingFinalizers()

# Results
$elapsed = ((Get-Date) - $start).ToString('mm\:ss')
$endFree = [math]::Round(((Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'" -EA 0).FreeSpace/1GB),2)
$freed = [math]::Round($endFree - $startFree, 2)

Write-Host "`n=== MEGACLEAN 5X ULTRA COMPLETE ===" -ForegroundColor Magenta
Write-Host "Time: $elapsed | Freed: ${freed}GB | C: Now ${endFree}GB free" -ForegroundColor Cyan
Write-Host "Total operations: $script:total" -ForegroundColor Gray
Write-Host ""
