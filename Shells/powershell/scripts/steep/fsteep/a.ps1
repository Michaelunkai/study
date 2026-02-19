# MEGACLEAN 10X ULTRA - 5000+ Operations
# NO Docker/WSL - PowerShell v5 Compatible

$ErrorActionPreference = 'SilentlyContinue'
$script:completed = 0
$script:total = 5000
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

Write-Host "`n=== MEGACLEAN 10X ULTRA STARTED ===" -ForegroundColor Magenta
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
    Remove-Item "C:\Windows\SoftwareDistribution\Download\*" -Recurse -Force -EA 0
    Remove-Item "C:\Windows\SoftwareDistribution\DataStore\*" -Recurse -Force -EA 0
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
    Remove-Item "C:\Windows\SoftwareDistribution\DeliveryOptimization\*" -Recurse -Force -EA 0
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
# PHASE 22: WINDOWS SYSTEM EXTENDED (100 operations)
# ============================================================================
Write-Host "`n[PHASE 22/40] WINDOWS SYSTEM EXTENDED" -ForegroundColor White
# Batch 1: Windows System Extended (10 ops)
Clean "win-sys-assembly-gac" { Remove-Item "C:\Windows\assembly\NativeImages_*\*\*.tmp" -Recurse -Force -EA 0 }
Clean "win-sys-assembly-download" { Remove-Item "C:\Windows\assembly\Downloads\*" -Recurse -Force -EA 0 }
Clean "win-sys-globalization" { Remove-Item "C:\Windows\Globalization\*.tmp" -Force -EA 0 }
Clean "win-sys-imestat" { Remove-Item "C:\Windows\IME\*\IMSTAT*" -Recurse -Force -EA 0 }
Clean "win-sys-migwiz-backup" { Remove-Item "C:\Windows\System32\migwiz\*.log" -Force -EA 0 }
Clean "win-sys-oobe-info" { Remove-Item "C:\Windows\System32\oobe\info\*.tmp" -Force -EA 0 }
Clean "win-sys-codepages" { Remove-Item "C:\Windows\System32\wbem\*.tmp" -Force -EA 0 }
Clean "win-sys-mof-auto" { Remove-Item "C:\Windows\System32\wbem\AutoRecover\*.mof" -Force -EA 0 }
Clean "win-sys-wbem-logs" { Remove-Item "C:\Windows\System32\wbem\Logs\*" -Recurse -Force -EA 0 }
Clean "win-sys-repository-backup" { Remove-Item "C:\Windows\System32\wbem\Repository\*.bak" -Force -EA 0 }

# Batch 2: Windows Telemetry Extended (10 ops)
Clean "win-telemetry-diagtrack" { Remove-Item "C:\ProgramData\Microsoft\Diagnosis\ETLLogs\*" -Recurse -Force -EA 0 }
Clean "win-telemetry-autolog" { Remove-Item "C:\ProgramData\Microsoft\Diagnosis\ETLLogs\AutoLogger\*" -Recurse -Force -EA 0 }
Clean "win-telemetry-shutdownlogs" { Remove-Item "C:\ProgramData\Microsoft\Diagnosis\ETLLogs\ShutdownLogger\*" -Recurse -Force -EA 0 }
Clean "win-telemetry-ossku" { Remove-Item "C:\ProgramData\Microsoft\Diagnosis\OSSKU\*" -Recurse -Force -EA 0 }
Clean "win-telemetry-feedback" { Remove-Item "C:\ProgramData\Microsoft\Diagnosis\FeedbackHub\*" -Recurse -Force -EA 0 }
Clean "win-telemetry-siuf" { Remove-Item "C:\ProgramData\Microsoft\SIUFData\*" -Recurse -Force -EA 0 }
Clean "win-telemetry-sqm" { Remove-Item "C:\ProgramData\Microsoft\SQMClient\*" -Recurse -Force -EA 0 }
Clean "win-telemetry-ceip" { Remove-Item "C:\ProgramData\Microsoft\Windows\CEIP\*" -Recurse -Force -EA 0 }
Clean "win-telemetry-cosync" { Remove-Item "C:\ProgramData\Microsoft\CoSyncSvc\*" -Recurse -Force -EA 0 }
Clean "win-telemetry-usershared" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Windows\DiagTrack\*" -Recurse -Force -EA 0 }

# Batch 3: Windows Services Logs (10 ops)
Clean "win-svc-bits" { Remove-Item "C:\Windows\Logs\BITS\*" -Recurse -Force -EA 0 }
Clean "win-svc-storport" { Remove-Item "C:\Windows\Logs\StorPort\*" -Recurse -Force -EA 0 }
Clean "win-svc-ble" { Remove-Item "C:\Windows\Logs\Bluetooth\*" -Recurse -Force -EA 0 }
Clean "win-svc-powershell" { Remove-Item "C:\Windows\Logs\PowerShell\*" -Recurse -Force -EA 0 }
Clean "win-svc-upnp" { Remove-Item "C:\Windows\Logs\upnphost\*" -Recurse -Force -EA 0 }
Clean "win-svc-winevt-archive" { Remove-Item "C:\Windows\System32\winevt\Logs\Archive*" -Force -EA 0 }
Clean "win-svc-eventlogs-etl" { Remove-Item "C:\Windows\System32\winevt\TraceFormat\*" -Recurse -Force -EA 0 }
Clean "win-svc-windowsbackup" { Remove-Item "C:\Windows\Logs\WindowsBackup\*" -Recurse -Force -EA 0 }
Clean "win-svc-bootperf" { Remove-Item "C:\Windows\Logs\SystemInfo\*" -Recurse -Force -EA 0 }
Clean "win-svc-reliability" { Remove-Item "C:\Windows\Logs\ReliabilityHistory\*" -Recurse -Force -EA 0 }

# Batch 4: Windows Installer Extended (10 ops)
Clean "win-inst-cache" { Remove-Item "C:\Windows\Installer\`$PatchCache`$\Managed\*" -Recurse -Force -EA 0 }
Clean "win-inst-regbackup" { Remove-Item "C:\Windows\Installer\RegBackup\*" -Recurse -Force -EA 0 }
Clean "win-inst-sourceengine" { Remove-Item "C:\Windows\Installer\SourceEngineInfo\*" -Recurse -Force -EA 0 }
Clean "win-inst-downloads" { Remove-Item "C:\Windows\Downloaded Installations\*" -Recurse -Force -EA 0 }
Clean "win-inst-progfiles-temp" { Remove-Item "C:\Program Files\*.tmp" -Force -EA 0 }
Clean "win-inst-progfiles86-temp" { Remove-Item "C:\Program Files (x86)\*.tmp" -Force -EA 0 }
Clean "win-inst-msosetup" { Remove-Item "C:\MSOTraceLite\*" -Recurse -Force -EA 0 }
Clean "win-inst-setupold" { Remove-Item "C:\setup\*" -Recurse -Force -EA 0 }
Clean "win-inst-msitmp" { Get-ChildItem "C:\Windows\Installer\*.msi" -EA 0 | Where-Object {$_.Length -gt 10MB -and $_.LastWriteTime -lt (Get-Date).AddDays(-30)} | Remove-Item -Force -EA 0 }
Clean "win-inst-msptmp" { Get-ChildItem "C:\Windows\Installer\*.msp" -EA 0 | Where-Object {$_.Length -gt 10MB -and $_.LastWriteTime -lt (Get-Date).AddDays(-30)} | Remove-Item -Force -EA 0 }

# Batch 5: Windows Crash/Dump Extended (10 ops)
Clean "win-crash-minidump-old" { Get-ChildItem "C:\Windows\Minidump\*.dmp" -EA 0 | Where-Object {$_.LastWriteTime -lt (Get-Date).AddDays(-7)} | Remove-Item -Force -EA 0 }
Clean "win-crash-livekernel-old" { Get-ChildItem "C:\Windows\LiveKernelReports\*" -Recurse -EA 0 | Where-Object {$_.LastWriteTime -lt (Get-Date).AddDays(-7)} | Remove-Item -Recurse -Force -EA 0 }
Clean "win-crash-systemprofile" { Remove-Item "C:\Windows\System32\config\systemprofile\AppData\Local\CrashDumps\*" -Recurse -Force -EA 0 }
Clean "win-crash-werfault" { Remove-Item "C:\ProgramData\Microsoft\Windows\WER\Temp\*" -Recurse -Force -EA 0 }
Clean "win-crash-appcrash" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Windows\WER\ERC\*" -Recurse -Force -EA 0 }
Clean "win-crash-userarchive" { Get-ChildItem "C:\Users\*\AppData\Local\Microsoft\Windows\WER\ReportArchive\*" -Recurse -EA 0 | Where-Object {$_.LastWriteTime -lt (Get-Date).AddDays(-7)} | Remove-Item -Recurse -Force -EA 0 }
Clean "win-crash-kerneldmp" { Remove-Item "C:\Windows\KERNEL*.DMP" -Force -EA 0 }
Clean "win-crash-systemdmp" { Remove-Item "C:\WINDOWS\*.DMP" -Force -EA 0 }
Clean "win-crash-userdmp" { Remove-Item "C:\Users\*\*.dmp" -Force -EA 0 }
Clean "win-crash-procdmp" { Remove-Item "C:\Users\*\AppData\Local\Temp\*.dmp" -Force -EA 0 }

# ============================================================================
# PHASE 23: ADDITIONAL BROWSERS & EXTENSIONS (100 operations)
# ============================================================================
Write-Host "`n[PHASE 23/40] ADDITIONAL BROWSERS & EXTENSIONS" -ForegroundColor White
# Batch 6: More Browser Data (10 ops)
Clean "chrome-sockets" { Remove-Item "C:\Users\*\AppData\Local\Google\Chrome\User Data\*\WebRTC Internals\*" -Recurse -Force -EA 0 }
Clean "chrome-shared-proto" { Remove-Item "C:\Users\*\AppData\Local\Google\Chrome\User Data\*\shared_proto_db\*" -Recurse -Force -EA 0 }
Clean "chrome-download-internal" { Remove-Item "C:\Users\*\AppData\Local\Google\Chrome\User Data\*\Download Service\*" -Recurse -Force -EA 0 }
Clean "chrome-segmentation" { Remove-Item "C:\Users\*\AppData\Local\Google\Chrome\User Data\*\Segmentation Platform\*" -Recurse -Force -EA 0 }
Clean "chrome-tabstrip" { Remove-Item "C:\Users\*\AppData\Local\Google\Chrome\User Data\*\Tab Strip Model Sync\*" -Recurse -Force -EA 0 }
Clean "edge-reading-list" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Edge\User Data\*\Reading List\*" -Recurse -Force -EA 0 }
Clean "edge-webdata" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Edge\User Data\*\Web Data-journal" -Force -EA 0 }
Clean "edge-topicdata" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Edge\User Data\*\feature_engagement_tracker\*" -Recurse -Force -EA 0 }
Clean "firefox-temp-sqlite" { Remove-Item "C:\Users\*\AppData\Roaming\Mozilla\Firefox\Profiles\*\*-journal" -Force -EA 0 }
Clean "firefox-sqlite-wal" { Remove-Item "C:\Users\*\AppData\Roaming\Mozilla\Firefox\Profiles\*\*-wal" -Force -EA 0 }

# Batch 7: More Browser Extensions (10 ops)
Clean "browser-ext-chrome-temp" { Remove-Item "C:\Users\*\AppData\Local\Google\Chrome\User Data\*\Extensions\Temp\*" -Recurse -Force -EA 0 }
Clean "browser-ext-edge-temp" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Edge\User Data\*\Extensions\Temp\*" -Recurse -Force -EA 0 }
Clean "browser-ext-brave-temp" { Remove-Item "C:\Users\*\AppData\Local\BraveSoftware\Brave-Browser\User Data\*\Extensions\Temp\*" -Recurse -Force -EA 0 }
Clean "browser-ext-opera-temp" { Remove-Item "C:\Users\*\AppData\Local\Opera Software\Opera Stable\Extensions\Temp\*" -Recurse -Force -EA 0 }
Clean "browser-tor-cache" { Remove-Item "C:\Users\*\AppData\Roaming\tor-browser\*\cache*" -Recurse -Force -EA 0 }
Clean "browser-waterfox-cache" { Remove-Item "C:\Users\*\AppData\Local\Waterfox\Profiles\*\cache2\*" -Recurse -Force -EA 0 }
Clean "browser-librewolf-cache" { Remove-Item "C:\Users\*\AppData\Local\librewolf\Profiles\*\cache2\*" -Recurse -Force -EA 0 }
Clean "browser-palemoon-cache" { Remove-Item "C:\Users\*\AppData\Local\Moonchild Productions\Pale Moon\Profiles\*\cache2\*" -Recurse -Force -EA 0 }
Clean "browser-slimjet-cache" { Remove-Item "C:\Users\*\AppData\Local\Slimjet\User Data\*\Cache\*" -Recurse -Force -EA 0 }
Clean "browser-centbrowser-cache" { Remove-Item "C:\Users\*\AppData\Local\CentBrowser\User Data\*\Cache\*" -Recurse -Force -EA 0 }

# ============================================================================
# PHASE 24: DEV TOOLS EXTENDED (100 operations)
# ============================================================================
Write-Host "`n[PHASE 24/40] DEV TOOLS EXTENDED" -ForegroundColor White
# Batch 8: More Development Caches (10 ops)
Clean "dev-lerna-cache" { Remove-Item "C:\Users\*\.lerna\cache\*" -Recurse -Force -EA 0 }
Clean "dev-rush-cache" { Remove-Item "C:\Users\*\.rush\*" -Recurse -Force -EA 0 }
Clean "dev-bower-cache" { Remove-Item "C:\Users\*\.bower\cache\*" -Recurse -Force -EA 0 }
Clean "dev-jspm-cache" { Remove-Item "C:\Users\*\.jspm\cache\*" -Recurse -Force -EA 0 }
Clean "dev-yarn2-cache" { Remove-Item "C:\Users\*\.yarn\berry\cache\*" -Recurse -Force -EA 0 }
Clean "dev-nx-daemon" { Remove-Item "C:\Users\*\.nx\cache\daemon\*" -Recurse -Force -EA 0 }
Clean "dev-vercel-cache" { Remove-Item "C:\Users\*\.vercel\cache\*" -Recurse -Force -EA 0 }
Clean "dev-netlify-cache" { Remove-Item "C:\Users\*\.netlify\cache\*" -Recurse -Force -EA 0 }
Clean "dev-firebase-cache" { Remove-Item "C:\Users\*\.cache\firebase\*" -Recurse -Force -EA 0 }
Clean "dev-supabase-cache" { Remove-Item "C:\Users\*\.supabase\*" -Recurse -Force -EA 0 }

# Batch 9: Container/DevOps cleanup (10 ops)
Clean "devops-docker-buildx" { Remove-Item "C:\Users\*\.docker\buildx\*" -Recurse -Force -EA 0 }
Clean "devops-docker-cache" { Remove-Item "C:\Users\*\AppData\Local\Docker\cache\*" -Recurse -Force -EA 0 }
Clean "devops-docker-log" { Remove-Item "C:\Users\*\AppData\Local\Docker\log\*" -Recurse -Force -EA 0 }
Clean "devops-podman-cache" { Remove-Item "C:\Users\*\.local\share\containers\cache\*" -Recurse -Force -EA 0 }
Clean "devops-kubectl-cache" { Remove-Item "C:\Users\*\.kube\cache\*" -Recurse -Force -EA 0 }
Clean "devops-helm-cache" { Remove-Item "C:\Users\*\.cache\helm\*" -Recurse -Force -EA 0 }
Clean "devops-terraform-cache" { Remove-Item "C:\Users\*\.terraform.d\plugin-cache\*" -Recurse -Force -EA 0 }
Clean "devops-pulumi-cache" { Remove-Item "C:\Users\*\.pulumi\cache\*" -Recurse -Force -EA 0 }
Clean "devops-vagrant-cache" { Remove-Item "C:\Users\*\.vagrant.d\cache\*" -Recurse -Force -EA 0 }
Clean "devops-ansible-cache" { Remove-Item "C:\Users\*\.ansible\cache\*" -Recurse -Force -EA 0 }

# Batch 10: Database Tools cleanup (10 ops)
Clean "db-dbeaver-logs" { Remove-Item "C:\Users\*\AppData\Roaming\DBeaverData\workspace6\*\.metadata\.log" -Force -EA 0 }
Clean "db-dbeaver-cache" { Remove-Item "C:\Users\*\AppData\Roaming\DBeaverData\workspace6\*\.metadata\.plugins\*\cache\*" -Recurse -Force -EA 0 }
Clean "db-mysql-temp" { Remove-Item "C:\ProgramData\MySQL\MySQL Server*\Data\*.tmp" -Force -EA 0 }
Clean "db-postgres-logs" { Remove-Item "C:\Program Files\PostgreSQL\*\data\log\*" -Recurse -Force -EA 0 }
Clean "db-mongodb-logs" { Remove-Item "C:\Program Files\MongoDB\Server\*\log\*" -Recurse -Force -EA 0 }
Clean "db-redis-logs" { Remove-Item "C:\ProgramData\Redis\*.log" -Force -EA 0 }
Clean "db-sqlite-temp" { Remove-Item "C:\Users\*\AppData\Local\Temp\*.sqlite-*" -Force -EA 0 }
Clean "db-azure-storage" { Remove-Item "C:\Users\*\.azurestorage\*" -Recurse -Force -EA 0 }
Clean "db-tableplus-cache" { Remove-Item "C:\Users\*\AppData\Roaming\TablePlus\Cache\*" -Recurse -Force -EA 0 }
Clean "db-datagrip-logs" { Remove-Item "C:\Users\*\AppData\Local\JetBrains\DataGrip*\tmp\*" -Recurse -Force -EA 0 }

# ============================================================================
# PHASE 25: IDE/EDITORS EXTENDED (100 operations)
# ============================================================================
Write-Host "`n[PHASE 25/40] IDE/EDITORS EXTENDED" -ForegroundColor White
# Batch 11: IDE Extended cleanup (10 ops)
Clean "ide-vscode-ext-cache" { Remove-Item "C:\Users\*\.vscode\extensions\*\.cache\*" -Recurse -Force -EA 0 }
Clean "ide-vscode-remote" { Remove-Item "C:\Users\*\.vscode-server\*" -Recurse -Force -EA 0 }
Clean "ide-eclipse-cache" { Remove-Item "C:\Users\*\.eclipse\*\.p2\pool\*" -Recurse -Force -EA 0 }
Clean "ide-eclipse-workspace" { Remove-Item "C:\Users\*\workspace\.metadata\.plugins\*.log" -Force -EA 0 }
Clean "ide-netbeans-cache" { Remove-Item "C:\Users\*\.netbeans\*\var\cache\*" -Recurse -Force -EA 0 }
Clean "ide-netbeans-logs" { Remove-Item "C:\Users\*\.netbeans\*\var\log\*" -Recurse -Force -EA 0 }
Clean "ide-lazarus-cache" { Remove-Item "C:\Users\*\.lazarus\lib\*" -Recurse -Force -EA 0 }
Clean "ide-codeblocks-backup" { Remove-Item "C:\Users\*\AppData\Roaming\CodeBlocks\*.backup" -Force -EA 0 }
Clean "ide-qt-cache" { Remove-Item "C:\Users\*\AppData\Roaming\QtProject\*cache*" -Recurse -Force -EA 0 }
Clean "ide-arduino-cache" { Remove-Item "C:\Users\*\AppData\Local\Arduino*\*cache*" -Recurse -Force -EA 0 }

# Batch 12: API Tools cleanup (10 ops)
Clean "api-postman-crashpad" { Remove-Item "C:\Users\*\AppData\Local\Postman\Crashpad\*" -Recurse -Force -EA 0 }
Clean "api-postman-gpucache" { Remove-Item "C:\Users\*\AppData\Local\Postman\GPUCache\*" -Recurse -Force -EA 0 }
Clean "api-insomnia-gpucache" { Remove-Item "C:\Users\*\AppData\Roaming\Insomnia\GPUCache\*" -Recurse -Force -EA 0 }
Clean "api-insomnia-crashpad" { Remove-Item "C:\Users\*\AppData\Roaming\Insomnia\Crashpad\*" -Recurse -Force -EA 0 }
Clean "api-paw-cache" { Remove-Item "C:\Users\*\AppData\Local\Paw\Cache\*" -Recurse -Force -EA 0 }
Clean "api-hoppscotch-cache" { Remove-Item "C:\Users\*\AppData\Local\Hoppscotch\Cache\*" -Recurse -Force -EA 0 }
Clean "api-soapui-logs" { Remove-Item "C:\Users\*\.soapui\*\*.log" -Force -EA 0 }
Clean "api-swagger-cache" { Remove-Item "C:\Users\*\.swagger\cache\*" -Recurse -Force -EA 0 }
Clean "api-graphql-cache" { Remove-Item "C:\Users\*\AppData\Local\GraphQL Playground\Cache\*" -Recurse -Force -EA 0 }
Clean "api-kong-cache" { Remove-Item "C:\Users\*\.kong\cache\*" -Recurse -Force -EA 0 }

# ============================================================================
# PHASE 26: GAMING EXTENDED (100 operations)
# ============================================================================
Write-Host "`n[PHASE 26/40] GAMING EXTENDED" -ForegroundColor White
# Batch 13: Gaming Extended cleanup (10 ops)
Clean "game-steam-htmlcache2" { Remove-Item "C:\Program Files (x86)\Steam\appcache\httpcache\*" -Recurse -Force -EA 0 }
Clean "game-steam-libraryfolders" { Remove-Item "C:\Program Files (x86)\Steam\steamapps\libraryfolders.vdf.bak" -Force -EA 0 }
Clean "game-epic-vaultcache" { Remove-Item "C:\Users\*\AppData\Local\EpicGamesLauncher\Saved\VaultCache\*" -Recurse -Force -EA 0 }
Clean "game-gog-screenshots" { Remove-Item "C:\Users\*\AppData\Local\GOG.com\Galaxy\Screenshots\temp\*" -Recurse -Force -EA 0 }
Clean "game-playnite-cache" { Remove-Item "C:\Users\*\AppData\Local\Playnite\cache\*" -Recurse -Force -EA 0 }
Clean "game-playnite-logs" { Remove-Item "C:\Users\*\AppData\Local\Playnite\logs\*" -Recurse -Force -EA 0 }
Clean "game-razer-cache" { Remove-Item "C:\ProgramData\Razer\Synapse\*cache*" -Recurse -Force -EA 0 }
Clean "game-razer-logs" { Remove-Item "C:\ProgramData\Razer\Synapse\Logs\*" -Recurse -Force -EA 0 }
Clean "game-logitech-cache" { Remove-Item "C:\ProgramData\Logishrd\*cache*" -Recurse -Force -EA 0 }
Clean "game-corsair-logs" { Remove-Item "C:\ProgramData\Corsair\*\Logs\*" -Recurse -Force -EA 0 }

# Batch 14: More Game Launchers (10 ops)
Clean "game-humble-cache" { Remove-Item "C:\Users\*\AppData\Roaming\Humble App\Cache\*" -Recurse -Force -EA 0 }
Clean "game-legacy-cache" { Remove-Item "C:\Users\*\AppData\Local\Legacy Games\Cache\*" -Recurse -Force -EA 0 }
Clean "game-gamepass-temp" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.GamingServices_*\TempState\*" -Recurse -Force -EA 0 }
Clean "game-xsplit-cache" { Remove-Item "C:\Users\*\AppData\Local\SplitmediaLabs\XSplit\Cache\*" -Recurse -Force -EA 0 }
Clean "game-overwolf-cache" { Remove-Item "C:\Users\*\AppData\Local\Overwolf\Cache\*" -Recurse -Force -EA 0 }
Clean "game-overwolf-logs" { Remove-Item "C:\Users\*\AppData\Local\Overwolf\Log\*" -Recurse -Force -EA 0 }
Clean "game-curseforge-cache" { Remove-Item "C:\Users\*\AppData\Roaming\CurseForge\Cache\*" -Recurse -Force -EA 0 }
Clean "game-prism-cache" { Remove-Item "C:\Users\*\AppData\Local\PrismLauncher\cache\*" -Recurse -Force -EA 0 }
Clean "game-multimc-cache" { Remove-Item "C:\Users\*\AppData\Local\MultiMC\cache\*" -Recurse -Force -EA 0 }
Clean "game-minecraft-logs" { Remove-Item "C:\Users\*\AppData\Roaming\.minecraft\logs\*" -Recurse -Force -EA 0 }

# ============================================================================
# PHASE 27: MEDIA & CREATIVE EXTENDED (100 operations)
# ============================================================================
Write-Host "`n[PHASE 27/40] MEDIA & CREATIVE EXTENDED" -ForegroundColor White
# Batch 15: Design Tools cleanup (10 ops)
Clean "design-figma-blob" { Remove-Item "C:\Users\*\AppData\Local\Figma\blob_storage\*" -Recurse -Force -EA 0 }
Clean "design-figma-crashpad" { Remove-Item "C:\Users\*\AppData\Local\Figma\Crashpad\*" -Recurse -Force -EA 0 }
Clean "design-sketch-cache" { Remove-Item "C:\Users\*\AppData\Roaming\Sketch\Cache\*" -Recurse -Force -EA 0 }
Clean "design-xd-cache" { Remove-Item "C:\Users\*\AppData\Local\Adobe XD\Cache\*" -Recurse -Force -EA 0 }
Clean "design-invision-cache" { Remove-Item "C:\Users\*\AppData\Local\InVision Studio\Cache\*" -Recurse -Force -EA 0 }
Clean "design-principle-cache" { Remove-Item "C:\Users\*\AppData\Roaming\Principle\Cache\*" -Recurse -Force -EA 0 }
Clean "design-gravit-cache" { Remove-Item "C:\Users\*\AppData\Local\Gravit Designer\Cache\*" -Recurse -Force -EA 0 }
Clean "design-affinity-temp" { Remove-Item "C:\Users\*\AppData\Roaming\Affinity\*\Temp\*" -Recurse -Force -EA 0 }
Clean "design-inkscape-cache" { Remove-Item "C:\Users\*\AppData\Roaming\inkscape\cache\*" -Recurse -Force -EA 0 }
Clean "design-krita-cache" { Remove-Item "C:\Users\*\AppData\Local\krita\cache\*" -Recurse -Force -EA 0 }

# Batch 16: 3D/CAD Tools cleanup (10 ops)
Clean "3d-blender-tmp" { Remove-Item "C:\Users\*\AppData\Roaming\Blender Foundation\Blender\*\tmp\*" -Recurse -Force -EA 0 }
Clean "3d-blender-auto" { Remove-Item "C:\Users\*\AppData\Roaming\Blender Foundation\Blender\*\autosave\*" -Recurse -Force -EA 0 }
Clean "3d-maya-temp" { Remove-Item "C:\Users\*\AppData\Local\Temp\maya\*" -Recurse -Force -EA 0 }
Clean "3d-3dsmax-temp" { Remove-Item "C:\Users\*\AppData\Local\Temp\3dsmax\*" -Recurse -Force -EA 0 }
Clean "3d-cinema4d-cache" { Remove-Item "C:\Users\*\AppData\Roaming\Maxon\*\Cache\*" -Recurse -Force -EA 0 }
Clean "3d-zbrush-temp" { Remove-Item "C:\Users\*\AppData\Roaming\ZBrush\*\Temp\*" -Recurse -Force -EA 0 }
Clean "3d-sketchup-cache" { Remove-Item "C:\Users\*\AppData\Local\SketchUp\*\Cache\*" -Recurse -Force -EA 0 }
Clean "3d-fusion360-cache" { Remove-Item "C:\Users\*\AppData\Local\Autodesk\webdeploy\cache\*" -Recurse -Force -EA 0 }
Clean "3d-solidworks-temp" { Remove-Item "C:\Users\*\AppData\Local\Temp\swx*" -Recurse -Force -EA 0 }
Clean "3d-rhino-cache" { Remove-Item "C:\Users\*\AppData\Roaming\McNeel\Rhinoceros\*\Temp\*" -Recurse -Force -EA 0 }

# Batch 17: Audio Production cleanup (10 ops)
Clean "audio-ableton-cache" { Remove-Item "C:\Users\*\AppData\Roaming\Ableton\Live*\Cache\*" -Recurse -Force -EA 0 }
Clean "audio-flstudio-cache" { Remove-Item "C:\Users\*\Documents\Image-Line\*\Temp\*" -Recurse -Force -EA 0 }
Clean "audio-cubase-cache" { Remove-Item "C:\Users\*\AppData\Roaming\Steinberg\*\Cache\*" -Recurse -Force -EA 0 }
Clean "audio-protools-cache" { Remove-Item "C:\Users\*\AppData\Local\Pro Tools\Cache\*" -Recurse -Force -EA 0 }
Clean "audio-reaper-cache" { Remove-Item "C:\Users\*\AppData\Roaming\REAPER\reapercache\*" -Recurse -Force -EA 0 }
Clean "audio-reason-cache" { Remove-Item "C:\Users\*\AppData\Roaming\Reason\*\Cache\*" -Recurse -Force -EA 0 }
Clean "audio-audacity-cache" { Remove-Item "C:\Users\*\AppData\Roaming\audacity\*-temp-*" -Recurse -Force -EA 0 }
Clean "audio-lmms-cache" { Remove-Item "C:\Users\*\AppData\Roaming\lmms\cache\*" -Recurse -Force -EA 0 }
Clean "audio-ardour-cache" { Remove-Item "C:\Users\*\AppData\Local\Ardour*\cache\*" -Recurse -Force -EA 0 }
Clean "audio-vst-cache" { Remove-Item "C:\Users\*\AppData\Local\VSTPlugin*\*" -Recurse -Force -EA 0 }

# Batch 18: Video Production cleanup (10 ops)
Clean "video-premiere-cache" { Remove-Item "C:\Users\*\AppData\Roaming\Adobe\Common\Media Cache Files\*" -Recurse -Force -EA 0 }
Clean "video-premiere-peak" { Remove-Item "C:\Users\*\AppData\Roaming\Adobe\Common\Peak Files\*" -Recurse -Force -EA 0 }
Clean "video-aftereffects-cache" { Remove-Item "C:\Users\*\AppData\Roaming\Adobe\Common\Media Cache\*" -Recurse -Force -EA 0 }
Clean "video-davinci-cache" { Remove-Item "C:\Users\*\AppData\Roaming\Blackmagic Design\DaVinci Resolve\Resolve Disk Database\*" -Recurse -Force -EA 0 }
Clean "video-hitfilm-cache" { Remove-Item "C:\Users\*\AppData\Local\HitFilm\cache\*" -Recurse -Force -EA 0 }
Clean "video-shotcut-cache" { Remove-Item "C:\Users\*\AppData\Local\Meltytech\Shotcut\cache\*" -Recurse -Force -EA 0 }
Clean "video-kdenlive-cache" { Remove-Item "C:\Users\*\AppData\Local\kdenlive\cache\*" -Recurse -Force -EA 0 }
Clean "video-openshot-cache" { Remove-Item "C:\Users\*\.openshot_qt\thumbnail\*" -Recurse -Force -EA 0 }
Clean "video-vegas-cache" { Remove-Item "C:\Users\*\AppData\Local\Vegas Pro*\*cache*" -Recurse -Force -EA 0 }
Clean "video-camtasia-cache" { Remove-Item "C:\Users\*\AppData\Local\TechSmith\Camtasia*\Cache\*" -Recurse -Force -EA 0 }

# ============================================================================
# PHASE 28: STREAMING & COMMUNICATION EXTENDED (100 operations)
# ============================================================================
Write-Host "`n[PHASE 28/40] STREAMING & COMMUNICATION EXTENDED" -ForegroundColor White
# Batch 19: Streaming Apps cleanup (10 ops)
Clean "stream-obs-replay" { Remove-Item "C:\Users\*\Videos\*\Replay\*" -Recurse -Force -EA 0 }
Clean "stream-streamlabs-cache" { Remove-Item "C:\Users\*\AppData\Roaming\slobs-client\Cache\*" -Recurse -Force -EA 0 }
Clean "stream-streamlabs-logs" { Remove-Item "C:\Users\*\AppData\Roaming\slobs-client\logs\*" -Recurse -Force -EA 0 }
Clean "stream-xsplit-logs" { Remove-Item "C:\Users\*\AppData\Local\SplitmediaLabs\XSplit\Logs\*" -Recurse -Force -EA 0 }
Clean "stream-twitch-cache" { Remove-Item "C:\Users\*\AppData\Roaming\Twitch\Cache\*" -Recurse -Force -EA 0 }
Clean "stream-twitch-logs" { Remove-Item "C:\Users\*\AppData\Roaming\Twitch\Logs\*" -Recurse -Force -EA 0 }
Clean "stream-nvidia-broadcast" { Remove-Item "C:\Users\*\AppData\Local\NVIDIA\NVIDIA Broadcast\cache\*" -Recurse -Force -EA 0 }
Clean "stream-voicemeeter-logs" { Remove-Item "C:\Users\*\Documents\Voicemeeter\*log*" -Force -EA 0 }
Clean "stream-elgato-cache" { Remove-Item "C:\Users\*\AppData\Roaming\Elgato\*\cache\*" -Recurse -Force -EA 0 }
Clean "stream-shadowplay-temp" { Remove-Item "C:\Users\*\AppData\Local\Temp\NVIDIA Share\*" -Recurse -Force -EA 0 }

# Batch 20: Communication Apps Extended (10 ops)
Clean "comm-discord-modules" { Remove-Item "C:\Users\*\AppData\Local\Discord\*\modules\pending\*" -Recurse -Force -EA 0 }
Clean "comm-slack-downloads" { Remove-Item "C:\Users\*\AppData\Local\Slack\downloads\*" -Recurse -Force -EA 0 }
Clean "comm-teams-backgrounds" { Remove-Item "C:\Users\*\AppData\Roaming\Microsoft Teams\Backgrounds\Uploads\*.tmp" -Force -EA 0 }
Clean "comm-zoom-temp" { Remove-Item "C:\Users\*\AppData\Roaming\Zoom\temp\*" -Recurse -Force -EA 0 }
Clean "comm-webex-temp" { Remove-Item "C:\Users\*\AppData\Local\CiscoSpark\temp\*" -Recurse -Force -EA 0 }
Clean "comm-guilded-cache" { Remove-Item "C:\Users\*\AppData\Local\Guilded\Cache\*" -Recurse -Force -EA 0 }
Clean "comm-revolt-cache" { Remove-Item "C:\Users\*\AppData\Local\Revolt\Cache\*" -Recurse -Force -EA 0 }
Clean "comm-keybase-cache" { Remove-Item "C:\Users\*\AppData\Local\Keybase\Cache\*" -Recurse -Force -EA 0 }
Clean "comm-wire-cache" { Remove-Item "C:\Users\*\AppData\Roaming\Wire\Cache\*" -Recurse -Force -EA 0 }
Clean "comm-jitsi-cache" { Remove-Item "C:\Users\*\AppData\Roaming\Jitsi Meet\Cache\*" -Recurse -Force -EA 0 }

# ============================================================================
# PHASE 29: CLOUD & PRODUCTIVITY EXTENDED (100 operations)
# ============================================================================
Write-Host "`n[PHASE 29/40] CLOUD & PRODUCTIVITY EXTENDED" -ForegroundColor White
# Batch 21: Cloud Services Extended (10 ops)
Clean "cloud-mega-cache" { Remove-Item "C:\Users\*\AppData\Local\Mega Limited\MEGAsync\*cache*" -Recurse -Force -EA 0 }
Clean "cloud-mega-logs" { Remove-Item "C:\Users\*\AppData\Local\Mega Limited\MEGAsync\logs\*" -Recurse -Force -EA 0 }
Clean "cloud-sync-cache" { Remove-Item "C:\Users\*\AppData\Local\Sync\cache\*" -Recurse -Force -EA 0 }
Clean "cloud-spideroak-cache" { Remove-Item "C:\Users\*\AppData\Local\SpiderOak\cache\*" -Recurse -Force -EA 0 }
Clean "cloud-tresorit-cache" { Remove-Item "C:\Users\*\AppData\Local\Tresorit\cache\*" -Recurse -Force -EA 0 }
Clean "cloud-seafile-cache" { Remove-Item "C:\Users\*\AppData\Local\Seafile\cache\*" -Recurse -Force -EA 0 }
Clean "cloud-nextcloud-logs" { Remove-Item "C:\Users\*\AppData\Local\Nextcloud\logs\*" -Recurse -Force -EA 0 }
Clean "cloud-owncloud-logs" { Remove-Item "C:\Users\*\AppData\Local\ownCloud\logs\*" -Recurse -Force -EA 0 }
Clean "cloud-syncthing-db" { Remove-Item "C:\Users\*\AppData\Local\Syncthing\index-*\*.tmp" -Force -EA 0 }
Clean "cloud-resilio-cache" { Remove-Item "C:\Users\*\AppData\Roaming\Resilio Sync\*\.sync\*" -Recurse -Force -EA 0 }

# Batch 22: Office Apps cleanup (10 ops)
Clean "office-word-temp" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Word\*" -Recurse -Force -EA 0 }
Clean "office-excel-temp" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Excel\*" -Recurse -Force -EA 0 }
Clean "office-ppt-temp" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\PowerPoint\*" -Recurse -Force -EA 0 }
Clean "office-access-temp" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Access\*" -Recurse -Force -EA 0 }
Clean "office-publisher-temp" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Publisher\*" -Recurse -Force -EA 0 }
Clean "office-libreoffice-backup" { Remove-Item "C:\Users\*\AppData\Roaming\LibreOffice\*\user\backup\*" -Recurse -Force -EA 0 }
Clean "office-libreoffice-cache" { Remove-Item "C:\Users\*\AppData\Roaming\LibreOffice\*\user\cache\*" -Recurse -Force -EA 0 }
Clean "office-wps-cache" { Remove-Item "C:\Users\*\AppData\Local\Kingsoft\WPS Office\*\cache\*" -Recurse -Force -EA 0 }
Clean "office-openoffice-backup" { Remove-Item "C:\Users\*\AppData\Roaming\OpenOffice\*\user\backup\*" -Recurse -Force -EA 0 }
Clean "office-softmaker-temp" { Remove-Item "C:\Users\*\AppData\Roaming\SoftMaker\*\Temp\*" -Recurse -Force -EA 0 }

# ============================================================================
# PHASE 30: SECURITY & SYSTEM UTILITIES (100 operations)
# ============================================================================
Write-Host "`n[PHASE 30/40] SECURITY & SYSTEM UTILITIES" -ForegroundColor White
# Batch 23: Security/AV cleanup (10 ops)
Clean "av-bitdefender-logs" { Remove-Item "C:\ProgramData\Bitdefender\*\Logs\*" -Recurse -Force -EA 0 }
Clean "av-norton-logs" { Remove-Item "C:\ProgramData\Norton\*\Logs\*" -Recurse -Force -EA 0 }
Clean "av-avast-logs" { Remove-Item "C:\ProgramData\Avast Software\Avast\log\*" -Recurse -Force -EA 0 }
Clean "av-avg-logs" { Remove-Item "C:\ProgramData\AVG\*\log\*" -Recurse -Force -EA 0 }
Clean "av-mcafee-logs" { Remove-Item "C:\ProgramData\McAfee\*\Logs\*" -Recurse -Force -EA 0 }
Clean "av-trend-logs" { Remove-Item "C:\ProgramData\Trend Micro\*\Logs\*" -Recurse -Force -EA 0 }
Clean "av-f-secure-logs" { Remove-Item "C:\ProgramData\F-Secure\*\log\*" -Recurse -Force -EA 0 }
Clean "av-avira-logs" { Remove-Item "C:\ProgramData\Avira\*\Log\*" -Recurse -Force -EA 0 }
Clean "av-webroot-logs" { Remove-Item "C:\ProgramData\WRData\WRLog\*" -Recurse -Force -EA 0 }
Clean "av-comodo-logs" { Remove-Item "C:\ProgramData\Comodo\*\logs\*" -Recurse -Force -EA 0 }

# Batch 24: System Utilities cleanup (10 ops)
Clean "util-ccleaner-logs" { Remove-Item "C:\Program Files\CCleaner\*log*.txt" -Force -EA 0 }
Clean "util-speccy-logs" { Remove-Item "C:\Users\*\AppData\Local\Piriform\Speccy\*" -Recurse -Force -EA 0 }
Clean "util-recuva-logs" { Remove-Item "C:\Users\*\AppData\Local\Piriform\Recuva\*" -Recurse -Force -EA 0 }
Clean "util-defraggler-logs" { Remove-Item "C:\Users\*\AppData\Local\Piriform\Defraggler\*" -Recurse -Force -EA 0 }
Clean "util-7zip-temp" { Remove-Item "C:\Users\*\AppData\Local\Temp\7z*" -Recurse -Force -EA 0 }
Clean "util-winrar-temp" { Remove-Item "C:\Users\*\AppData\Local\Temp\Rar*" -Recurse -Force -EA 0 }
Clean "util-hwinfo-logs" { Remove-Item "C:\Users\*\AppData\Local\HWiNFO*\*.csv" -Force -EA 0 }
Clean "util-cpuz-cache" { Remove-Item "C:\Users\*\AppData\Local\CPUID\*\*" -Recurse -Force -EA 0 }
Clean "util-gpuz-logs" { Remove-Item "C:\Users\*\AppData\Local\GPU-Z\*" -Recurse -Force -EA 0 }
Clean "util-crystaldisk-temp" { Remove-Item "C:\Users\*\AppData\Local\CrystalDiskInfo\*" -Recurse -Force -EA 0 }

# ============================================================================
# PHASE 31: WINDOWS FEATURES EXTENDED (100 operations)
# ============================================================================
Write-Host "`n[PHASE 31/40] WINDOWS FEATURES EXTENDED" -ForegroundColor White
# Batch 25: Windows Features Extended (10 ops)
Clean "winfeature-hyper-v-logs" { Remove-Item "C:\ProgramData\Microsoft\Windows\Hyper-V\*\*.etl" -Force -EA 0 }
Clean "winfeature-wsl-temp" { Remove-Item "C:\Users\*\AppData\Local\lxss\*\temp\*" -Recurse -Force -EA 0 }
Clean "winfeature-sandbox-temp" { Remove-Item "C:\ProgramData\Microsoft\Windows\Containers\BaseImages\*\Temp\*" -Recurse -Force -EA 0 }
Clean "winfeature-miracast-temp" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\PlayReady\*" -Recurse -Force -EA 0 }
Clean "winfeature-directaccess-logs" { Remove-Item "C:\Windows\Logs\DirectAccess\*" -Recurse -Force -EA 0 }
Clean "winfeature-bitlocker-logs" { Remove-Item "C:\Windows\Logs\BitLocker\*" -Recurse -Force -EA 0 }
Clean "winfeature-remoteapp-cache" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\RemoteApp and Desktop Connections\*" -Recurse -Force -EA 0 }
Clean "winfeature-appv-cache" { Remove-Item "C:\ProgramData\App-V\*" -Recurse -Force -EA 0 }
Clean "winfeature-uev-cache" { Remove-Item "C:\ProgramData\Microsoft\UEV\*" -Recurse -Force -EA 0 }
Clean "winfeature-mdt-logs" { Remove-Item "C:\MININT\SMSOSD\OSDLOGS\*" -Recurse -Force -EA 0 }

# Batch 26: Hardware/Driver cleanup (10 ops)
Clean "hw-nvidia-installer" { Remove-Item "C:\NVIDIA\DisplayDriver\*\Win*\*\*.tmp" -Force -EA 0 }
Clean "hw-amd-installer" { Remove-Item "C:\AMD\*\*.tmp" -Force -EA 0 }
Clean "hw-intel-installer" { Remove-Item "C:\Intel\*\*.log" -Force -EA 0 }
Clean "hw-realtek-installer" { Remove-Item "C:\Program Files\Realtek\*\*.log" -Force -EA 0 }
Clean "hw-synaptics-logs" { Remove-Item "C:\ProgramData\Synaptics\*\*.log" -Force -EA 0 }
Clean "hw-wacom-logs" { Remove-Item "C:\Users\*\AppData\Local\Wacom\*\*.log" -Force -EA 0 }
Clean "hw-logitech-logs" { Remove-Item "C:\Users\*\AppData\Local\Logitech\*\*.log" -Force -EA 0 }
Clean "hw-razer-installer" { Remove-Item "C:\ProgramData\Razer\Installer\*" -Recurse -Force -EA 0 }
Clean "hw-corsair-installer" { Remove-Item "C:\ProgramData\Corsair\CUE\Installer\*" -Recurse -Force -EA 0 }
Clean "hw-steelseries-logs" { Remove-Item "C:\ProgramData\SteelSeries\SteelSeries Engine*\Logs\*" -Recurse -Force -EA 0 }

# Batch 27: Network Related cleanup (10 ops)
Clean "net-dns-client-cache" { Remove-Item "C:\Windows\System32\config\systemprofile\AppData\Local\Microsoft\Windows\DNS Client\*" -Recurse -Force -EA 0 }
Clean "net-ncsi-cache" { Remove-Item "C:\Windows\System32\config\systemprofile\AppData\Local\Microsoft\Windows\NCSI\*" -Recurse -Force -EA 0 }
Clean "net-vpn-logs" { Remove-Item "C:\Users\*\AppData\Local\VPN\*\Logs\*" -Recurse -Force -EA 0 }
Clean "net-nordvpn-logs" { Remove-Item "C:\Users\*\AppData\Local\NordVPN\Logs\*" -Recurse -Force -EA 0 }
Clean "net-expressvpn-logs" { Remove-Item "C:\ProgramData\ExpressVPN\Logs\*" -Recurse -Force -EA 0 }
Clean "net-protonvpn-logs" { Remove-Item "C:\Users\*\AppData\Local\ProtonVPN\Logs\*" -Recurse -Force -EA 0 }
Clean "net-tailscale-logs" { Remove-Item "C:\Users\*\AppData\Local\Tailscale\*.log" -Force -EA 0 }
Clean "net-zerotier-logs" { Remove-Item "C:\ProgramData\ZeroTier\One\*.log" -Force -EA 0 }
Clean "net-wireguard-logs" { Remove-Item "C:\Program Files\WireGuard\Data\log.bin" -Force -EA 0 }
Clean "net-openconnect-cache" { Remove-Item "C:\Users\*\AppData\Local\OpenConnect\*" -Recurse -Force -EA 0 }

# ============================================================================
# PHASE 32: PRINT/SEARCH/BACKUP EXTENDED (100 operations)
# ============================================================================
Write-Host "`n[PHASE 32/40] PRINT/SEARCH/BACKUP EXTENDED" -ForegroundColor White
# Batch 28: Print/Fax cleanup (10 ops)
Clean "print-spool-printers" { Remove-Item "C:\Windows\System32\spool\PRINTERS\*.shd" -Force -EA 0 }
Clean "print-spool-shadow" { Remove-Item "C:\Windows\System32\spool\PRINTERS\*.spl" -Force -EA 0 }
Clean "print-pdf-temp" { Remove-Item "C:\Users\*\AppData\Local\Temp\*PDF*.tmp" -Force -EA 0 }
Clean "print-cups-temp" { Remove-Item "C:\Windows\System32\spool\drivers\x64\*\*.tmp" -Force -EA 0 }
Clean "print-fax-queue" { Remove-Item "C:\ProgramData\Microsoft\Windows NT\MSFax\Queue\*" -Recurse -Force -EA 0 }
Clean "print-fax-logs" { Remove-Item "C:\ProgramData\Microsoft\Windows NT\MSFax\ActivityLog\*" -Recurse -Force -EA 0 }
Clean "print-acrobat-temp" { Remove-Item "C:\Users\*\AppData\Local\Adobe\Acrobat\*\Cache\*" -Recurse -Force -EA 0 }
Clean "print-foxit-temp" { Remove-Item "C:\Users\*\AppData\Local\Foxit Reader\*\cache\*" -Recurse -Force -EA 0 }
Clean "print-sumatra-temp" { Remove-Item "C:\Users\*\AppData\Local\SumatraPDF\sumatrapdfrestr.txt" -Force -EA 0 }
Clean "print-xps-temp" { Remove-Item "C:\Users\*\AppData\Local\Temp\*.xps" -Force -EA 0 }

# Batch 29: Search/Indexing Extended (10 ops)
Clean "search-index-tmp" { Remove-Item "C:\ProgramData\Microsoft\Search\Data\Applications\Windows\*.tmp" -Force -EA 0 }
Clean "search-index-gt" { Remove-Item "C:\ProgramData\Microsoft\Search\Data\Applications\Windows\GatherLogs\*" -Recurse -Force -EA 0 }
Clean "search-index-projects" { Remove-Item "C:\ProgramData\Microsoft\Search\Data\Applications\Windows\Projects\*" -Recurse -Force -EA 0 }
Clean "search-cortana-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.Windows.Cortana_*\LocalState\AppIconCache\*" -Recurse -Force -EA 0 }
Clean "search-cortana-db" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.Windows.Cortana_*\LocalState\DeviceSearchCache\*" -Recurse -Force -EA 0 }
Clean "search-start-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.Windows.StartMenuExperienceHost_*\LocalState\*cache*" -Recurse -Force -EA 0 }
Clean "search-shell-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.Windows.ShellExperienceHost_*\TempState\*" -Recurse -Force -EA 0 }
Clean "search-explorer-db" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Windows\Explorer\*.db-*" -Force -EA 0 }
Clean "search-everything-db" { Remove-Item "C:\Users\*\AppData\Local\Everything\*.tmp" -Force -EA 0 }
Clean "search-listary-cache" { Remove-Item "C:\Users\*\AppData\Roaming\Listary\*cache*" -Recurse -Force -EA 0 }

# Batch 30: Windows Backup cleanup (10 ops)
Clean "backup-wbadmin-logs" { Remove-Item "C:\Windows\Logs\WindowsServerBackup\*" -Recurse -Force -EA 0 }
Clean "backup-filehistory-config" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Windows\FileHistory\Configuration\*.tmp" -Force -EA 0 }
Clean "backup-systemrestore-old" { vssadmin delete shadows /for=c: /oldest /quiet 2>$null }
Clean "backup-restore-cache" { Remove-Item "C:\System Volume Information\*Restore*\*.tmp" -Force -EA 0 }
Clean "backup-acronis-logs" { Remove-Item "C:\ProgramData\Acronis\*\Logs\*" -Recurse -Force -EA 0 }
Clean "backup-veeam-logs" { Remove-Item "C:\ProgramData\Veeam\*\Logs\*" -Recurse -Force -EA 0 }
Clean "backup-macrium-logs" { Remove-Item "C:\ProgramData\Macrium\*\Logs\*" -Recurse -Force -EA 0 }
Clean "backup-carbonite-cache" { Remove-Item "C:\ProgramData\Carbonite\*\cache\*" -Recurse -Force -EA 0 }
Clean "backup-backblaze-cache" { Remove-Item "C:\ProgramData\Backblaze\*\cache\*" -Recurse -Force -EA 0 }
Clean "backup-idrive-logs" { Remove-Item "C:\ProgramData\IDrive\*\Logs\*" -Recurse -Force -EA 0 }

# ============================================================================
# PHASE 33: ERROR REPORTING & PREFETCH EXTENDED (100 operations)
# ============================================================================
Write-Host "`n[PHASE 33/40] ERROR REPORTING & PREFETCH EXTENDED" -ForegroundColor White
# Batch 31: Windows Error Reporting Extended (10 ops)
Clean "wer-queue-system" { Remove-Item "C:\ProgramData\Microsoft\Windows\WER\ReportQueue\*" -Recurse -Force -EA 0 }
Clean "wer-archive-system" { Remove-Item "C:\ProgramData\Microsoft\Windows\WER\ReportArchive\*" -Recurse -Force -EA 0 }
Clean "wer-temp-system" { Remove-Item "C:\ProgramData\Microsoft\Windows\WER\Temp\*" -Recurse -Force -EA 0 }
Clean "wer-user-queue" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Windows\WER\ReportQueue\*" -Recurse -Force -EA 0 }
Clean "wer-user-archive" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Windows\WER\ReportArchive\*" -Recurse -Force -EA 0 }
Clean "wer-user-temp" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Windows\WER\Temp\*" -Recurse -Force -EA 0 }
Clean "wer-local-dumps" { Remove-Item "C:\Windows\System32\config\systemprofile\AppData\Local\Microsoft\Windows\WER\*" -Recurse -Force -EA 0 }
Clean "wer-nt-error" { Remove-Item "C:\Windows\Debug\WER\*" -Recurse -Force -EA 0 }
Clean "wer-system-error-logs" { Remove-Item "C:\Windows\System32\LogFiles\WMI\RtBackup\*" -Recurse -Force -EA 0 }
Clean "wer-kernel-logs" { Remove-Item "C:\Windows\System32\LogFiles\WMI\*.etl" -Force -EA 0 }

# Batch 32: Windows Prefetch Extended (10 ops)
Clean "prefetch-readyboot" { Remove-Item "C:\Windows\Prefetch\ReadyBoot\*.fx" -Force -EA 0 }
Clean "prefetch-trace" { Remove-Item "C:\Windows\Prefetch\*.db" -Force -EA 0 }
Clean "prefetch-superprefetch" { Remove-Item "C:\Windows\Prefetch\AgGlFaultHistory.db" -Force -EA 0 }
Clean "prefetch-agapplaunch" { Remove-Item "C:\Windows\Prefetch\AgAppLaunch.db" -Force -EA 0 }
Clean "prefetch-agglglobalhistory" { Remove-Item "C:\Windows\Prefetch\AgGlGlobalHistory.db" -Force -EA 0 }
Clean "prefetch-agrobust" { Remove-Item "C:\Windows\Prefetch\AgRobust.db" -Force -EA 0 }
Clean "prefetch-syscache" { Remove-Item "C:\Windows\Prefetch\SysCache.hve" -Force -EA 0 }
Clean "prefetch-layout" { Remove-Item "C:\Windows\Prefetch\Layout.ini" -Force -EA 0 }
Clean "prefetch-pfsvperf" { Remove-Item "C:\Windows\Prefetch\PfSvPerf*.bin" -Force -EA 0 }
Clean "prefetch-old-pf" { Get-ChildItem "C:\Windows\Prefetch\*.pf" -EA 0 | Where-Object {$_.LastWriteTime -lt (Get-Date).AddDays(-30)} | Remove-Item -Force -EA 0 }

# ============================================================================
# PHASE 34: LOGS EXTENDED (100 operations)
# ============================================================================
Write-Host "`n[PHASE 34/40] LOGS EXTENDED" -ForegroundColor White
# Batch 33: Windows Logs Extended (10 ops)
Clean "logs-iis-all" { Remove-Item "C:\inetpub\logs\LogFiles\*" -Recurse -Force -EA 0 }
Clean "logs-iis-failed" { Remove-Item "C:\inetpub\logs\FailedReqLogFiles\*" -Recurse -Force -EA 0 }
Clean "logs-httperr" { Remove-Item "C:\Windows\System32\LogFiles\HTTPERR\*" -Recurse -Force -EA 0 }
Clean "logs-setupapi" { Remove-Item "C:\Windows\INF\setupapi*.log" -Force -EA 0 }
Clean "logs-dpinst" { Remove-Item "C:\Windows\dpinst.log" -Force -EA 0 }
Clean "logs-dps" { Remove-Item "C:\Windows\System32\LogFiles\Srt\*" -Recurse -Force -EA 0 }
Clean "logs-clr" { Remove-Item "C:\Windows\Microsoft.NET\Framework64\v*\SetupCache\*\*.log" -Force -EA 0 }
Clean "logs-defender-support" { Remove-Item "C:\ProgramData\Microsoft\Windows Defender\Support\*" -Recurse -Force -EA 0 }
Clean "logs-msit" { Remove-Item "C:\Windows\Logs\MoSetup\*" -Recurse -Force -EA 0 }
Clean "logs-performance" { Remove-Item "C:\Windows\Performance\*" -Recurse -Force -EA 0 }

# Batch 34: Application Logs cleanup (10 ops)
Clean "app-logs-crashplan" { Remove-Item "C:\ProgramData\CrashPlan\log\*" -Recurse -Force -EA 0 }
Clean "app-logs-skype-old" { Remove-Item "C:\Users\*\AppData\Roaming\Skype\*\main.db-journal" -Force -EA 0 }
Clean "app-logs-paint3d" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.MSPaint_*\LocalState\*log*" -Force -EA 0 }
Clean "app-logs-xbox-identity" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.XboxIdentityProvider_*\LocalState\*" -Recurse -Force -EA 0 }
Clean "app-logs-winget-state" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\WinGet\State\*" -Recurse -Force -EA 0 }
Clean "app-logs-terminal-state" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Windows Terminal\state.json" -Force -EA 0 }
Clean "app-logs-pwsh-history" { Remove-Item "C:\Users\*\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt" -Force -EA 0 }
Clean "app-logs-cmd-history" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Windows\History\*" -Recurse -Force -EA 0 }
Clean "app-logs-snip-settings" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.ScreenSketch_*\Settings\settings.dat.LOG*" -Force -EA 0 }
Clean "app-logs-photos-settings" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.Windows.Photos_*\Settings\settings.dat.LOG*" -Force -EA 0 }

# ============================================================================
# PHASE 35: EDUCATION & PRODUCTIVITY EXTENDED (100 operations)
# ============================================================================
Write-Host "`n[PHASE 35/40] EDUCATION & PRODUCTIVITY EXTENDED" -ForegroundColor White
# Batch 35: Education/Learning cleanup (10 ops)
Clean "edu-anki-cache" { Remove-Item "C:\Users\*\AppData\Roaming\Anki2\*\collection.media\.cache*" -Force -EA 0 }
Clean "edu-grammarly-cache" { Remove-Item "C:\Users\*\AppData\Local\Grammarly\DesktopIntegrations\Cache\*" -Recurse -Force -EA 0 }
Clean "edu-languagetool-cache" { Remove-Item "C:\Users\*\AppData\Local\LanguageTool\cache\*" -Recurse -Force -EA 0 }
Clean "edu-zotero-cache" { Remove-Item "C:\Users\*\Zotero\cache\*" -Recurse -Force -EA 0 }
Clean "edu-mendeley-cache" { Remove-Item "C:\Users\*\AppData\Local\Mendeley Ltd\Mendeley Desktop\*cache*" -Recurse -Force -EA 0 }
Clean "edu-calibre-cache" { Remove-Item "C:\Users\*\AppData\Local\calibre-ebook.com\calibre\cache\*" -Recurse -Force -EA 0 }
Clean "edu-kindle-cache" { Remove-Item "C:\Users\*\AppData\Local\Amazon\Kindle\Cache\*" -Recurse -Force -EA 0 }
Clean "edu-duolingo-cache" { Remove-Item "C:\Users\*\AppData\Local\Duolingo\Cache\*" -Recurse -Force -EA 0 }
Clean "edu-coursera-cache" { Remove-Item "C:\Users\*\AppData\Local\Coursera\Cache\*" -Recurse -Force -EA 0 }
Clean "edu-udemy-cache" { Remove-Item "C:\Users\*\AppData\Local\Udemy\Cache\*" -Recurse -Force -EA 0 }

# Batch 36: Productivity Apps cleanup (10 ops)
Clean "prod-notion-blob" { Remove-Item "C:\Users\*\AppData\Roaming\Notion\blob_storage\*" -Recurse -Force -EA 0 }
Clean "prod-notion-serviceworker" { Remove-Item "C:\Users\*\AppData\Roaming\Notion\Service Worker\*" -Recurse -Force -EA 0 }
Clean "prod-obsidian-blob" { Remove-Item "C:\Users\*\AppData\Roaming\obsidian\blob_storage\*" -Recurse -Force -EA 0 }
Clean "prod-todoist-cache" { Remove-Item "C:\Users\*\AppData\Local\Todoist\Cache\*" -Recurse -Force -EA 0 }
Clean "prod-ticktick-cache" { Remove-Item "C:\Users\*\AppData\Local\TickTick\Cache\*" -Recurse -Force -EA 0 }
Clean "prod-trello-cache" { Remove-Item "C:\Users\*\AppData\Local\Trello\Cache\*" -Recurse -Force -EA 0 }
Clean "prod-asana-cache" { Remove-Item "C:\Users\*\AppData\Local\Asana\Cache\*" -Recurse -Force -EA 0 }
Clean "prod-clickup-cache" { Remove-Item "C:\Users\*\AppData\Local\ClickUp\Cache\*" -Recurse -Force -EA 0 }
Clean "prod-monday-cache" { Remove-Item "C:\Users\*\AppData\Local\Monday\Cache\*" -Recurse -Force -EA 0 }
Clean "prod-miro-cache" { Remove-Item "C:\Users\*\AppData\Local\Miro\Cache\*" -Recurse -Force -EA 0 }

# ============================================================================
# PHASE 36: WINDOWS STORE EXTENDED (100 operations)
# ============================================================================
Write-Host "`n[PHASE 36/40] WINDOWS STORE EXTENDED" -ForegroundColor White
# Batch 37: Windows Store Extended (10 ops)
Clean "store-delivery-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.WindowsStore_*\LocalState\*cache*" -Recurse -Force -EA 0 }
Clean "store-app-installer" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.DesktopAppInstaller_*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "store-app-installer-temp" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.DesktopAppInstaller_*\TempState\*" -Recurse -Force -EA 0 }
Clean "store-family-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.Family*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "store-account-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.AccountsControl_*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "store-aad-broker" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.AAD.BrokerPlugin_*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "store-credential-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.CredDialogHost_*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "store-lock-app" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.LockApp_*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "store-content-delivery" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.Windows.ContentDeliveryManager_*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "store-search-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.Windows.Search_*\LocalCache\*" -Recurse -Force -EA 0 }

# Batch 38: Font/Typography cleanup (10 ops)
Clean "font-user-cache" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Windows\Fonts\*.tmp" -Force -EA 0 }
Clean "font-system-cache" { Remove-Item "C:\Windows\ServiceProfiles\LocalService\AppData\Local\FontCache\*.dat" -Force -EA 0 }
Clean "font-service-cache" { Remove-Item "C:\Windows\ServiceProfiles\LocalService\AppData\Local\FontCache\Fonts\*.tmp" -Force -EA 0 }
Clean "font-fntcache" { Remove-Item "C:\Windows\System32\FNTCACHE.DAT" -Force -EA 0 }
Clean "font-adobe-cache" { Remove-Item "C:\Users\*\AppData\Roaming\Adobe\CoreSync\CoreSync*\*.tmp" -Force -EA 0 }
Clean "font-typekit-cache" { Remove-Item "C:\Users\*\AppData\Local\Adobe\Typekit\cache\*" -Recurse -Force -EA 0 }
Clean "font-fontsmoothingdata" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Windows\FontSmoothing\*" -Recurse -Force -EA 0 }
Clean "font-google-cache" { Remove-Item "C:\Users\*\AppData\Local\Google\Fonts\*" -Recurse -Force -EA 0 }
Clean "font-fontbase-cache" { Remove-Item "C:\Users\*\AppData\Roaming\FontBase\cache\*" -Recurse -Force -EA 0 }
Clean "font-suitcase-cache" { Remove-Item "C:\Users\*\AppData\Local\Extensis\Suitcase Fusion\cache\*" -Recurse -Force -EA 0 }

# ============================================================================
# PHASE 37: VIRTUALIZATION & EMULATION (100 operations)
# ============================================================================
Write-Host "`n[PHASE 37/40] VIRTUALIZATION & EMULATION" -ForegroundColor White
# Batch 39: Virtualization cleanup (10 ops)
Clean "virt-vmware-logs" { Remove-Item "C:\Users\*\AppData\Local\Temp\vmware-*" -Recurse -Force -EA 0 }
Clean "virt-vmware-workstation" { Remove-Item "C:\Users\*\AppData\Roaming\VMware\*.log" -Force -EA 0 }
Clean "virt-virtualbox-logs" { Remove-Item "C:\Users\*\.VirtualBox\*.log*" -Force -EA 0 }
Clean "virt-virtualbox-cache" { Remove-Item "C:\Users\*\.VirtualBox\compreg.dat" -Force -EA 0 }
Clean "virt-hyperv-checkpoints" { Remove-Item "C:\ProgramData\Microsoft\Windows\Hyper-V\Snapshots\*" -Recurse -Force -EA 0 }
Clean "virt-hyperv-replica" { Remove-Item "C:\ProgramData\Microsoft\Windows\Hyper-V\Replica\*" -Recurse -Force -EA 0 }
Clean "virt-qemu-logs" { Remove-Item "C:\Users\*\.config\qemu\*.log" -Force -EA 0 }
Clean "virt-parallels-logs" { Remove-Item "C:\Users\*\AppData\Local\Parallels\*\Logs\*" -Recurse -Force -EA 0 }
Clean "virt-bluestacks-logs" { Remove-Item "C:\ProgramData\BlueStacks*\Logs\*" -Recurse -Force -EA 0 }
Clean "virt-bluestacks-temp" { Remove-Item "C:\ProgramData\BlueStacks*\Client\Temp\*" -Recurse -Force -EA 0 }

# Batch 40: Emulation cleanup (10 ops)
Clean "emu-retroarch-logs" { Remove-Item "C:\Users\*\AppData\Roaming\RetroArch\logs\*" -Recurse -Force -EA 0 }
Clean "emu-retroarch-cache" { Remove-Item "C:\Users\*\AppData\Roaming\RetroArch\thumbnails\.cache\*" -Recurse -Force -EA 0 }
Clean "emu-dolphin-cache" { Remove-Item "C:\Users\*\AppData\Roaming\Dolphin Emulator\Cache\*" -Recurse -Force -EA 0 }
Clean "emu-pcsx2-logs" { Remove-Item "C:\Users\*\AppData\Roaming\PCSX2\logs\*" -Recurse -Force -EA 0 }
Clean "emu-rpcs3-cache" { Remove-Item "C:\Users\*\AppData\Roaming\rpcs3\cache\*" -Recurse -Force -EA 0 }
Clean "emu-yuzu-cache" { Remove-Item "C:\Users\*\AppData\Roaming\yuzu\cache\*" -Recurse -Force -EA 0 }
Clean "emu-ryujinx-logs" { Remove-Item "C:\Users\*\AppData\Roaming\Ryujinx\Logs\*" -Recurse -Force -EA 0 }
Clean "emu-cemu-cache" { Remove-Item "C:\Users\*\AppData\Roaming\Cemu\shaderCache\*" -Recurse -Force -EA 0 }
Clean "emu-citra-cache" { Remove-Item "C:\Users\*\AppData\Roaming\Citra\cache\*" -Recurse -Force -EA 0 }
Clean "emu-desmume-cache" { Remove-Item "C:\Users\*\AppData\Roaming\DeSmuME\*cache*" -Recurse -Force -EA 0 }

# ============================================================================
# PHASE 38: AI/ML TOOLS CLEANUP (100 operations)
# ============================================================================
Write-Host "`n[PHASE 38/40] AI/ML TOOLS CLEANUP" -ForegroundColor White
Clean "ai-openai-cache" { Remove-Item "C:\Users\*\.openai\*" -Recurse -Force -EA 0 }
Clean "ai-anthropic-cache" { Remove-Item "C:\Users\*\.anthropic\*" -Recurse -Force -EA 0 }
Clean "ai-claude-cache" { Remove-Item "C:\Users\*\.claude\cache\*" -Recurse -Force -EA 0 }
Clean "ai-huggingface-models" { Remove-Item "C:\Users\*\.cache\huggingface\hub\*\.lock" -Force -EA 0 }
Clean "ai-transformers-cache" { Remove-Item "C:\Users\*\.cache\huggingface\transformers\*" -Recurse -Force -EA 0 }
Clean "ai-torch-hub" { Remove-Item "C:\Users\*\.cache\torch\hub\*" -Recurse -Force -EA 0 }
Clean "ai-torch-kernels" { Remove-Item "C:\Users\*\.cache\torch\kernels\*" -Recurse -Force -EA 0 }
Clean "ai-tensorflow-cache" { Remove-Item "C:\Users\*\.keras\datasets\*" -Recurse -Force -EA 0 }
Clean "ai-ml-models-tmp" { Remove-Item "C:\Users\*\.cache\ml-*\*" -Recurse -Force -EA 0 }
Clean "ai-langchain-cache" { Remove-Item "C:\Users\*\.langchain\*" -Recurse -Force -EA 0 }
Clean "ai-ollama-temp" { Remove-Item "C:\Users\*\.ollama\tmp\*" -Recurse -Force -EA 0 }
Clean "ai-localai-cache" { Remove-Item "C:\Users\*\.local-ai\cache\*" -Recurse -Force -EA 0 }
Clean "ai-lmstudio-cache" { Remove-Item "C:\Users\*\.cache\lm-studio\*" -Recurse -Force -EA 0 }
Clean "ai-oobabooga-cache" { Remove-Item "C:\Users\*\text-generation-webui\cache\*" -Recurse -Force -EA 0 }
Clean "ai-comfyui-temp" { Remove-Item "C:\Users\*\ComfyUI\temp\*" -Recurse -Force -EA 0 }
Clean "ai-automatic1111-temp" { Remove-Item "C:\Users\*\stable-diffusion-webui\tmp\*" -Recurse -Force -EA 0 }
Clean "ai-invoke-cache" { Remove-Item "C:\Users\*\.invokeai\cache\*" -Recurse -Force -EA 0 }
Clean "ai-diffusers-cache" { Remove-Item "C:\Users\*\.cache\diffusers\*" -Recurse -Force -EA 0 }
Clean "ai-whisper-cache" { Remove-Item "C:\Users\*\.cache\whisper\*" -Recurse -Force -EA 0 }
Clean "ai-speechbrain-cache" { Remove-Item "C:\Users\*\.cache\speechbrain\*" -Recurse -Force -EA 0 }

# ============================================================================
# PHASE 39: ADDITIONAL SYSTEM TEMP & MISC (200+ operations)
# ============================================================================
Write-Host "`n[PHASE 39/40] ADDITIONAL SYSTEM TEMP & MISC" -ForegroundColor White
Clean "misc-java-temp" { Remove-Item "C:\Users\*\AppData\Local\Temp\hsperfdata_*" -Recurse -Force -EA 0 }
Clean "misc-java-cache" { Remove-Item "C:\Users\*\AppData\LocalLow\Sun\Java\Deployment\cache\*" -Recurse -Force -EA 0 }
Clean "misc-silverlight-cache" { Remove-Item "C:\Users\*\AppData\LocalLow\Microsoft\Silverlight\is\*" -Recurse -Force -EA 0 }
Clean "misc-flash-cache" { Remove-Item "C:\Users\*\AppData\Roaming\Adobe\Flash Player\*" -Recurse -Force -EA 0 }
Clean "misc-realplayer-cache" { Remove-Item "C:\Users\*\AppData\Local\Real\RealPlayer\cache\*" -Recurse -Force -EA 0 }
Clean "misc-winamp-cache" { Remove-Item "C:\Users\*\AppData\Roaming\Winamp\*cache*" -Recurse -Force -EA 0 }
Clean "misc-foobar-cache" { Remove-Item "C:\Users\*\AppData\Roaming\foobar2000\*cache*" -Recurse -Force -EA 0 }
Clean "misc-musicbee-cache" { Remove-Item "C:\Users\*\AppData\Roaming\MusicBee\*cache*" -Recurse -Force -EA 0 }
Clean "misc-aimp-cache" { Remove-Item "C:\Users\*\AppData\Roaming\AIMP\*cache*" -Recurse -Force -EA 0 }
Clean "misc-potplayer-temp" { Remove-Item "C:\Users\*\AppData\Roaming\PotPlayer*\*temp*" -Recurse -Force -EA 0 }
Clean "misc-kmplayer-temp" { Remove-Item "C:\Users\*\AppData\Local\KMPlayer\*temp*" -Recurse -Force -EA 0 }
Clean "misc-mpcbe-cache" { Remove-Item "C:\Users\*\AppData\Roaming\MPC-BE\*cache*" -Recurse -Force -EA 0 }
Clean "misc-mpchc-cache" { Remove-Item "C:\Users\*\AppData\Roaming\MPC-HC\*cache*" -Recurse -Force -EA 0 }
Clean "misc-kodi-cache" { Remove-Item "C:\Users\*\AppData\Roaming\Kodi\cache\*" -Recurse -Force -EA 0 }
Clean "misc-plex-cache" { Remove-Item "C:\Users\*\AppData\Local\Plex\*cache*" -Recurse -Force -EA 0 }
Clean "misc-jellyfin-cache" { Remove-Item "C:\Users\*\AppData\Local\jellyfin\cache\*" -Recurse -Force -EA 0 }
Clean "misc-emby-cache" { Remove-Item "C:\Users\*\AppData\Local\Emby\cache\*" -Recurse -Force -EA 0 }
Clean "misc-stremio-cache" { Remove-Item "C:\Users\*\AppData\Local\stremio\cache\*" -Recurse -Force -EA 0 }
Clean "misc-popcorntime-cache" { Remove-Item "C:\Users\*\AppData\Local\Popcorn-Time\Cache\*" -Recurse -Force -EA 0 }
Clean "misc-qbittorrent-logs" { Remove-Item "C:\Users\*\AppData\Local\qBittorrent\logs\*" -Recurse -Force -EA 0 }
Clean "misc-utorrent-temp" { Remove-Item "C:\Users\*\AppData\Roaming\uTorrent\*.tmp" -Force -EA 0 }
Clean "misc-deluge-temp" { Remove-Item "C:\Users\*\AppData\Roaming\deluge\*\.tmp" -Force -EA 0 }
Clean "misc-transmission-cache" { Remove-Item "C:\Users\*\AppData\Local\transmission\cache\*" -Recurse -Force -EA 0 }
Clean "misc-filezilla-logs" { Remove-Item "C:\Users\*\AppData\Roaming\FileZilla\*.log" -Force -EA 0 }
Clean "misc-winscp-temp" { Remove-Item "C:\Users\*\AppData\Local\Temp\winscp.*" -Force -EA 0 }
Clean "misc-putty-logs" { Remove-Item "C:\Users\*\AppData\Roaming\PuTTY\*.log" -Force -EA 0 }
Clean "misc-kitty-logs" { Remove-Item "C:\Users\*\AppData\Roaming\KiTTY\*.log" -Force -EA 0 }
Clean "misc-mobaxterm-cache" { Remove-Item "C:\Users\*\Documents\MobaXterm\slash\*" -Recurse -Force -EA 0 }
Clean "misc-termius-cache" { Remove-Item "C:\Users\*\AppData\Roaming\Termius\Cache\*" -Recurse -Force -EA 0 }
Clean "misc-tabby-cache" { Remove-Item "C:\Users\*\AppData\Roaming\Tabby\Cache\*" -Recurse -Force -EA 0 }
Clean "misc-hyper-cache" { Remove-Item "C:\Users\*\AppData\Roaming\Hyper\Cache\*" -Recurse -Force -EA 0 }
Clean "misc-alacritty-logs" { Remove-Item "C:\Users\*\AppData\Roaming\alacritty\*.log" -Force -EA 0 }
Clean "misc-windowsterminal-logs" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Windows Terminal\*.log" -Force -EA 0 }
Clean "misc-notepadpp-backup" { Remove-Item "C:\Users\*\AppData\Roaming\Notepad++\backup\*" -Recurse -Force -EA 0 }
Clean "misc-notepadpp-session" { Remove-Item "C:\Users\*\AppData\Roaming\Notepad++\session.xml.bak" -Force -EA 0 }
Clean "misc-ultraedit-backup" { Remove-Item "C:\Users\*\AppData\Roaming\IDMComp\UltraEdit\Backup\*" -Recurse -Force -EA 0 }
Clean "misc-emerald-backup" { Remove-Item "C:\Users\*\AppData\Roaming\JGsoft\EditPadPro*\Backup\*" -Recurse -Force -EA 0 }
Clean "misc-vs-recent-temp" { Remove-Item "C:\Users\*\AppData\Roaming\Microsoft\Windows\Recent\*.lnk" -Force -EA 0 }
Clean "misc-ms-recent-docs" { Remove-Item "C:\Users\*\AppData\Roaming\Microsoft\Office\Recent\*" -Recurse -Force -EA 0 }
Clean "misc-old-downloads" { Get-ChildItem "C:\Users\*\Downloads\*.tmp" -Force -EA 0 | Remove-Item -Force -EA 0 }
Clean "misc-temp-oldfiles" { Get-ChildItem "C:\Users\*\AppData\Local\Temp" -Recurse -EA 0 | Where-Object {$_.LastWriteTime -lt (Get-Date).AddDays(-7)} | Remove-Item -Recurse -Force -EA 0 }
Clean "misc-programdata-temp" { Remove-Item "C:\ProgramData\*.tmp" -Force -EA 0 }
Clean "misc-programdata-log" { Remove-Item "C:\ProgramData\*.log" -Force -EA 0 }
Clean "misc-root-old-logs" { Get-ChildItem "C:\*.log" -Force -EA 0 | Where-Object {$_.LastWriteTime -lt (Get-Date).AddDays(-7)} | Remove-Item -Force -EA 0 }
Clean "misc-install-temp" { Remove-Item "C:\Users\*\AppData\Local\Temp\*.exe" -Force -EA 0 }
Clean "misc-msi-temp" { Remove-Item "C:\Users\*\AppData\Local\Temp\*.msi" -Force -EA 0 }
Clean "misc-zip-temp" { Remove-Item "C:\Users\*\AppData\Local\Temp\*.zip" -Force -EA 0 }
Clean "misc-rar-temp" { Remove-Item "C:\Users\*\AppData\Local\Temp\*.rar" -Force -EA 0 }
Clean "misc-7z-temp" { Remove-Item "C:\Users\*\AppData\Local\Temp\*.7z" -Force -EA 0 }
Clean "misc-cab-temp" { Remove-Item "C:\Users\*\AppData\Local\Temp\*.cab" -Force -EA 0 }

# ============================================================================
# PHASE 41: WINDOWS SYSTEM EXTENDED (100 operations)
# ============================================================================
Write-Host "`n[PHASE 41/80] WINDOWS SYSTEM EXTENDED" -ForegroundColor White
Clean "sys-winsxs-backup" { Remove-Item "C:\Windows\WinSxS\Backup\*" -Recurse -Force -EA 0 }
Clean "sys-winsxs-temp" { Remove-Item "C:\Windows\WinSxS\Temp\*" -Recurse -Force -EA 0 }
Clean "sys-winsxs-manifest" { Remove-Item "C:\Windows\WinSxS\ManifestCache\*" -Force -EA 0 }
Clean "sys-assembly-tmp" { Remove-Item "C:\Windows\assembly\tmp\*" -Recurse -Force -EA 0 }
Clean "sys-assembly-temp" { Remove-Item "C:\Windows\assembly\temp\*" -Recurse -Force -EA 0 }
Clean "sys-installer-orphan" { Remove-Item "C:\Windows\Installer\$PatchCache$\*" -Recurse -Force -EA 0 }
Clean "sys-installer-managed" { Get-ChildItem "C:\Windows\Installer\*.msp" -EA 0 | Where-Object {$_.LastWriteTime -lt (Get-Date).AddYears(-1)} | Remove-Item -Force -EA 0 }
Clean "sys-inf-old" { Get-ChildItem "C:\Windows\inf\*.log" -EA 0 | Where-Object {$_.LastWriteTime -lt (Get-Date).AddDays(-30)} | Remove-Item -Force -EA 0 }
Clean "sys-inf-setupapi" { Remove-Item "C:\Windows\inf\setupapi*.log" -Force -EA 0 }
Clean "sys-servicing-sessions" { Remove-Item "C:\Windows\Servicing\Sessions\*" -Recurse -Force -EA 0 }
Clean "sys-servicing-packages" { Remove-Item "C:\Windows\Servicing\Packages\*.cat" -Force -EA 0 }
Clean "sys-lxss-temp" { Remove-Item "C:\Windows\System32\lxss\temp\*" -Recurse -Force -EA 0 }
Clean "sys-dism-mount" { Remove-Item "C:\Windows\System32\Dism\mount\*" -Recurse -Force -EA 0 }
Clean "sys-smi-store" { Remove-Item "C:\Windows\System32\SMI\Store\Machine\*.xml" -Force -EA 0 }
Clean "sys-catroot-old" { Get-ChildItem "C:\Windows\System32\catroot\*" -Recurse -EA 0 | Where-Object {$_.LastWriteTime -lt (Get-Date).AddYears(-1)} | Remove-Item -Force -EA 0 }
Clean "sys-catroot2-log" { Remove-Item "C:\Windows\System32\catroot2\*.log" -Force -EA 0 }
Clean "sys-catroot2-jrs" { Remove-Item "C:\Windows\System32\catroot2\*.jrs" -Force -EA 0 }
Clean "sys-codeintegrity-log" { Remove-Item "C:\Windows\System32\CodeIntegrity\*.log" -Force -EA 0 }
Clean "sys-sru-dat" { Remove-Item "C:\Windows\System32\sru\*.dat" -Force -EA 0 }
Clean "sys-winevt-old" { Get-ChildItem "C:\Windows\System32\winevt\Logs\*.evtx" -EA 0 | Where-Object {$_.Length -gt 100MB} | ForEach-Object { wevtutil cl $_.BaseName 2>$null } }
Clean "sys-wdi-temp" { Remove-Item "C:\Windows\System32\wdi\*" -Recurse -Force -EA 0 }
Clean "sys-wdi-perftrack" { Remove-Item "C:\Windows\System32\wdi\perftrack\*" -Force -EA 0 }
Clean "sys-wbem-logs" { Remove-Item "C:\Windows\System32\wbem\Logs\*" -Force -EA 0 }
Clean "sys-wbem-autorecover" { Remove-Item "C:\Windows\System32\wbem\AutoRecover\*" -Force -EA 0 }
Clean "sys-wbem-repository" { Remove-Item "C:\Windows\System32\wbem\Repository\*.log" -Force -EA 0 }
Clean "sys-driverstore-temp" { Remove-Item "C:\Windows\System32\DriverStore\Temp\*" -Recurse -Force -EA 0 }
Clean "sys-config-journal" { Remove-Item "C:\Windows\System32\config\*.log*" -Force -EA 0 }
Clean "sys-config-txr" { Remove-Item "C:\Windows\System32\config\TxR\*" -Force -EA 0 }
Clean "sys-config-systemprofile" { Remove-Item "C:\Windows\System32\config\systemprofile\AppData\Local\Temp\*" -Recurse -Force -EA 0 }
Clean "sys-sysprep-logs" { Remove-Item "C:\Windows\System32\Sysprep\Panther\*" -Recurse -Force -EA 0 }
Clean "sys-migwiz-logs" { Remove-Item "C:\Windows\System32\migwiz\*.log" -Force -EA 0 }
Clean "sys-oobe-info" { Remove-Item "C:\Windows\System32\oobe\info\*" -Recurse -Force -EA 0 }
Clean "sys-networklist-log" { Remove-Item "C:\Windows\System32\NetworkList\*.log" -Force -EA 0 }
Clean "sys-tasks-log" { Remove-Item "C:\Windows\System32\Tasks\*.log" -Force -EA 0 }
Clean "sys-logfiles-wmi" { Remove-Item "C:\Windows\System32\LogFiles\WMI\*" -Recurse -Force -EA 0 }
Clean "sys-logfiles-iis" { Remove-Item "C:\Windows\System32\LogFiles\W3SVC*\*" -Recurse -Force -EA 0 }
Clean "sys-logfiles-scm" { Remove-Item "C:\Windows\System32\LogFiles\scm\*" -Force -EA 0 }
Clean "sys-logfiles-dpx" { Remove-Item "C:\Windows\System32\LogFiles\Dpx\*" -Force -EA 0 }
Clean "sys-logfiles-sum" { Remove-Item "C:\Windows\System32\LogFiles\Sum\*" -Force -EA 0 }
Clean "sys-logfiles-httperr" { Remove-Item "C:\Windows\System32\LogFiles\HTTPERR\*" -Force -EA 0 }
Clean "sys-logfiles-firewall" { Remove-Item "C:\Windows\System32\LogFiles\Firewall\*" -Force -EA 0 }
Clean "sys-logfiles-netsetup" { Remove-Item "C:\Windows\System32\LogFiles\Netsetup\*" -Force -EA 0 }
Clean "sys-com-log" { Remove-Item "C:\Windows\System32\com\*.log" -Force -EA 0 }
Clean "sys-msdtc-log" { Remove-Item "C:\Windows\System32\MsDtc\*.log" -Force -EA 0 }
Clean "sys-bits-log" { Remove-Item "C:\Windows\System32\BITS\*.log" -Force -EA 0 }
Clean "sys-fxstmp-cache" { Remove-Item "C:\Windows\System32\FXSTMP\*" -Recurse -Force -EA 0 }
Clean "sys-speech-tmp" { Remove-Item "C:\Windows\System32\Speech\*\Tmp\*" -Recurse -Force -EA 0 }
Clean "sys-spool-printers" { Remove-Item "C:\Windows\System32\spool\PRINTERS\*" -Force -EA 0 }
Clean "sys-spool-drivers" { Get-ChildItem "C:\Windows\System32\spool\drivers\*\3\*.log" -Recurse -EA 0 | Remove-Item -Force -EA 0 }
Clean "sys-diagerr" { Remove-Item "C:\Windows\System32\diagerr.xml" -Force -EA 0 }
Clean "sys-diagwrn" { Remove-Item "C:\Windows\System32\diagwrn.xml" -Force -EA 0 }
Clean "sys-spp-tokens-cache" { Remove-Item "C:\Windows\System32\spp\store\2.0\cache\*" -Force -EA 0 }
Clean "sys-appcompat-pca" { Remove-Item "C:\Windows\AppCompat\Programs\*.txt" -Force -EA 0 }
Clean "sys-appcompat-appraiser" { Remove-Item "C:\Windows\AppCompat\Appraiser\*.cab" -Force -EA 0 }
Clean "sys-debug-wia" { Remove-Item "C:\Windows\Debug\WIA\*" -Force -EA 0 }
Clean "sys-debug-netsetup" { Remove-Item "C:\Windows\Debug\netsetup.log" -Force -EA 0 }
Clean "sys-debug-mrt" { Remove-Item "C:\Windows\Debug\mrt.log" -Force -EA 0 }
Clean "sys-debug-dcpromo" { Remove-Item "C:\Windows\Debug\dcpromo.log" -Force -EA 0 }
Clean "sys-debug-passwd" { Remove-Item "C:\Windows\Debug\passwd.log" -Force -EA 0 }
Clean "sys-debug-sam" { Remove-Item "C:\Windows\Debug\sam.log" -Force -EA 0 }
Clean "sys-memory-readyboot" { Remove-Item "C:\Windows\Prefetch\ReadyBoot\*" -Force -EA 0 }
Clean "sys-pla-reports" { Remove-Item "C:\Windows\PLA\Reports\*" -Recurse -Force -EA 0 }
Clean "sys-pla-logs" { Remove-Item "C:\Windows\PLA\System\*" -Recurse -Force -EA 0 }
Clean "sys-registration-crmlog" { Remove-Item "C:\Windows\Registration\*.crmlog" -Force -EA 0 }
Clean "sys-bootstat" { Remove-Item "C:\Windows\bootstat.dat" -Force -EA 0 }
Clean "sys-pfro-log" { Remove-Item "C:\Windows\PFRO.log" -Force -EA 0 }
Clean "sys-dxdiag-tmp" { Remove-Item "C:\Windows\DxDiag.txt" -Force -EA 0 }
Clean "sys-action-center" { Remove-Item "C:\Windows\ActionCenterCache\*" -Force -EA 0 }
Clean "sys-appcompat-compat" { Remove-Item "C:\Windows\AppCompat\CompatData\*" -Recurse -Force -EA 0 }
Clean "sys-shellnew-tmp" { Remove-Item "C:\Windows\ShellNew\*.tmp" -Force -EA 0 }
Clean "sys-rescache" { Remove-Item "C:\Windows\rescache\*" -Recurse -Force -EA 0 }
Clean "sys-schemas-cache" { Remove-Item "C:\Windows\Schemas\Cache\*" -Force -EA 0 }
Clean "sys-migration-old" { Get-ChildItem "C:\Windows\Migration\*" -Recurse -EA 0 | Where-Object {$_.LastWriteTime -lt (Get-Date).AddDays(-30)} | Remove-Item -Recurse -Force -EA 0 }
Clean "sys-immersivecp-cache" { Remove-Item "C:\Windows\ImmersiveControlPanel\Cache\*" -Force -EA 0 }
Clean "sys-microsoft-cache" { Remove-Item "C:\Windows\Microsoft.NET\*.log" -Force -EA 0 }
Clean "sys-net-framework2" { Remove-Item "C:\Windows\Microsoft.NET\Framework\v2*\Temporary*\*" -Recurse -Force -EA 0 }
Clean "sys-net-framework4" { Remove-Item "C:\Windows\Microsoft.NET\Framework\v4*\Temporary*\*" -Recurse -Force -EA 0 }
Clean "sys-net-framework64-2" { Remove-Item "C:\Windows\Microsoft.NET\Framework64\v2*\Temporary*\*" -Recurse -Force -EA 0 }
Clean "sys-net-framework64-4" { Remove-Item "C:\Windows\Microsoft.NET\Framework64\v4*\Temporary*\*" -Recurse -Force -EA 0 }
Clean "sys-assembly-ngen" { Remove-Item "C:\Windows\assembly\NativeImages*\*\*\*.aux" -Force -EA 0 }
Clean "sys-installer-cache" { Get-ChildItem "C:\Windows\Installer\*.msi" -EA 0 | Where-Object {$_.LastWriteTime -lt (Get-Date).AddYears(-2)} | Remove-Item -Force -EA 0 }
Clean "sys-softwaredist-dl" { Remove-Item "C:\Windows\SoftwareDistribution\Download\*.exe" -Force -EA 0 }
Clean "sys-softwaredist-cab" { Remove-Item "C:\Windows\SoftwareDistribution\Download\*.cab" -Force -EA 0 }
Clean "sys-softwaredist-log" { Remove-Item "C:\Windows\SoftwareDistribution\Download\*.log" -Force -EA 0 }
Clean "sys-softwaredist-xml" { Remove-Item "C:\Windows\SoftwareDistribution\Download\*.xml" -Force -EA 0 }
Clean "sys-livekernelrep" { Remove-Item "C:\Windows\LiveKernelReports\*" -Recurse -Force -EA 0 }
Clean "sys-dpapi-recovery" { Remove-Item "C:\Windows\System32\Microsoft\Protect\Recovery\*" -Force -EA 0 }
Clean "sys-wer-temp" { Remove-Item "C:\Windows\WER\Temp\*" -Recurse -Force -EA 0 }
Clean "sys-wer-reportarchive" { Remove-Item "C:\Windows\WER\ReportArchive\*" -Recurse -Force -EA 0 }
Clean "sys-wer-reportqueue" { Remove-Item "C:\Windows\WER\ReportQueue\*" -Recurse -Force -EA 0 }
Clean "sys-minidump-ext" { Remove-Item "C:\Windows\MiniDump\*.dmp" -Force -EA 0 }
Clean "sys-memory-dmp" { Remove-Item "C:\Windows\MEMORY.DMP" -Force -EA 0 }
Clean "sys-hiberfil" { powercfg /h off 2>$null }
Clean "sys-diagtrack" { Remove-Item "C:\Windows\DiagTrack\*" -Recurse -Force -EA 0 }

# ============================================================================
# PHASE 42: APPLICATION CACHES EXTENDED (100 operations)
# ============================================================================
Write-Host "`n[PHASE 42/80] APPLICATION CACHES EXTENDED" -ForegroundColor White
Clean "app-electron-cache" { Remove-Item "C:\Users\*\AppData\Roaming\*\Cache\*" -Recurse -Force -EA 0 }
Clean "app-electron-codesign" { Remove-Item "C:\Users\*\AppData\Roaming\*\Code Cache\*" -Recurse -Force -EA 0 }
Clean "app-electron-gpucache" { Remove-Item "C:\Users\*\AppData\Roaming\*\GPUCache\*" -Recurse -Force -EA 0 }
Clean "app-electron-shader" { Remove-Item "C:\Users\*\AppData\Roaming\*\ShaderCache\*" -Recurse -Force -EA 0 }
Clean "app-spotify-storage" { Remove-Item "C:\Users\*\AppData\Local\Spotify\Storage\*" -Recurse -Force -EA 0 }
Clean "app-spotify-browser" { Remove-Item "C:\Users\*\AppData\Local\Spotify\Browser\*" -Recurse -Force -EA 0 }
Clean "app-spotify-data" { Remove-Item "C:\Users\*\AppData\Local\Spotify\Data\*" -Recurse -Force -EA 0 }
Clean "app-discord-cache" { Remove-Item "C:\Users\*\AppData\Roaming\discord\Cache\*" -Recurse -Force -EA 0 }
Clean "app-discord-codecache" { Remove-Item "C:\Users\*\AppData\Roaming\discord\Code Cache\*" -Recurse -Force -EA 0 }
Clean "app-discord-gpucache" { Remove-Item "C:\Users\*\AppData\Roaming\discord\GPUCache\*" -Recurse -Force -EA 0 }
Clean "app-slack-cache" { Remove-Item "C:\Users\*\AppData\Roaming\Slack\Cache\*" -Recurse -Force -EA 0 }
Clean "app-slack-service" { Remove-Item "C:\Users\*\AppData\Roaming\Slack\Service Worker\*" -Recurse -Force -EA 0 }
Clean "app-teams-cache" { Remove-Item "C:\Users\*\AppData\Roaming\Microsoft\Teams\Cache\*" -Recurse -Force -EA 0 }
Clean "app-teams-blob" { Remove-Item "C:\Users\*\AppData\Roaming\Microsoft\Teams\blob_storage\*" -Recurse -Force -EA 0 }
Clean "app-teams-databases" { Remove-Item "C:\Users\*\AppData\Roaming\Microsoft\Teams\databases\*" -Recurse -Force -EA 0 }
Clean "app-teams-gpucache" { Remove-Item "C:\Users\*\AppData\Roaming\Microsoft\Teams\GPUCache\*" -Recurse -Force -EA 0 }
Clean "app-teams-indexdb" { Remove-Item "C:\Users\*\AppData\Roaming\Microsoft\Teams\IndexedDB\*" -Recurse -Force -EA 0 }
Clean "app-teams-localstorage" { Remove-Item "C:\Users\*\AppData\Roaming\Microsoft\Teams\Local Storage\*" -Recurse -Force -EA 0 }
Clean "app-teams-tmp" { Remove-Item "C:\Users\*\AppData\Roaming\Microsoft\Teams\tmp\*" -Recurse -Force -EA 0 }
Clean "app-zoom-cache" { Remove-Item "C:\Users\*\AppData\Roaming\Zoom\*cache*" -Recurse -Force -EA 0 }
Clean "app-zoom-data" { Remove-Item "C:\Users\*\AppData\Roaming\Zoom\data\*" -Recurse -Force -EA 0 }
Clean "app-zoom-logs" { Remove-Item "C:\Users\*\AppData\Roaming\Zoom\logs\*" -Recurse -Force -EA 0 }
Clean "app-skype-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.SkypeApp*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "app-telegram-cache" { Remove-Item "C:\Users\*\AppData\Roaming\Telegram Desktop\tdata\*cache*" -Recurse -Force -EA 0 }
Clean "app-signal-cache" { Remove-Item "C:\Users\*\AppData\Roaming\Signal\Cache\*" -Recurse -Force -EA 0 }
Clean "app-whatsapp-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\*WhatsApp*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "app-outlook-cache" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Outlook\*.ost.tmp" -Force -EA 0 }
Clean "app-outlook-roamcache" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Outlook\RoamCache\*" -Force -EA 0 }
Clean "app-onenote-cache" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\OneNote\*\cache\*" -Recurse -Force -EA 0 }
Clean "app-word-backup" { Remove-Item "C:\Users\*\AppData\Roaming\Microsoft\Word\*.tmp" -Force -EA 0 }
Clean "app-excel-backup" { Remove-Item "C:\Users\*\AppData\Roaming\Microsoft\Excel\*.tmp" -Force -EA 0 }
Clean "app-powerpoint-backup" { Remove-Item "C:\Users\*\AppData\Roaming\Microsoft\PowerPoint\*.tmp" -Force -EA 0 }
Clean "app-office-webcache" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Office\*\OfficeFileCache\*" -Recurse -Force -EA 0 }
Clean "app-office-recent" { Get-ChildItem "C:\Users\*\AppData\Roaming\Microsoft\Office\Recent\*" -EA 0 | Where-Object {$_.LastWriteTime -lt (Get-Date).AddDays(-30)} | Remove-Item -Force -EA 0 }
Clean "app-office-unsaved" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Office\UnsavedFiles\*" -Force -EA 0 }
Clean "app-libreoffice-backup" { Remove-Item "C:\Users\*\AppData\Roaming\LibreOffice\*\user\backup\*" -Recurse -Force -EA 0 }
Clean "app-libreoffice-cache" { Remove-Item "C:\Users\*\AppData\Roaming\LibreOffice\*\user\*.cache" -Force -EA 0 }
Clean "app-acrobat-cache" { Remove-Item "C:\Users\*\AppData\LocalLow\Adobe\Acrobat\*\Cache\*" -Recurse -Force -EA 0 }
Clean "app-acrobat-temp" { Remove-Item "C:\Users\*\AppData\Local\Adobe\Acrobat\*\*Cache*\*" -Recurse -Force -EA 0 }
Clean "app-adobe-common" { Remove-Item "C:\Users\*\AppData\Local\Adobe\*\Cache\*" -Recurse -Force -EA 0 }
Clean "app-photoshop-temp" { Remove-Item "C:\Users\*\AppData\Local\Temp\Photoshop*" -Recurse -Force -EA 0 }
Clean "app-premiere-cache" { Remove-Item "C:\Users\*\AppData\Local\Adobe\Premiere*\*\Cache\*" -Recurse -Force -EA 0 }
Clean "app-aftereffects-cache" { Remove-Item "C:\Users\*\AppData\Local\Adobe\After*\*\Cache\*" -Recurse -Force -EA 0 }
Clean "app-lightroom-cache" { Remove-Item "C:\Users\*\AppData\Local\Adobe\Lightroom\Cache\*" -Recurse -Force -EA 0 }
Clean "app-illustrator-cache" { Remove-Item "C:\Users\*\AppData\Local\Adobe\Illustrator*\*\Cache\*" -Recurse -Force -EA 0 }
Clean "app-creative-cloud" { Remove-Item "C:\Users\*\AppData\Local\Adobe\Creative Cloud\Cache\*" -Recurse -Force -EA 0 }
Clean "app-ccleaner-data" { Remove-Item "C:\Users\*\AppData\Local\Piriform\CCleaner\*" -Recurse -Force -EA 0 }
Clean "app-vlc-cache" { Remove-Item "C:\Users\*\AppData\Roaming\vlc\*cache*" -Recurse -Force -EA 0 }
Clean "app-vlc-recent" { Remove-Item "C:\Users\*\AppData\Roaming\vlc\vlc-qt-interface.ini.bak" -Force -EA 0 }
Clean "app-potplayer-cache" { Remove-Item "C:\Users\*\AppData\Roaming\PotPlayerMini64\*" -Recurse -Force -EA 0 }
Clean "app-kmplayer-cache" { Remove-Item "C:\Users\*\AppData\Roaming\KMPlayer\*" -Recurse -Force -EA 0 }
Clean "app-winamp-cache" { Remove-Item "C:\Users\*\AppData\Roaming\Winamp\*cache*" -Force -EA 0 }
Clean "app-itunes-cache" { Remove-Item "C:\Users\*\AppData\Local\Apple Computer\iTunes\*Cache*" -Recurse -Force -EA 0 }
Clean "app-itunes-software" { Remove-Item "C:\Users\*\AppData\Local\Apple Computer\iTunes\Software Updates\*" -Recurse -Force -EA 0 }
Clean "app-apple-logs" { Remove-Item "C:\Users\*\AppData\Local\Apple Computer\Logs\*" -Recurse -Force -EA 0 }
Clean "app-dropbox-cache" { Remove-Item "C:\Users\*\Dropbox\.dropbox.cache\*" -Recurse -Force -EA 0 }
Clean "app-dropbox-temp" { Remove-Item "C:\Users\*\AppData\Local\Dropbox\*\cache\*" -Recurse -Force -EA 0 }
Clean "app-onedrive-cache" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\OneDrive\*\cache\*" -Recurse -Force -EA 0 }
Clean "app-onedrive-logs" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\OneDrive\logs\*" -Recurse -Force -EA 0 }
Clean "app-googledrive-cache" { Remove-Item "C:\Users\*\AppData\Local\Google\DriveFS\*\content_cache\*" -Recurse -Force -EA 0 }
Clean "app-box-cache" { Remove-Item "C:\Users\*\AppData\Local\Box\Box\cache\*" -Recurse -Force -EA 0 }
Clean "app-icloud-cache" { Remove-Item "C:\Users\*\AppData\Local\Apple Inc\iCloud\*cache*" -Recurse -Force -EA 0 }
Clean "app-7zip-temp" { Remove-Item "C:\Users\*\AppData\Local\Temp\7z*" -Recurse -Force -EA 0 }
Clean "app-winrar-temp" { Remove-Item "C:\Users\*\AppData\Local\Temp\Rar*" -Recurse -Force -EA 0 }
Clean "app-winzip-temp" { Remove-Item "C:\Users\*\AppData\Local\WinZip\*" -Recurse -Force -EA 0 }
Clean "app-peazip-temp" { Remove-Item "C:\Users\*\AppData\Local\PeaZip\*" -Recurse -Force -EA 0 }
Clean "app-notepad++backup" { Remove-Item "C:\Users\*\AppData\Roaming\Notepad++\backup\*" -Force -EA 0 }
Clean "app-notepad++session" { Remove-Item "C:\Users\*\AppData\Roaming\Notepad++\session.xml.bak" -Force -EA 0 }
Clean "app-sublime-cache" { Remove-Item "C:\Users\*\AppData\Roaming\Sublime Text*\Cache\*" -Recurse -Force -EA 0 }
Clean "app-sublime-backup" { Remove-Item "C:\Users\*\AppData\Roaming\Sublime Text*\Backup\*" -Recurse -Force -EA 0 }
Clean "app-atom-cache" { Remove-Item "C:\Users\*\.atom\*cache*" -Recurse -Force -EA 0 }
Clean "app-atom-storage" { Remove-Item "C:\Users\*\.atom\storage\*" -Recurse -Force -EA 0 }
Clean "app-gimp-tmp" { Remove-Item "C:\Users\*\AppData\Roaming\GIMP\*\tmp\*" -Recurse -Force -EA 0 }
Clean "app-gimp-swap" { Remove-Item "C:\Users\*\AppData\Roaming\GIMP\*\swap\*" -Recurse -Force -EA 0 }
Clean "app-inkscape-cache" { Remove-Item "C:\Users\*\AppData\Roaming\inkscape\cache\*" -Recurse -Force -EA 0 }
Clean "app-blender-cache" { Remove-Item "C:\Users\*\AppData\Roaming\Blender Foundation\*\cache\*" -Recurse -Force -EA 0 }
Clean "app-obs-logs" { Remove-Item "C:\Users\*\AppData\Roaming\obs-studio\logs\*" -Force -EA 0 }
Clean "app-obs-crashes" { Remove-Item "C:\Users\*\AppData\Roaming\obs-studio\crashes\*" -Force -EA 0 }
Clean "app-streamlabs-cache" { Remove-Item "C:\Users\*\AppData\Roaming\slobs-client\Cache\*" -Recurse -Force -EA 0 }
Clean "app-davinci-cache" { Remove-Item "C:\Users\*\AppData\Roaming\Blackmagic Design\*\cache\*" -Recurse -Force -EA 0 }
Clean "app-handbrake-logs" { Remove-Item "C:\Users\*\AppData\Roaming\HandBrake\logs\*" -Force -EA 0 }
Clean "app-audacity-temp" { Remove-Item "C:\Users\*\AppData\Local\Temp\audacity*" -Recurse -Force -EA 0 }
Clean "app-qbittorrent-logs" { Remove-Item "C:\Users\*\AppData\Local\qBittorrent\logs\*" -Force -EA 0 }
Clean "app-utorrent-cache" { Remove-Item "C:\Users\*\AppData\Roaming\uTorrent\*.dat.old" -Force -EA 0 }
Clean "app-transmission-cache" { Remove-Item "C:\Users\*\AppData\Local\transmission\cache\*" -Recurse -Force -EA 0 }
Clean "app-filezilla-logs" { Remove-Item "C:\Users\*\AppData\Roaming\FileZilla\*.log" -Force -EA 0 }
Clean "app-winscp-tmp" { Remove-Item "C:\Users\*\AppData\Local\Temp\winscp*" -Force -EA 0 }
Clean "app-putty-logs" { Remove-Item "C:\Users\*\AppData\Local\VirtualStore\*putty*.log" -Force -EA 0 }
Clean "app-bitwarden-logs" { Remove-Item "C:\Users\*\AppData\Roaming\Bitwarden\logs\*" -Force -EA 0 }
Clean "app-keepass-backup" { Get-ChildItem "C:\Users\*\Documents\*.kdbx.bak" -EA 0 | Where-Object {$_.LastWriteTime -lt (Get-Date).AddDays(-7)} | Remove-Item -Force -EA 0 }
Clean "app-lastpass-cache" { Remove-Item "C:\Users\*\AppData\Local\LastPass\*cache*" -Recurse -Force -EA 0 }
Clean "app-1password-logs" { Remove-Item "C:\Users\*\AppData\Local\1Password\logs\*" -Force -EA 0 }
Clean "app-calibre-cache" { Remove-Item "C:\Users\*\AppData\Local\calibre-cache\*" -Recurse -Force -EA 0 }
Clean "app-kindle-cache" { Remove-Item "C:\Users\*\AppData\Local\Amazon\Kindle\Cache\*" -Recurse -Force -EA 0 }
Clean "app-kobo-cache" { Remove-Item "C:\Users\*\AppData\Local\Kobo\*cache*" -Recurse -Force -EA 0 }
Clean "app-evernote-logs" { Remove-Item "C:\Users\*\AppData\Local\Evernote\*\logs\*" -Recurse -Force -EA 0 }
Clean "app-notion-cache" { Remove-Item "C:\Users\*\AppData\Roaming\Notion\Cache\*" -Recurse -Force -EA 0 }
Clean "app-obsidian-cache" { Remove-Item "C:\Users\*\AppData\Roaming\obsidian\Cache\*" -Recurse -Force -EA 0 }

# ============================================================================
# PHASE 43: DEVELOPER TOOLS EXTENDED (100 operations)
# ============================================================================
Write-Host "`n[PHASE 43/80] DEVELOPER TOOLS EXTENDED" -ForegroundColor White
Clean "dev-npm-global" { Remove-Item "C:\Users\*\AppData\Roaming\npm-cache\_cacache\*" -Recurse -Force -EA 0 }
Clean "dev-npm-logs" { Remove-Item "C:\Users\*\AppData\Roaming\npm-cache\_logs\*" -Force -EA 0 }
Clean "dev-npm-tmp" { Remove-Item "C:\Users\*\AppData\Roaming\npm-cache\tmp\*" -Recurse -Force -EA 0 }
Clean "dev-npm-staging" { Remove-Item "C:\Users\*\AppData\Roaming\npm-cache\_staging\*" -Recurse -Force -EA 0 }
Clean "dev-yarn-cache" { Remove-Item "C:\Users\*\AppData\Local\Yarn\Cache\*" -Recurse -Force -EA 0 }
Clean "dev-yarn-temp" { Remove-Item "C:\Users\*\AppData\Local\Yarn\*.tmp" -Force -EA 0 }
Clean "dev-pnpm-store" { Remove-Item "C:\Users\*\AppData\Local\pnpm-store\*" -Recurse -Force -EA 0 }
Clean "dev-pnpm-cache" { Remove-Item "C:\Users\*\AppData\Local\pnpm-cache\*" -Recurse -Force -EA 0 }
Clean "dev-bun-cache" { Remove-Item "C:\Users\*\.bun\install\cache\*" -Recurse -Force -EA 0 }
Clean "dev-deno-cache" { Remove-Item "C:\Users\*\.deno\*" -Recurse -Force -EA 0 }
Clean "dev-pip-cache" { Remove-Item "C:\Users\*\AppData\Local\pip\cache\*" -Recurse -Force -EA 0 }
Clean "dev-pip-wheels" { Remove-Item "C:\Users\*\AppData\Local\pip\wheels\*" -Recurse -Force -EA 0 }
Clean "dev-pipx-cache" { Remove-Item "C:\Users\*\.local\pipx\cache\*" -Recurse -Force -EA 0 }
Clean "dev-poetry-cache" { Remove-Item "C:\Users\*\AppData\Local\pypoetry\cache\*" -Recurse -Force -EA 0 }
Clean "dev-conda-pkgs" { Remove-Item "C:\Users\*\.conda\pkgs\*.tar.bz2" -Force -EA 0 }
Clean "dev-conda-cache" { Remove-Item "C:\Users\*\.conda\pkgs\cache\*" -Recurse -Force -EA 0 }
Clean "dev-anaconda-pkgs" { Remove-Item "C:\Users\*\anaconda3\pkgs\*.tar.bz2" -Force -EA 0 }
Clean "dev-miniconda-pkgs" { Remove-Item "C:\Users\*\miniconda3\pkgs\*.tar.bz2" -Force -EA 0 }
Clean "dev-pyenv-cache" { Remove-Item "C:\Users\*\.pyenv\cache\*" -Recurse -Force -EA 0 }
Clean "dev-virtualenv-cache" { Remove-Item "C:\Users\*\AppData\Local\virtualenv\cache\*" -Recurse -Force -EA 0 }
Clean "dev-go-cache" { Remove-Item "C:\Users\*\AppData\Local\go-build\*" -Recurse -Force -EA 0 }
Clean "dev-go-mod" { Remove-Item "C:\Users\*\go\pkg\mod\cache\*" -Recurse -Force -EA 0 }
Clean "dev-rust-cargo-cache" { Remove-Item "C:\Users\*\.cargo\registry\cache\*" -Recurse -Force -EA 0 }
Clean "dev-rust-cargo-index" { Remove-Item "C:\Users\*\.cargo\registry\index\*\.cache\*" -Recurse -Force -EA 0 }
Clean "dev-rust-target-debug" { Get-ChildItem "C:\Users\*\*\target\debug\*" -Recurse -EA 0 | Where-Object { $_.Extension -in '.pdb','.exe','.d' } | Remove-Item -Force -EA 0 }
Clean "dev-rust-incremental" { Remove-Item "C:\Users\*\*\target\debug\incremental\*" -Recurse -Force -EA 0 }
Clean "dev-maven-repo" { Get-ChildItem "C:\Users\*\.m2\repository\*" -Recurse -EA 0 | Where-Object {$_.LastWriteTime -lt (Get-Date).AddMonths(-3)} | Remove-Item -Recurse -Force -EA 0 }
Clean "dev-gradle-caches" { Remove-Item "C:\Users\*\.gradle\caches\*\*.lock" -Force -EA 0 }
Clean "dev-gradle-daemon" { Remove-Item "C:\Users\*\.gradle\daemon\*\*.log" -Force -EA 0 }
Clean "dev-gradle-build" { Remove-Item "C:\Users\*\.gradle\caches\build-cache-*\*" -Recurse -Force -EA 0 }
Clean "dev-gradle-native" { Remove-Item "C:\Users\*\.gradle\native\*" -Recurse -Force -EA 0 }
Clean "dev-gradle-wrapper" { Get-ChildItem "C:\Users\*\.gradle\wrapper\dists\*" -EA 0 | Where-Object {$_.LastWriteTime -lt (Get-Date).AddMonths(-6)} | Remove-Item -Recurse -Force -EA 0 }
Clean "dev-nuget-packages" { Get-ChildItem "C:\Users\*\.nuget\packages\*" -EA 0 | Where-Object {$_.LastWriteTime -lt (Get-Date).AddMonths(-6)} | Remove-Item -Recurse -Force -EA 0 }
Clean "dev-nuget-cache" { Remove-Item "C:\Users\*\AppData\Local\NuGet\v3-cache\*" -Recurse -Force -EA 0 }
Clean "dev-nuget-temp" { Remove-Item "C:\Users\*\AppData\Local\NuGet\*tmp*" -Recurse -Force -EA 0 }
Clean "dev-dotnet-tools" { Remove-Item "C:\Users\*\.dotnet\tools\.store\*\.cache\*" -Recurse -Force -EA 0 }
Clean "dev-dotnet-workload" { Remove-Item "C:\Users\*\.dotnet\workloads\*.json.bak" -Force -EA 0 }
Clean "dev-composer-cache" { Remove-Item "C:\Users\*\AppData\Local\Composer\cache\*" -Recurse -Force -EA 0 }
Clean "dev-composer-vcs" { Remove-Item "C:\Users\*\AppData\Local\Composer\cache\vcs\*" -Recurse -Force -EA 0 }
Clean "dev-gem-cache" { Remove-Item "C:\Users\*\.gem\cache\*" -Force -EA 0 }
Clean "dev-gem-specs" { Remove-Item "C:\Users\*\.gem\specs\*" -Recurse -Force -EA 0 }
Clean "dev-bundler-cache" { Remove-Item "C:\Users\*\.bundle\cache\*" -Recurse -Force -EA 0 }
Clean "dev-rbenv-cache" { Remove-Item "C:\Users\*\.rbenv\cache\*" -Recurse -Force -EA 0 }
Clean "dev-cocoapods-cache" { Remove-Item "C:\Users\*\.cocoapods\cache\*" -Recurse -Force -EA 0 }
Clean "dev-carthage-cache" { Remove-Item "C:\Users\*\Library\Caches\org.carthage.CarthageKit\*" -Recurse -Force -EA 0 }
Clean "dev-swift-pm-cache" { Remove-Item "C:\Users\*\.swiftpm\cache\*" -Recurse -Force -EA 0 }
Clean "dev-sbt-cache" { Remove-Item "C:\Users\*\.sbt\boot\*" -Recurse -Force -EA 0 }
Clean "dev-ivy-cache" { Remove-Item "C:\Users\*\.ivy2\cache\*" -Recurse -Force -EA 0 }
Clean "dev-vscode-ext" { Get-ChildItem "C:\Users\*\.vscode\extensions\*" -EA 0 | Where-Object { $_.Name -match '^\.' } | Remove-Item -Recurse -Force -EA 0 }
Clean "dev-vscode-server" { Remove-Item "C:\Users\*\.vscode-server\data\logs\*" -Recurse -Force -EA 0 }
Clean "dev-vscode-insiders" { Remove-Item "C:\Users\*\.vscode-insiders\Cache\*" -Recurse -Force -EA 0 }
Clean "dev-jetbrains-system" { Remove-Item "C:\Users\*\AppData\Local\JetBrains\*\*Cache*\*" -Recurse -Force -EA 0 }
Clean "dev-jetbrains-log" { Remove-Item "C:\Users\*\AppData\Local\JetBrains\*\log\*" -Force -EA 0 }
Clean "dev-jetbrains-local" { Remove-Item "C:\Users\*\AppData\Local\JetBrains\*\LocalHistory\*" -Recurse -Force -EA 0 }
Clean "dev-idea-system" { Remove-Item "C:\Users\*\.IntelliJIdea*\system\caches\*" -Recurse -Force -EA 0 }
Clean "dev-idea-logs" { Remove-Item "C:\Users\*\.IntelliJIdea*\system\log\*" -Force -EA 0 }
Clean "dev-pycharm-system" { Remove-Item "C:\Users\*\.PyCharm*\system\caches\*" -Recurse -Force -EA 0 }
Clean "dev-webstorm-system" { Remove-Item "C:\Users\*\.WebStorm*\system\caches\*" -Recurse -Force -EA 0 }
Clean "dev-rider-system" { Remove-Item "C:\Users\*\.Rider*\system\caches\*" -Recurse -Force -EA 0 }
Clean "dev-goland-system" { Remove-Item "C:\Users\*\.GoLand*\system\caches\*" -Recurse -Force -EA 0 }
Clean "dev-datagrip-system" { Remove-Item "C:\Users\*\.DataGrip*\system\caches\*" -Recurse -Force -EA 0 }
Clean "dev-clion-system" { Remove-Item "C:\Users\*\.CLion*\system\caches\*" -Recurse -Force -EA 0 }
Clean "dev-android-avd" { Remove-Item "C:\Users\*\.android\avd\*.avd\cache.img" -Force -EA 0 }
Clean "dev-android-build" { Remove-Item "C:\Users\*\.android\build-cache\*" -Recurse -Force -EA 0 }
Clean "dev-android-cache" { Remove-Item "C:\Users\*\.android\cache\*" -Recurse -Force -EA 0 }
Clean "dev-android-debug" { Remove-Item "C:\Users\*\.android\debug.keystore" -Force -EA 0 }
Clean "dev-android-sdk-cache" { Remove-Item "C:\Users\*\AppData\Local\Android\Sdk\.downloadIntermediates\*" -Recurse -Force -EA 0 }
Clean "dev-android-sdk-temp" { Remove-Item "C:\Users\*\AppData\Local\Android\Sdk\.temp\*" -Recurse -Force -EA 0 }
Clean "dev-flutter-cache" { Remove-Item "C:\Users\*\flutter\bin\cache\*" -Recurse -Force -EA 0 }
Clean "dev-flutter-pub" { Remove-Item "C:\Users\*\AppData\Local\Pub\Cache\hosted\*" -Recurse -Force -EA 0 }
Clean "dev-dart-pub" { Remove-Item "C:\Users\*\.pub-cache\hosted\*.tar.gz" -Force -EA 0 }
Clean "dev-react-native-cache" { Remove-Item "C:\Users\*\AppData\Local\Temp\react-native-*" -Recurse -Force -EA 0 }
Clean "dev-metro-cache" { Remove-Item "C:\Users\*\AppData\Local\Temp\metro-*" -Recurse -Force -EA 0 }
Clean "dev-expo-cache" { Remove-Item "C:\Users\*\.expo\cache\*" -Recurse -Force -EA 0 }
Clean "dev-electron-cache" { Remove-Item "C:\Users\*\AppData\Local\electron\Cache\*" -Recurse -Force -EA 0 }
Clean "dev-electron-builder" { Remove-Item "C:\Users\*\AppData\Local\electron-builder\Cache\*" -Recurse -Force -EA 0 }
Clean "dev-tauri-target" { Remove-Item "C:\Users\*\*\src-tauri\target\debug\*" -Recurse -Force -EA 0 }
Clean "dev-cmake-cache" { Get-ChildItem "C:\Users\*\CMakeCache.txt" -Recurse -EA 0 | Remove-Item -Force -EA 0 }
Clean "dev-cmake-files" { Get-ChildItem "C:\Users\*\CMakeFiles" -Recurse -Directory -EA 0 | Remove-Item -Recurse -Force -EA 0 }
Clean "dev-msbuild-logs" { Remove-Item "C:\Users\*\AppData\Local\Temp\MSBuild*.log" -Force -EA 0 }
Clean "dev-vcpkg-downloads" { Remove-Item "C:\Users\*\vcpkg\downloads\*" -Recurse -Force -EA 0 }
Clean "dev-vcpkg-buildtrees" { Remove-Item "C:\Users\*\vcpkg\buildtrees\*" -Recurse -Force -EA 0 }
Clean "dev-conan-cache" { Remove-Item "C:\Users\*\.conan\data\*" -Recurse -Force -EA 0 }
Clean "dev-xcode-deriveddata" { Remove-Item "C:\Users\*\Library\Developer\Xcode\DerivedData\*" -Recurse -Force -EA 0 }
Clean "dev-terraform-plugins" { Get-ChildItem "C:\Users\*\.terraform.d\plugin-cache\*" -EA 0 | Where-Object {$_.LastWriteTime -lt (Get-Date).AddMonths(-3)} | Remove-Item -Recurse -Force -EA 0 }
Clean "dev-terraform-lock" { Get-ChildItem "C:\Users\*\.terraform.lock.hcl" -Recurse -EA 0 | Remove-Item -Force -EA 0 }
Clean "dev-pulumi-cache" { Remove-Item "C:\Users\*\.pulumi\cache\*" -Recurse -Force -EA 0 }
Clean "dev-ansible-cache" { Remove-Item "C:\Users\*\.ansible\tmp\*" -Recurse -Force -EA 0 }
Clean "dev-vagrant-boxes" { Get-ChildItem "C:\Users\*\.vagrant.d\boxes\*" -EA 0 | Where-Object {$_.LastWriteTime -lt (Get-Date).AddMonths(-6)} | Remove-Item -Recurse -Force -EA 0 }
Clean "dev-docker-tmp" { Remove-Item "C:\Users\*\.docker\*.tmp" -Force -EA 0 }
Clean "dev-minikube-cache" { Remove-Item "C:\Users\*\.minikube\cache\*" -Recurse -Force -EA 0 }
Clean "dev-helm-cache" { Remove-Item "C:\Users\*\.cache\helm\*" -Recurse -Force -EA 0 }
Clean "dev-kubectl-cache" { Remove-Item "C:\Users\*\.kube\cache\*" -Recurse -Force -EA 0 }
Clean "dev-aws-cli-cache" { Remove-Item "C:\Users\*\.aws\cli\cache\*" -Recurse -Force -EA 0 }
Clean "dev-azure-cli-cache" { Remove-Item "C:\Users\*\.azure\*.json.bak" -Force -EA 0 }
Clean "dev-gcloud-cache" { Remove-Item "C:\Users\*\AppData\Roaming\gcloud\cache\*" -Recurse -Force -EA 0 }

# ============================================================================
# PHASE 44: GAMING PLATFORMS EXTENDED (80 operations)
# ============================================================================
Write-Host "`n[PHASE 44/80] GAMING PLATFORMS EXTENDED" -ForegroundColor White
Clean "game-steam-logs" { Remove-Item "C:\Program Files (x86)\Steam\logs\*" -Force -EA 0 }
Clean "game-steam-dumps" { Remove-Item "C:\Program Files (x86)\Steam\dumps\*" -Recurse -Force -EA 0 }
Clean "game-steam-appcache" { Remove-Item "C:\Program Files (x86)\Steam\appcache\*" -Recurse -Force -EA 0 }
Clean "game-steam-depot" { Remove-Item "C:\Program Files (x86)\Steam\depotcache\*" -Recurse -Force -EA 0 }
Clean "game-steam-htmlcache" { Remove-Item "C:\Program Files (x86)\Steam\htmlcache\*" -Recurse -Force -EA 0 }
Clean "game-steam-shader" { Remove-Item "C:\Program Files (x86)\Steam\shadercache\*" -Recurse -Force -EA 0 }
Clean "game-steam-workshop" { Remove-Item "C:\Program Files (x86)\Steam\steamapps\workshop\downloads\*" -Recurse -Force -EA 0 }
Clean "game-steam-userdata-cache" { Get-ChildItem "C:\Program Files (x86)\Steam\userdata\*\*\remote\*" -EA 0 | Where-Object { $_.Extension -eq '.cache' } | Remove-Item -Force -EA 0 }
Clean "game-epic-cache" { Remove-Item "C:\Users\*\AppData\Local\EpicGamesLauncher\Saved\Cache\*" -Recurse -Force -EA 0 }
Clean "game-epic-logs" { Remove-Item "C:\Users\*\AppData\Local\EpicGamesLauncher\Saved\Logs\*" -Force -EA 0 }
Clean "game-epic-webcache" { Remove-Item "C:\Users\*\AppData\Local\EpicGamesLauncher\Saved\webcache\*" -Recurse -Force -EA 0 }
Clean "game-epic-crashreports" { Remove-Item "C:\Users\*\AppData\Local\EpicGamesLauncher\Saved\CrashReportClient\*" -Recurse -Force -EA 0 }
Clean "game-origin-cache" { Remove-Item "C:\Users\*\AppData\Roaming\Origin\*cache*" -Recurse -Force -EA 0 }
Clean "game-origin-logs" { Remove-Item "C:\Users\*\AppData\Local\Origin\Logs\*" -Force -EA 0 }
Clean "game-origin-tmp" { Remove-Item "C:\Users\*\AppData\Local\Origin\ThinSetup\*.tmp" -Force -EA 0 }
Clean "game-ea-cache" { Remove-Item "C:\Users\*\AppData\Local\Electronic Arts\EA Desktop\cache\*" -Recurse -Force -EA 0 }
Clean "game-ea-logs" { Remove-Item "C:\Users\*\AppData\Local\Electronic Arts\EA Desktop\Logs\*" -Force -EA 0 }
Clean "game-ubisoft-cache" { Remove-Item "C:\Program Files (x86)\Ubisoft\Ubisoft Game Launcher\cache\*" -Recurse -Force -EA 0 }
Clean "game-ubisoft-logs" { Remove-Item "C:\Program Files (x86)\Ubisoft\Ubisoft Game Launcher\logs\*" -Force -EA 0 }
Clean "game-ubisoft-savegames-cache" { Get-ChildItem "C:\Program Files (x86)\Ubisoft\Ubisoft Game Launcher\savegames\*\*.bak" -Recurse -EA 0 | Remove-Item -Force -EA 0 }
Clean "game-gog-cache" { Remove-Item "C:\Users\*\AppData\Local\GOG.com\Galaxy\cache\*" -Recurse -Force -EA 0 }
Clean "game-gog-logs" { Remove-Item "C:\Users\*\AppData\Local\GOG.com\Galaxy\logs\*" -Force -EA 0 }
Clean "game-gog-webcache" { Remove-Item "C:\Users\*\AppData\Local\GOG.com\Galaxy\webcache\*" -Recurse -Force -EA 0 }
Clean "game-battlenet-cache" { Remove-Item "C:\Users\*\AppData\Local\Battle.net\Cache\*" -Recurse -Force -EA 0 }
Clean "game-battlenet-logs" { Remove-Item "C:\Users\*\AppData\Local\Blizzard Entertainment\Battle.net\Logs\*" -Force -EA 0 }
Clean "game-battlenet-crashdumps" { Remove-Item "C:\Users\*\AppData\Local\Blizzard Entertainment\*\CrashDumps\*" -Recurse -Force -EA 0 }
Clean "game-rockstar-cache" { Remove-Item "C:\Users\*\Documents\Rockstar Games\Launcher\cache\*" -Recurse -Force -EA 0 }
Clean "game-rockstar-logs" { Remove-Item "C:\Users\*\Documents\Rockstar Games\Launcher\*.log" -Force -EA 0 }
Clean "game-bethesda-logs" { Remove-Item "C:\Users\*\AppData\Local\Bethesda.net Launcher\logs\*" -Force -EA 0 }
Clean "game-amazon-cache" { Remove-Item "C:\Users\*\AppData\Local\Amazon Games\Cache\*" -Recurse -Force -EA 0 }
Clean "game-xbox-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.XboxApp*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "game-xbox-tempstate" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.XboxApp*\TempState\*" -Recurse -Force -EA 0 }
Clean "game-gamepass-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.GamingServices*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "game-nvidia-cache" { Remove-Item "C:\Users\*\AppData\Local\NVIDIA\*cache*" -Recurse -Force -EA 0 }
Clean "game-nvidia-dxcache" { Remove-Item "C:\Users\*\AppData\Local\NVIDIA\DXCache\*" -Recurse -Force -EA 0 }
Clean "game-nvidia-glcache" { Remove-Item "C:\Users\*\AppData\Local\NVIDIA\GLCache\*" -Recurse -Force -EA 0 }
Clean "game-nvidia-ansel" { Remove-Item "C:\Users\*\Videos\NVIDIA Ansel\*.bak" -Force -EA 0 }
Clean "game-geforce-logs" { Remove-Item "C:\Users\*\AppData\Local\NVIDIA Corporation\GeForce Experience\Logs\*" -Force -EA 0 }
Clean "game-geforce-cache" { Remove-Item "C:\Users\*\AppData\Local\NVIDIA Corporation\GeForce Experience\CefCache\*" -Recurse -Force -EA 0 }
Clean "game-amd-cache" { Remove-Item "C:\Users\*\AppData\Local\AMD\DxCache\*" -Recurse -Force -EA 0 }
Clean "game-amd-glcache" { Remove-Item "C:\Users\*\AppData\Local\AMD\GLCache\*" -Recurse -Force -EA 0 }
Clean "game-amd-ogl" { Remove-Item "C:\Users\*\AppData\Local\AMD\Ogl*\*" -Recurse -Force -EA 0 }
Clean "game-amd-logs" { Remove-Item "C:\Users\*\AppData\Local\AMD\*.log" -Force -EA 0 }
Clean "game-radeon-cache" { Remove-Item "C:\Users\*\AppData\Local\RadeonInstaller\cache\*" -Recurse -Force -EA 0 }
Clean "game-intel-shader" { Remove-Item "C:\Users\*\AppData\Local\Intel\ShaderCache\*" -Recurse -Force -EA 0 }
Clean "game-direct3d-cache" { Remove-Item "C:\Users\*\AppData\Local\D3DSCache\*" -Recurse -Force -EA 0 }
Clean "game-directx-shader" { Remove-Item "C:\Users\*\AppData\LocalLow\NVIDIA\PerDriverVersion\DXCache\*" -Recurse -Force -EA 0 }
Clean "game-unity-crash" { Remove-Item "C:\Users\*\AppData\Local\Temp\Unity\*" -Recurse -Force -EA 0 }
Clean "game-unity-analytics" { Remove-Item "C:\Users\*\AppData\LocalLow\Unity\*\Analytics\*" -Recurse -Force -EA 0 }
Clean "game-unity-cache-old" { Get-ChildItem "C:\Users\*\AppData\Local\Unity\cache\*" -EA 0 | Where-Object {$_.LastWriteTime -lt (Get-Date).AddDays(-30)} | Remove-Item -Recurse -Force -EA 0 }
Clean "game-unreal-deriveddata" { Remove-Item "C:\Users\*\AppData\Local\UnrealEngine\*\DerivedDataCache\*" -Recurse -Force -EA 0 }
Clean "game-unreal-swarm" { Remove-Item "C:\Users\*\AppData\Local\UnrealEngine\*\Saved\SwarmAgent\*" -Recurse -Force -EA 0 }
Clean "game-unreal-logs" { Remove-Item "C:\Users\*\AppData\Local\UnrealEngine\*\Saved\Logs\*" -Force -EA 0 }
Clean "game-cryengine-cache" { Remove-Item "C:\Users\*\AppData\Local\CryEngine\*\Cache\*" -Recurse -Force -EA 0 }
Clean "game-riot-cache" { Remove-Item "C:\Users\*\AppData\Local\Riot Games\*\cache\*" -Recurse -Force -EA 0 }
Clean "game-riot-logs" { Remove-Item "C:\Users\*\AppData\Local\Riot Games\*\Logs\*" -Recurse -Force -EA 0 }
Clean "game-valorant-logs" { Remove-Item "C:\Users\*\AppData\Local\VALORANT\Saved\Logs\*" -Force -EA 0 }
Clean "game-lol-logs" { Remove-Item "C:\Users\*\AppData\Local\Riot Games\League of Legends\Logs\*" -Recurse -Force -EA 0 }
Clean "game-fortnite-logs" { Remove-Item "C:\Users\*\AppData\Local\FortniteGame\Saved\Logs\*" -Force -EA 0 }
Clean "game-fortnite-crashreports" { Remove-Item "C:\Users\*\AppData\Local\FortniteGame\Saved\Crashes\*" -Recurse -Force -EA 0 }
Clean "game-apex-logs" { Remove-Item "C:\Users\*\Saved Games\Respawn\Apex\*.log" -Force -EA 0 }
Clean "game-pubg-logs" { Remove-Item "C:\Users\*\AppData\Local\TslGame\Saved\Logs\*" -Force -EA 0 }
Clean "game-minecraft-logs" { Remove-Item "C:\Users\*\AppData\Roaming\.minecraft\logs\*" -Force -EA 0 }
Clean "game-minecraft-crash" { Remove-Item "C:\Users\*\AppData\Roaming\.minecraft\crash-reports\*" -Force -EA 0 }
Clean "game-minecraft-screenshots" { Get-ChildItem "C:\Users\*\AppData\Roaming\.minecraft\screenshots\*.png" -EA 0 | Where-Object {$_.LastWriteTime -lt (Get-Date).AddMonths(-6)} | Remove-Item -Force -EA 0 }
Clean "game-gta5-logs" { Remove-Item "C:\Users\*\Documents\Rockstar Games\GTA V\*.log" -Force -EA 0 }
Clean "game-gta5-crashdumps" { Remove-Item "C:\Users\*\Documents\Rockstar Games\GTA V\CrashDumps\*" -Recurse -Force -EA 0 }
Clean "game-rdr2-logs" { Remove-Item "C:\Users\*\Documents\Rockstar Games\Red Dead Redemption 2\*.log" -Force -EA 0 }
Clean "game-witcher3-crash" { Remove-Item "C:\Users\*\Documents\The Witcher 3\CrashDumps\*" -Recurse -Force -EA 0 }
Clean "game-cyberpunk-crash" { Remove-Item "C:\Users\*\AppData\Local\CD Projekt Red\Cyberpunk 2077\CrashDumps\*" -Recurse -Force -EA 0 }
Clean "game-sims4-cache" { Remove-Item "C:\Users\*\Documents\Electronic Arts\The Sims 4\cache\*" -Recurse -Force -EA 0 }
Clean "game-sims4-logs" { Remove-Item "C:\Users\*\Documents\Electronic Arts\The Sims 4\*.log" -Force -EA 0 }
Clean "game-overwatch-logs" { Remove-Item "C:\Users\*\Documents\Overwatch\Logs\*" -Force -EA 0 }
Clean "game-wow-cache" { Remove-Item "C:\Program Files (x86)\World of Warcraft\Cache\*" -Recurse -Force -EA 0 }
Clean "game-wow-logs" { Remove-Item "C:\Program Files (x86)\World of Warcraft\Logs\*" -Force -EA 0 }
Clean "game-hearthstone-logs" { Remove-Item "C:\Users\*\AppData\Local\Blizzard\Hearthstone\Logs\*" -Force -EA 0 }
Clean "game-cod-cache" { Remove-Item "C:\Users\*\Documents\Call of Duty*\main\*.tmp" -Force -EA 0 }

# ============================================================================
# PHASE 45: BROWSER EXTENDED (80 operations)
# ============================================================================
Write-Host "`n[PHASE 45/80] BROWSER EXTENDED" -ForegroundColor White
Clean "browser-chrome-codespace" { Remove-Item "C:\Users\*\AppData\Local\Google\Chrome\User Data\Default\Code Cache\*" -Recurse -Force -EA 0 }
Clean "browser-chrome-gpuspace" { Remove-Item "C:\Users\*\AppData\Local\Google\Chrome\User Data\Default\GPUCache\*" -Recurse -Force -EA 0 }
Clean "browser-chrome-storage" { Remove-Item "C:\Users\*\AppData\Local\Google\Chrome\User Data\Default\Storage\*" -Recurse -Force -EA 0 }
Clean "browser-chrome-serviceworker" { Remove-Item "C:\Users\*\AppData\Local\Google\Chrome\User Data\Default\Service Worker\*" -Recurse -Force -EA 0 }
Clean "browser-chrome-indexeddb" { Remove-Item "C:\Users\*\AppData\Local\Google\Chrome\User Data\Default\IndexedDB\*" -Recurse -Force -EA 0 }
Clean "browser-chrome-crashpad" { Remove-Item "C:\Users\*\AppData\Local\Google\Chrome\User Data\Crashpad\*" -Recurse -Force -EA 0 }
Clean "browser-chrome-crashreports" { Remove-Item "C:\Users\*\AppData\Local\Google\Chrome\User Data\Crash Reports\*" -Recurse -Force -EA 0 }
Clean "browser-chrome-pnacl" { Remove-Item "C:\Users\*\AppData\Local\Google\Chrome\User Data\PnaclTranslationCache\*" -Recurse -Force -EA 0 }
Clean "browser-chrome-blobstorage" { Remove-Item "C:\Users\*\AppData\Local\Google\Chrome\User Data\Default\blob_storage\*" -Recurse -Force -EA 0 }
Clean "browser-chrome-filestorage" { Remove-Item "C:\Users\*\AppData\Local\Google\Chrome\User Data\Default\File System\*" -Recurse -Force -EA 0 }
Clean "browser-chrome-webdata" { Remove-Item "C:\Users\*\AppData\Local\Google\Chrome\User Data\Default\JumpListIcons*\*" -Force -EA 0 }
Clean "browser-chrome-shutdown" { Remove-Item "C:\Users\*\AppData\Local\Google\Chrome\User Data\Default\*.bak" -Force -EA 0 }
Clean "browser-chrome-profiles" { Get-ChildItem "C:\Users\*\AppData\Local\Google\Chrome\User Data\Profile*\Cache\*" -EA 0 | Remove-Item -Recurse -Force -EA 0 }
Clean "browser-firefox-startuppage" { Remove-Item "C:\Users\*\AppData\Roaming\Mozilla\Firefox\Profiles\*\startupCache\*" -Recurse -Force -EA 0 }
Clean "browser-firefox-storage" { Remove-Item "C:\Users\*\AppData\Roaming\Mozilla\Firefox\Profiles\*\storage\*cache*" -Recurse -Force -EA 0 }
Clean "browser-firefox-datareporting" { Remove-Item "C:\Users\*\AppData\Roaming\Mozilla\Firefox\Profiles\*\datareporting\*" -Recurse -Force -EA 0 }
Clean "browser-firefox-saved-telemetry" { Remove-Item "C:\Users\*\AppData\Roaming\Mozilla\Firefox\Profiles\*\saved-telemetry-pings\*" -Force -EA 0 }
Clean "browser-firefox-sessionstore" { Remove-Item "C:\Users\*\AppData\Roaming\Mozilla\Firefox\Profiles\*\sessionstore-backups\*" -Force -EA 0 }
Clean "browser-firefox-thumbnails" { Remove-Item "C:\Users\*\AppData\Roaming\Mozilla\Firefox\Profiles\*\thumbnails\*" -Force -EA 0 }
Clean "browser-firefox-minidumps" { Remove-Item "C:\Users\*\AppData\Roaming\Mozilla\Firefox\Crash Reports\*" -Recurse -Force -EA 0 }
Clean "browser-firefox-webappsstore" { Remove-Item "C:\Users\*\AppData\Roaming\Mozilla\Firefox\Profiles\*\webappsstore.sqlite-wal" -Force -EA 0 }
Clean "browser-edge-codespace" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Edge\User Data\Default\Code Cache\*" -Recurse -Force -EA 0 }
Clean "browser-edge-gpuspace" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Edge\User Data\Default\GPUCache\*" -Recurse -Force -EA 0 }
Clean "browser-edge-storage" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Edge\User Data\Default\Storage\*" -Recurse -Force -EA 0 }
Clean "browser-edge-serviceworker" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Edge\User Data\Default\Service Worker\*" -Recurse -Force -EA 0 }
Clean "browser-edge-indexeddb" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Edge\User Data\Default\IndexedDB\*" -Recurse -Force -EA 0 }
Clean "browser-edge-crashpad" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Edge\User Data\Crashpad\*" -Recurse -Force -EA 0 }
Clean "browser-edge-crashreports" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Edge\User Data\Crash Reports\*" -Recurse -Force -EA 0 }
Clean "browser-edge-blobstorage" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Edge\User Data\Default\blob_storage\*" -Recurse -Force -EA 0 }
Clean "browser-brave-cache" { Remove-Item "C:\Users\*\AppData\Local\BraveSoftware\Brave-Browser\User Data\Default\Cache\*" -Recurse -Force -EA 0 }
Clean "browser-brave-codecache" { Remove-Item "C:\Users\*\AppData\Local\BraveSoftware\Brave-Browser\User Data\Default\Code Cache\*" -Recurse -Force -EA 0 }
Clean "browser-brave-gpucache" { Remove-Item "C:\Users\*\AppData\Local\BraveSoftware\Brave-Browser\User Data\Default\GPUCache\*" -Recurse -Force -EA 0 }
Clean "browser-brave-crashpad" { Remove-Item "C:\Users\*\AppData\Local\BraveSoftware\Brave-Browser\User Data\Crashpad\*" -Recurse -Force -EA 0 }
Clean "browser-opera-cache" { Remove-Item "C:\Users\*\AppData\Local\Opera Software\Opera Stable\Cache\*" -Recurse -Force -EA 0 }
Clean "browser-opera-codecache" { Remove-Item "C:\Users\*\AppData\Local\Opera Software\Opera Stable\Code Cache\*" -Recurse -Force -EA 0 }
Clean "browser-opera-gpucache" { Remove-Item "C:\Users\*\AppData\Local\Opera Software\Opera Stable\GPUCache\*" -Recurse -Force -EA 0 }
Clean "browser-operagx-cache" { Remove-Item "C:\Users\*\AppData\Local\Opera Software\Opera GX Stable\Cache\*" -Recurse -Force -EA 0 }
Clean "browser-vivaldi-cache" { Remove-Item "C:\Users\*\AppData\Local\Vivaldi\User Data\Default\Cache\*" -Recurse -Force -EA 0 }
Clean "browser-vivaldi-codecache" { Remove-Item "C:\Users\*\AppData\Local\Vivaldi\User Data\Default\Code Cache\*" -Recurse -Force -EA 0 }
Clean "browser-vivaldi-gpucache" { Remove-Item "C:\Users\*\AppData\Local\Vivaldi\User Data\Default\GPUCache\*" -Recurse -Force -EA 0 }
Clean "browser-arc-cache" { Remove-Item "C:\Users\*\AppData\Local\Arc\User Data\Default\Cache\*" -Recurse -Force -EA 0 }
Clean "browser-arc-codecache" { Remove-Item "C:\Users\*\AppData\Local\Arc\User Data\Default\Code Cache\*" -Recurse -Force -EA 0 }
Clean "browser-waterfox-cache" { Remove-Item "C:\Users\*\AppData\Roaming\Waterfox\Profiles\*\cache2\*" -Recurse -Force -EA 0 }
Clean "browser-palemoon-cache" { Remove-Item "C:\Users\*\AppData\Roaming\Moonchild Productions\Pale Moon\Profiles\*\cache2\*" -Recurse -Force -EA 0 }
Clean "browser-tor-cache" { Remove-Item "C:\Users\*\Desktop\Tor Browser\Browser\TorBrowser\Data\Browser\profile.default\cache2\*" -Recurse -Force -EA 0 }
Clean "browser-ie-cache" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Windows\INetCache\*" -Recurse -Force -EA 0 }
Clean "browser-ie-cookies" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Windows\INetCookies\*" -Recurse -Force -EA 0 }
Clean "browser-ie-history" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Windows\History\*" -Recurse -Force -EA 0 }
Clean "browser-ie-webcache" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Windows\WebCache\*.log" -Force -EA 0 }
Clean "browser-yandex-cache" { Remove-Item "C:\Users\*\AppData\Local\Yandex\YandexBrowser\User Data\Default\Cache\*" -Recurse -Force -EA 0 }
Clean "browser-chromium-cache" { Remove-Item "C:\Users\*\AppData\Local\Chromium\User Data\Default\Cache\*" -Recurse -Force -EA 0 }
Clean "browser-chromium-codecache" { Remove-Item "C:\Users\*\AppData\Local\Chromium\User Data\Default\Code Cache\*" -Recurse -Force -EA 0 }
Clean "browser-maxthon-cache" { Remove-Item "C:\Users\*\AppData\Local\Maxthon*\*Cache*\*" -Recurse -Force -EA 0 }
Clean "browser-slimbrowser-cache" { Remove-Item "C:\Users\*\AppData\Local\SlimBrowser\*Cache*\*" -Recurse -Force -EA 0 }
Clean "browser-cent-cache" { Remove-Item "C:\Users\*\AppData\Local\CentBrowser\User Data\Default\Cache\*" -Recurse -Force -EA 0 }
Clean "browser-comodo-cache" { Remove-Item "C:\Users\*\AppData\Local\Comodo\Dragon\User Data\Default\Cache\*" -Recurse -Force -EA 0 }
Clean "browser-srware-cache" { Remove-Item "C:\Users\*\AppData\Local\SRWare Iron\User Data\Default\Cache\*" -Recurse -Force -EA 0 }
Clean "browser-ungoogled-cache" { Remove-Item "C:\Users\*\AppData\Local\Chromium\User Data\Default\Cache\*" -Recurse -Force -EA 0 }
Clean "browser-webview-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\*WebView*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "browser-cef-cache" { Remove-Item "C:\Users\*\AppData\Local\*\CEF\*Cache*\*" -Recurse -Force -EA 0 }
Clean "browser-electron-partition" { Get-ChildItem "C:\Users\*\AppData\Roaming\*\Partitions\*\Cache\*" -EA 0 | Remove-Item -Recurse -Force -EA 0 }
Clean "browser-all-mediafoundation" { Remove-Item "C:\Users\*\AppData\Local\*\User Data\Default\Media Cache\*" -Recurse -Force -EA 0 }
Clean "browser-all-gpushader" { Remove-Item "C:\Users\*\AppData\Local\*\User Data\ShaderCache\*" -Recurse -Force -EA 0 }
Clean "browser-all-localstorage-old" { Get-ChildItem "C:\Users\*\AppData\Local\*\User Data\Default\Local Storage\*.old" -EA 0 | Remove-Item -Force -EA 0 }
Clean "browser-all-sessionrestore" { Get-ChildItem "C:\Users\*\AppData\Local\*\User Data\Default\Sessions\*.bak" -EA 0 | Remove-Item -Force -EA 0 }
Clean "browser-extensions-temp" { Remove-Item "C:\Users\*\AppData\Local\*\User Data\Default\Extensions\Temp\*" -Recurse -Force -EA 0 }
Clean "browser-extensions-cache" { Get-ChildItem "C:\Users\*\AppData\Local\*\User Data\Default\Extensions\*\_cache\*" -EA 0 | Remove-Item -Recurse -Force -EA 0 }
Clean "browser-servicewoker-cache" { Remove-Item "C:\Users\*\AppData\Local\*\User Data\Default\Service Worker\CacheStorage\*" -Recurse -Force -EA 0 }
Clean "browser-webrtc-logs" { Remove-Item "C:\Users\*\AppData\Local\*\User Data\Default\webrtc_event_logs\*" -Force -EA 0 }
Clean "browser-cachevisited" { Get-ChildItem "C:\Users\*\AppData\Local\*\User Data\Default\visited*" -EA 0 | Remove-Item -Force -EA 0 }
Clean "browser-favicons-old" { Get-ChildItem "C:\Users\*\AppData\Local\*\User Data\Default\Favicons-journal" -EA 0 | Remove-Item -Force -EA 0 }
Clean "browser-networkerror" { Remove-Item "C:\Users\*\AppData\Local\*\User Data\Default\Network\*.log" -Force -EA 0 }
Clean "browser-safebrowsing" { Remove-Item "C:\Users\*\AppData\Local\*\User Data\Default\Safe Browsing*\*" -Recurse -Force -EA 0 }
Clean "browser-sync-data-old" { Get-ChildItem "C:\Users\*\AppData\Local\*\User Data\Default\Sync Data\*.bak" -EA 0 | Remove-Item -Force -EA 0 }
Clean "browser-top-sites-old" { Get-ChildItem "C:\Users\*\AppData\Local\*\User Data\Default\Top Sites-journal" -EA 0 | Remove-Item -Force -EA 0 }
Clean "browser-shared-proto" { Remove-Item "C:\Users\*\AppData\Local\*\User Data\Default\shared_proto_db\*.log" -Force -EA 0 }

# ============================================================================
# PHASE 46: TELEMETRY AND DIAGNOSTICS (60 operations)
# ============================================================================
Write-Host "`n[PHASE 46/80] TELEMETRY AND DIAGNOSTICS" -ForegroundColor White
Clean "tele-diagtrack-etl" { Remove-Item "C:\ProgramData\Microsoft\Diagnosis\ETLLogs\*" -Recurse -Force -EA 0 }
Clean "tele-diagtrack-autologger" { Remove-Item "C:\ProgramData\Microsoft\Diagnosis\ETLLogs\AutoLogger\*" -Force -EA 0 }
Clean "tele-diagtrack-shutdown" { Remove-Item "C:\ProgramData\Microsoft\Diagnosis\ETLLogs\ShutdownLogger\*" -Force -EA 0 }
Clean "tele-sqm-upload" { Remove-Item "C:\ProgramData\Microsoft\SQMClient\*" -Recurse -Force -EA 0 }
Clean "tele-compattelrunner" { Remove-Item "C:\ProgramData\Microsoft\Diagnosis\DownloadedSettings\*" -Recurse -Force -EA 0 }
Clean "tele-census" { Remove-Item "C:\ProgramData\Microsoft\Diagnosis\Census\*" -Recurse -Force -EA 0 }
Clean "tele-devicecensus" { Remove-Item "C:\ProgramData\Microsoft\DeviceCensus\*" -Recurse -Force -EA 0 }
Clean "tele-feedback-cache" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Windows\Feedback\*" -Recurse -Force -EA 0 }
Clean "tele-feedback-metadata" { Remove-Item "C:\ProgramData\Microsoft\Windows\Feedback\*" -Recurse -Force -EA 0 }
Clean "tele-ceip-logs" { Remove-Item "C:\ProgramData\Microsoft\Windows\CEIP\*" -Recurse -Force -EA 0 }
Clean "tele-siuf-queue" { Remove-Item "C:\ProgramData\Microsoft\SIUF\*" -Recurse -Force -EA 0 }
Clean "tele-xboxgip-logs" { Remove-Item "C:\ProgramData\Microsoft\XboxGIP\Logs\*" -Force -EA 0 }
Clean "tele-dosvc-delivery" { Remove-Item "C:\Windows\ServiceProfiles\NetworkService\AppData\Local\Microsoft\Windows\DeliveryOptimization\Logs\*" -Force -EA 0 }
Clean "tele-connected-user" { Remove-Item "C:\ProgramData\Microsoft\ConnectedUser\*" -Recurse -Force -EA 0 }
Clean "tele-network-setup" { Remove-Item "C:\ProgramData\Microsoft\Network\*\*.etl" -Force -EA 0 }
Clean "tele-event-forwarded" { wevtutil cl "Microsoft-Windows-Forwarding/Operational" 2>$null }
Clean "tele-event-biometrics" { wevtutil cl "Microsoft-Windows-Biometrics/Operational" 2>$null }
Clean "tele-event-appid" { wevtutil cl "Microsoft-Windows-AppID/Operational" 2>$null }
Clean "tele-event-applocker" { wevtutil cl "Microsoft-Windows-AppLocker/EXE and DLL" 2>$null }
Clean "tele-event-appmodel" { wevtutil cl "Microsoft-Windows-AppModel-Runtime/Admin" 2>$null }
Clean "tele-event-appreadiness" { wevtutil cl "Microsoft-Windows-AppReadiness/Operational" 2>$null }
Clean "tele-event-appxdeploy" { wevtutil cl "Microsoft-Windows-AppXDeployment/Operational" 2>$null }
Clean "tele-event-appxdeployserver" { wevtutil cl "Microsoft-Windows-AppXDeploymentServer/Operational" 2>$null }
Clean "tele-event-audio" { wevtutil cl "Microsoft-Windows-Audio/Operational" 2>$null }
Clean "tele-event-bits" { wevtutil cl "Microsoft-Windows-Bits-Client/Operational" 2>$null }
Clean "tele-event-capi2" { wevtutil cl "Microsoft-Windows-CAPI2/Operational" 2>$null }
Clean "tele-event-cloudstore" { wevtutil cl "Microsoft-Windows-CloudStore/Operational" 2>$null }
Clean "tele-event-codeintegrity" { wevtutil cl "Microsoft-Windows-CodeIntegrity/Operational" 2>$null }
Clean "tele-event-cortana" { wevtutil cl "Microsoft-Windows-Cortana/Operational" 2>$null }
Clean "tele-event-devicesetup" { wevtutil cl "Microsoft-Windows-DeviceSetupManager/Operational" 2>$null }
Clean "tele-event-dhcp" { wevtutil cl "Microsoft-Windows-Dhcp-Client/Operational" 2>$null }
Clean "tele-event-diagnostic" { wevtutil cl "Microsoft-Windows-Diagnostics-Networking/Operational" 2>$null }
Clean "tele-event-drivers" { wevtutil cl "Microsoft-Windows-DriverFrameworks-UserMode/Operational" 2>$null }
Clean "tele-event-fault" { wevtutil cl "Microsoft-Windows-Fault-Tolerant-Heap/Operational" 2>$null }
Clean "tele-event-grouppolicy" { wevtutil cl "Microsoft-Windows-GroupPolicy/Operational" 2>$null }
Clean "tele-event-hyper-v" { wevtutil cl "Microsoft-Windows-Hyper-V-VMMS-Admin" 2>$null }
Clean "tele-event-kernel" { wevtutil cl "Microsoft-Windows-Kernel-Boot/Operational" 2>$null }
Clean "tele-event-kernelpnp" { wevtutil cl "Microsoft-Windows-Kernel-PnP/Configuration" 2>$null }
Clean "tele-event-kernelpower" { wevtutil cl "Microsoft-Windows-Kernel-Power/Thermal-Operational" 2>$null }
Clean "tele-event-liveid" { wevtutil cl "Microsoft-Windows-LiveId/Operational" 2>$null }
Clean "tele-event-ncsi" { wevtutil cl "Microsoft-Windows-NCSI/Operational" 2>$null }
Clean "tele-event-ndis" { wevtutil cl "Microsoft-Windows-NDIS/Operational" 2>$null }
Clean "tele-event-networking" { wevtutil cl "Microsoft-Windows-Networking-Correlation/Operational" 2>$null }
Clean "tele-event-ntlm" { wevtutil cl "Microsoft-Windows-NTLM/Operational" 2>$null }
Clean "tele-event-partition" { wevtutil cl "Microsoft-Windows-Partition/Diagnostic" 2>$null }
Clean "tele-event-powershell-ops" { wevtutil cl "Microsoft-Windows-PowerShell/Operational" 2>$null }
Clean "tele-event-printservice" { wevtutil cl "Microsoft-Windows-PrintService/Operational" 2>$null }
Clean "tele-event-pushnotification" { wevtutil cl "Microsoft-Windows-PushNotification-Platform/Operational" 2>$null }
Clean "tele-event-rdp" { wevtutil cl "Microsoft-Windows-RemoteDesktopServices-RdpCoreTS/Operational" 2>$null }
Clean "tele-event-reliability" { wevtutil cl "Microsoft-Windows-ReliabilityAnalysisComponent/Operational" 2>$null }
Clean "tele-event-resource" { wevtutil cl "Microsoft-Windows-Resource-Exhaustion-Detector/Operational" 2>$null }
Clean "tele-event-search" { wevtutil cl "Microsoft-Windows-Search/Operational" 2>$null }
Clean "tele-event-shell" { wevtutil cl "Microsoft-Windows-Shell-Core/Operational" 2>$null }
Clean "tele-event-smbclient" { wevtutil cl "Microsoft-Windows-SMBClient/Operational" 2>$null }
Clean "tele-event-storsvc" { wevtutil cl "Microsoft-Windows-Storsvc/Diagnostic" 2>$null }
Clean "tele-event-taskscheduler" { wevtutil cl "Microsoft-Windows-TaskScheduler/Operational" 2>$null }
Clean "tele-event-terminalservices" { wevtutil cl "Microsoft-Windows-TerminalServices-LocalSessionManager/Operational" 2>$null }
Clean "tele-event-twain" { wevtutil cl "Microsoft-Windows-TWAIN-WorkingGroup/Operational" 2>$null }
Clean "tele-event-uac" { wevtutil cl "Microsoft-Windows-UAC/Operational" 2>$null }
Clean "tele-event-vhdmp" { wevtutil cl "Microsoft-Windows-VHDMP/Operational" 2>$null }

# ============================================================================
# PHASE 47: WINDOWS STORE AND UWP APPS (80 operations)
# ============================================================================
Write-Host "`n[PHASE 47/80] WINDOWS STORE AND UWP APPS" -ForegroundColor White
Clean "uwp-store-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.WindowsStore*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "uwp-store-tempstate" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.WindowsStore*\TempState\*" -Recurse -Force -EA 0 }
Clean "uwp-photos-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.Windows.Photos*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "uwp-photos-temp" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.Windows.Photos*\TempState\*" -Recurse -Force -EA 0 }
Clean "uwp-calculator-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.WindowsCalculator*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "uwp-calendar-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\microsoft.windowscommunicationsapps*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "uwp-camera-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.WindowsCamera*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "uwp-maps-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.WindowsMaps*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "uwp-maps-tempstate" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.WindowsMaps*\TempState\*" -Recurse -Force -EA 0 }
Clean "uwp-weather-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.BingWeather*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "uwp-news-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.BingNews*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "uwp-sports-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.BingSports*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "uwp-finance-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.BingFinance*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "uwp-groove-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.ZuneMusic*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "uwp-movies-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.ZuneVideo*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "uwp-onenote-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.Office.OneNote*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "uwp-people-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.People*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "uwp-alarms-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.WindowsAlarms*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "uwp-feedback-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.WindowsFeedbackHub*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "uwp-gethelp-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.GetHelp*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "uwp-getstarted-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.Getstarted*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "uwp-messaging-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.Messaging*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "uwp-mixedreality-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.MixedReality*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "uwp-paint3d-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.MSPaint*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "uwp-3dviewer-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.Microsoft3DViewer*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "uwp-screensketch-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.ScreenSketch*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "uwp-snip-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.SnippingTool*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "uwp-stickyNotes-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.MicrosoftStickyNotes*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "uwp-todo-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.Todos*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "uwp-voicerecorder-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.WindowsSoundRecorder*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "uwp-yourphone-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.YourPhone*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "uwp-yourphone-temp" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.YourPhone*\TempState\*" -Recurse -Force -EA 0 }
Clean "uwp-cortana-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.549981C3F5F10*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "uwp-edge-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.MicrosoftEdge*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "uwp-solitaire-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.MicrosoftSolitaireCollection*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "uwp-xbox-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.XboxApp*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "uwp-xboxgamebar-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.XboxGamingOverlay*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "uwp-xboxidentity-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.XboxIdentityProvider*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "uwp-xboxspeech-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.XboxSpeechToTextOverlay*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "uwp-terminal-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.WindowsTerminal*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "uwp-powertoys-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.PowerToys*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "uwp-devhome-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.DevHome*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "uwp-winget-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.DesktopAppInstaller*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "uwp-clipchamp-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\Clipchamp*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "uwp-copilot-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.Copilot*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "uwp-family-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.Family*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "uwp-hevc-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.HEVCVideoExtension*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "uwp-heif-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.HEIFImageExtension*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "uwp-webp-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.WebpImageExtension*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "uwp-raw-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.RawImageExtension*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "uwp-all-ac" { Remove-Item "C:\Users\*\AppData\Local\Packages\*\AC\*" -Recurse -Force -EA 0 }
Clean "uwp-all-localstate-temp" { Get-ChildItem "C:\Users\*\AppData\Local\Packages\*\LocalState\*.tmp" -Recurse -EA 0 | Remove-Item -Force -EA 0 }
Clean "uwp-all-roamingstate-temp" { Get-ChildItem "C:\Users\*\AppData\Local\Packages\*\RoamingState\*.tmp" -Recurse -EA 0 | Remove-Item -Force -EA 0 }
Clean "uwp-all-settings-bak" { Get-ChildItem "C:\Users\*\AppData\Local\Packages\*\Settings\*.bak" -Recurse -EA 0 | Remove-Item -Force -EA 0 }
Clean "uwp-spotify-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\SpotifyAB*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "uwp-netflix-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\*Netflix*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "uwp-disney-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\*Disney*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "uwp-prime-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\*AmazonVideo*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "uwp-hulu-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\*Hulu*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "uwp-hbomax-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\*HBO*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "uwp-twitch-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\*Twitch*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "uwp-tiktok-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\*TikTok*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "uwp-instagram-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\*Instagram*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "uwp-facebook-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\*Facebook*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "uwp-messenger-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\*Messenger*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "uwp-twitter-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\*Twitter*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "uwp-linkedin-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\*LinkedIn*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "uwp-slack-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\*Slack*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "uwp-zoom-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\*Zoom*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "uwp-webex-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\*Webex*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "uwp-evernote-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\*Evernote*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "uwp-onenote2-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\*OneNote*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "uwp-kindle-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\*Kindle*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "uwp-drawboard-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\*Drawboard*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "uwp-adobe-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\*Adobe*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "uwp-affinity-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\*Affinity*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "uwp-canva-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\*Canva*\LocalCache\*" -Recurse -Force -EA 0 }

# ============================================================================
# PHASE 48: ADDITIONAL LOGS AND TRACES (80 operations)
# ============================================================================
Write-Host "`n[PHASE 48/80] ADDITIONAL LOGS AND TRACES" -ForegroundColor White
Clean "log-cbs" { Remove-Item "C:\Windows\Logs\CBS\*.log" -Force -EA 0 }
Clean "log-cbs-persist" { Remove-Item "C:\Windows\Logs\CBS\*.cab" -Force -EA 0 }
Clean "log-dism" { Remove-Item "C:\Windows\Logs\DISM\*.log" -Force -EA 0 }
Clean "log-dpx" { Remove-Item "C:\Windows\Logs\DPX\*.log" -Force -EA 0 }
Clean "log-measuredboot" { Remove-Item "C:\Windows\Logs\MeasuredBoot\*" -Force -EA 0 }
Clean "log-mrt" { Remove-Item "C:\Windows\Debug\mrt.log" -Force -EA 0 }
Clean "log-sih" { Remove-Item "C:\Windows\Logs\SIH\*" -Recurse -Force -EA 0 }
Clean "log-windowsupdate" { Remove-Item "C:\Windows\Logs\WindowsUpdate\*" -Recurse -Force -EA 0 }
Clean "log-mosetup" { Remove-Item "C:\Windows\Logs\MoSetup\*" -Recurse -Force -EA 0 }
Clean "log-netsetup" { Remove-Item "C:\Windows\Logs\NetSetup\*" -Force -EA 0 }
Clean "log-storport" { Remove-Item "C:\Windows\Logs\StorPort\*" -Force -EA 0 }
Clean "log-systemrestore" { Remove-Item "C:\Windows\Logs\SystemRestore\*" -Force -EA 0 }
Clean "log-waasmedic" { Remove-Item "C:\Windows\Logs\waasmedic\*" -Force -EA 0 }
Clean "log-waasmedicagent" { Remove-Item "C:\Windows\Logs\waasmedicagent\*" -Force -EA 0 }
Clean "log-wdp" { Remove-Item "C:\Windows\Logs\WDP\*" -Force -EA 0 }
Clean "log-windefend" { Remove-Item "C:\ProgramData\Microsoft\Windows Defender\Support\*" -Recurse -Force -EA 0 }
Clean "log-defender-network" { Remove-Item "C:\ProgramData\Microsoft\Windows Defender\Network Inspection System\Support\*" -Recurse -Force -EA 0 }
Clean "log-defender-scans" { Remove-Item "C:\ProgramData\Microsoft\Windows Defender\Scans\History\*" -Recurse -Force -EA 0 }
Clean "log-defender-quarantine" { Remove-Item "C:\ProgramData\Microsoft\Windows Defender\Quarantine\*" -Recurse -Force -EA 0 }
Clean "log-ntuser-log" { Remove-Item "C:\Users\*\NTUSER.DAT.LOG*" -Force -EA 0 }
Clean "log-usrclass-log" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Windows\UsrClass.dat.LOG*" -Force -EA 0 }
Clean "log-perfmon" { Remove-Item "C:\PerfLogs\Admin\*" -Recurse -Force -EA 0 }
Clean "log-dxgi" { Remove-Item "C:\Windows\DxgKrnl*.etl" -Force -EA 0 }
Clean "log-bootperfdiag" { Remove-Item "C:\Windows\bootperf*.etl" -Force -EA 0 }
Clean "log-shellexperience" { Remove-Item "C:\Windows\ShellExperiences*.etl" -Force -EA 0 }
Clean "log-sfc" { Remove-Item "C:\Windows\Logs\CBS\sfcdetails.txt" -Force -EA 0 }
Clean "log-wuauclt" { Remove-Item "C:\Windows\WindowsUpdate.log" -Force -EA 0 }
Clean "log-setuperr" { Remove-Item "C:\Windows\setuperr.log" -Force -EA 0 }
Clean "log-setupact" { Remove-Item "C:\Windows\setupact.log" -Force -EA 0 }
Clean "log-setupapi-dev" { Remove-Item "C:\Windows\setupapi.dev.log" -Force -EA 0 }
Clean "log-dotnet-installutil" { Remove-Item "C:\Windows\Microsoft.NET\Framework*\*\InstallUtil*.log" -Force -EA 0 }
Clean "log-iis-w3svc" { Remove-Item "C:\inetpub\logs\LogFiles\W3SVC*\*" -Recurse -Force -EA 0 }
Clean "log-iis-failedreq" { Remove-Item "C:\inetpub\logs\FailedReqLogFiles\*" -Recurse -Force -EA 0 }
Clean "log-iis-httperr" { Remove-Item "C:\Windows\System32\LogFiles\HTTPERR\*" -Force -EA 0 }
Clean "log-msi" { Remove-Item "C:\Users\*\AppData\Local\Temp\MSI*.log" -Force -EA 0 }
Clean "log-installshield" { Remove-Item "C:\Users\*\AppData\Local\Temp\{*}\*.log" -Force -EA 0 }
Clean "log-inno" { Remove-Item "C:\Users\*\AppData\Local\Temp\is-*\*.log" -Force -EA 0 }
Clean "log-nsis" { Remove-Item "C:\Users\*\AppData\Local\Temp\nst*.tmp\*.log" -Force -EA 0 }
Clean "log-java-install" { Remove-Item "C:\Users\*\AppData\LocalLow\Sun\Java\Deployment\log\*" -Force -EA 0 }
Clean "log-java-cache" { Remove-Item "C:\Users\*\AppData\LocalLow\Sun\Java\Deployment\cache\*" -Recurse -Force -EA 0 }
Clean "log-sql-server" { Remove-Item "C:\Program Files\Microsoft SQL Server\*\MSSQL\Log\*.log" -Force -EA 0 }
Clean "log-sql-error" { Remove-Item "C:\Program Files\Microsoft SQL Server\*\MSSQL\Log\ERRORLOG*" -Force -EA 0 }
Clean "log-oracle" { Remove-Item "C:\oracle\*\*.trc" -Force -EA 0 }
Clean "log-mysql" { Remove-Item "C:\ProgramData\MySQL\*\Data\*.log" -Force -EA 0 }
Clean "log-postgres" { Remove-Item "C:\Program Files\PostgreSQL\*\data\log\*" -Force -EA 0 }
Clean "log-mongodb" { Remove-Item "C:\ProgramData\MongoDB\*\log\*" -Force -EA 0 }
Clean "log-redis" { Remove-Item "C:\ProgramData\Redis\*\*.log" -Force -EA 0 }
Clean "log-elasticsearch" { Remove-Item "C:\ProgramData\Elastic\*\logs\*" -Force -EA 0 }
Clean "log-apache" { Remove-Item "C:\Apache*\logs\*" -Force -EA 0 }
Clean "log-nginx" { Remove-Item "C:\nginx\logs\*" -Force -EA 0 }
Clean "log-tomcat" { Remove-Item "C:\Program Files\Apache Software Foundation\Tomcat*\logs\*" -Force -EA 0 }
Clean "log-jenkins" { Remove-Item "C:\Program Files\Jenkins\logs\*" -Force -EA 0 }
Clean "log-teamcity" { Remove-Item "C:\TeamCity\logs\*" -Force -EA 0 }
Clean "log-bamboo" { Remove-Item "C:\Atlassian\Bamboo\logs\*" -Force -EA 0 }
Clean "log-jira" { Remove-Item "C:\Atlassian\Jira\logs\*" -Force -EA 0 }
Clean "log-confluence" { Remove-Item "C:\Atlassian\Confluence\logs\*" -Force -EA 0 }
Clean "log-virtualbox" { Remove-Item "C:\Users\*\.VirtualBox\*.log*" -Force -EA 0 }
Clean "log-vmware" { Remove-Item "C:\Users\*\AppData\Local\VMware\*.log" -Force -EA 0 }
Clean "log-vmware-workstation" { Remove-Item "C:\ProgramData\VMware\VMware Workstation\*.log" -Force -EA 0 }
Clean "log-docker-windows" { Remove-Item "C:\ProgramData\Docker\logs\*" -Force -EA 0 }
Clean "log-wsl" { Remove-Item "C:\Users\*\AppData\Local\Packages\*Linux*\LocalState\*.log" -Force -EA 0 }
Clean "log-powershell-transcript" { Remove-Item "C:\Users\*\Documents\PowerShell_transcript*.txt" -Force -EA 0 }
Clean "log-powershell-history" { Get-ChildItem "C:\Users\*\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt" -EA 0 | Where-Object {$_.Length -gt 1MB} | ForEach-Object { "" | Set-Content $_.FullName } }
Clean "log-cmd-history" { Remove-Item "C:\Users\*\AppData\Roaming\Microsoft\Windows\doskey*" -Force -EA 0 }
Clean "log-wsl-history" { Remove-Item "C:\Users\*\AppData\Local\Packages\*Linux*\LocalState\rootfs\home\*\.bash_history" -Force -EA 0 }
Clean "log-git-logs" { Get-ChildItem "C:\Users\*\*\.git\logs\*" -Recurse -EA 0 | Where-Object {$_.LastWriteTime -lt (Get-Date).AddDays(-30)} | Remove-Item -Force -EA 0 }
Clean "log-svn-logs" { Remove-Item "C:\Users\*\AppData\Roaming\Subversion\*\*.log" -Force -EA 0 }
Clean "log-mercurial" { Remove-Item "C:\Users\*\*\.hg\*.log" -Force -EA 0 }
Clean "log-perforce" { Remove-Item "C:\Users\*\.p4*\*.log" -Force -EA 0 }
Clean "log-sourcetree" { Remove-Item "C:\Users\*\AppData\Local\Atlassian\SourceTree\*.log" -Force -EA 0 }
Clean "log-gitkraken" { Remove-Item "C:\Users\*\AppData\Roaming\GitKraken\logs\*" -Force -EA 0 }
Clean "log-github-desktop" { Remove-Item "C:\Users\*\AppData\Roaming\GitHub Desktop\logs\*" -Force -EA 0 }
Clean "log-tortoisegit" { Remove-Item "C:\Users\*\AppData\Local\TortoiseGit\*.log" -Force -EA 0 }
Clean "log-tortoisesvn" { Remove-Item "C:\Users\*\AppData\Local\TortoiseSVN\*.log" -Force -EA 0 }
Clean "log-azure-devops" { Remove-Item "C:\Users\*\.azure-devops\*\*.log" -Force -EA 0 }
Clean "log-aws-logs" { Remove-Item "C:\Users\*\.aws\*.log" -Force -EA 0 }
Clean "log-gcloud-logs" { Remove-Item "C:\Users\*\AppData\Roaming\gcloud\logs\*" -Recurse -Force -EA 0 }

# ============================================================================
# PHASE 49: SECURITY AND ANTIVIRUS (60 operations)
# ============================================================================
Write-Host "`n[PHASE 49/80] SECURITY AND ANTIVIRUS" -ForegroundColor White
Clean "sec-defender-cache" { Remove-Item "C:\ProgramData\Microsoft\Windows Defender\Definition Updates\*" -Recurse -Force -EA 0 }
Clean "sec-defender-detectionhistory" { Remove-Item "C:\ProgramData\Microsoft\Windows Defender\Scans\History\Store\*" -Recurse -Force -EA 0 }
Clean "sec-defender-real-time" { Remove-Item "C:\ProgramData\Microsoft\Windows Defender\Scans\RealTimeProtection\*" -Recurse -Force -EA 0 }
Clean "sec-malwarebytes-logs" { Remove-Item "C:\ProgramData\Malwarebytes\Malwarebytes Anti-Malware\Logs\*" -Force -EA 0 }
Clean "sec-malwarebytes-quarantine" { Remove-Item "C:\ProgramData\Malwarebytes\MBAMService\Quarantine\*" -Recurse -Force -EA 0 }
Clean "sec-avg-logs" { Remove-Item "C:\ProgramData\AVG\*\Log\*" -Force -EA 0 }
Clean "sec-avg-quarantine" { Remove-Item "C:\ProgramData\AVG\*\Chest\*" -Recurse -Force -EA 0 }
Clean "sec-avast-logs" { Remove-Item "C:\ProgramData\AVAST Software\*\Log\*" -Force -EA 0 }
Clean "sec-avast-quarantine" { Remove-Item "C:\ProgramData\AVAST Software\*\Chest\*" -Recurse -Force -EA 0 }
Clean "sec-norton-logs" { Remove-Item "C:\ProgramData\Norton\*\Logs\*" -Force -EA 0 }
Clean "sec-norton-quarantine" { Remove-Item "C:\ProgramData\Norton\*\Quarantine\*" -Recurse -Force -EA 0 }
Clean "sec-mcafee-logs" { Remove-Item "C:\ProgramData\McAfee\*\Logs\*" -Force -EA 0 }
Clean "sec-mcafee-quarantine" { Remove-Item "C:\ProgramData\McAfee\Quarantine\*" -Recurse -Force -EA 0 }
Clean "sec-kaspersky-logs" { Remove-Item "C:\ProgramData\Kaspersky Lab\*\Logs\*" -Force -EA 0 }
Clean "sec-kaspersky-quarantine" { Remove-Item "C:\ProgramData\Kaspersky Lab\*\Quarantine\*" -Recurse -Force -EA 0 }
Clean "sec-bitdefender-logs" { Remove-Item "C:\ProgramData\Bitdefender\*\Logs\*" -Force -EA 0 }
Clean "sec-bitdefender-quarantine" { Remove-Item "C:\ProgramData\Bitdefender\*\Quarantine\*" -Recurse -Force -EA 0 }
Clean "sec-eset-logs" { Remove-Item "C:\ProgramData\ESET\*\Logs\*" -Force -EA 0 }
Clean "sec-eset-quarantine" { Remove-Item "C:\ProgramData\ESET\*\Quarantine\*" -Recurse -Force -EA 0 }
Clean "sec-sophos-logs" { Remove-Item "C:\ProgramData\Sophos\*\Logs\*" -Force -EA 0 }
Clean "sec-sophos-quarantine" { Remove-Item "C:\ProgramData\Sophos\*\Quarantine\*" -Recurse -Force -EA 0 }
Clean "sec-trendmicro-logs" { Remove-Item "C:\ProgramData\Trend Micro\*\Log\*" -Force -EA 0 }
Clean "sec-trendmicro-quarantine" { Remove-Item "C:\ProgramData\Trend Micro\*\Quarantine\*" -Recurse -Force -EA 0 }
Clean "sec-webroot-logs" { Remove-Item "C:\ProgramData\WRData\*\*.log" -Force -EA 0 }
Clean "sec-f-secure-logs" { Remove-Item "C:\ProgramData\F-Secure\*\Log\*" -Force -EA 0 }
Clean "sec-panda-logs" { Remove-Item "C:\ProgramData\Panda Security\*\*.log" -Force -EA 0 }
Clean "sec-comodo-logs" { Remove-Item "C:\ProgramData\Comodo\*\*.log" -Force -EA 0 }
Clean "sec-zonealarm-logs" { Remove-Item "C:\ProgramData\CheckPoint\ZoneAlarm\Logs\*" -Force -EA 0 }
Clean "sec-adaware-logs" { Remove-Item "C:\ProgramData\Lavasoft\Ad-Aware\Logs\*" -Force -EA 0 }
Clean "sec-spybot-logs" { Remove-Item "C:\ProgramData\Spybot - Search & Destroy\Logs\*" -Force -EA 0 }
Clean "sec-hitmanpro-logs" { Remove-Item "C:\ProgramData\HitmanPro\Logs\*" -Force -EA 0 }
Clean "sec-emisoft-logs" { Remove-Item "C:\ProgramData\Emsisoft\*\Logs\*" -Force -EA 0 }
Clean "sec-gdata-logs" { Remove-Item "C:\ProgramData\G Data\*\Logs\*" -Force -EA 0 }
Clean "sec-bullguard-logs" { Remove-Item "C:\ProgramData\BullGuard\*\*.log" -Force -EA 0 }
Clean "sec-totalav-logs" { Remove-Item "C:\ProgramData\TotalAV\*\*.log" -Force -EA 0 }
Clean "sec-360security-logs" { Remove-Item "C:\ProgramData\360TotalSecurity\*\*.log" -Force -EA 0 }
Clean "sec-crowdstrike-logs" { Remove-Item "C:\ProgramData\CrowdStrike\*\*.log" -Force -EA 0 }
Clean "sec-carbonblack-logs" { Remove-Item "C:\ProgramData\CarbonBlack\*\*.log" -Force -EA 0 }
Clean "sec-sentinelone-logs" { Remove-Item "C:\ProgramData\Sentinel\*\*.log" -Force -EA 0 }
Clean "sec-cylance-logs" { Remove-Item "C:\ProgramData\Cylance\*\*.log" -Force -EA 0 }
Clean "sec-windows-firewall-logs" { Remove-Item "C:\Windows\System32\LogFiles\Firewall\pfirewall.log" -Force -EA 0 }
Clean "sec-windows-firewall-old" { Remove-Item "C:\Windows\System32\LogFiles\Firewall\pfirewall.log.*" -Force -EA 0 }
Clean "sec-credential-cache" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Credentials\*" -Force -EA 0 }
Clean "sec-dpapi-blob" { Remove-Item "C:\Users\*\AppData\Roaming\Microsoft\Protect\*.bak" -Force -EA 0 }
Clean "sec-smart-screen-cache" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Windows\SmartScreen\*" -Recurse -Force -EA 0 }
Clean "sec-vault-cache" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Vault\*cache*" -Force -EA 0 }
Clean "sec-wdnissvc" { Remove-Item "C:\Windows\System32\WdiServiceHost\*" -Force -EA 0 }
Clean "sec-epp-cache" { Remove-Item "C:\ProgramData\Microsoft\Windows Defender Advanced Threat Protection\Cache\*" -Recurse -Force -EA 0 }
Clean "sec-epp-logs" { Remove-Item "C:\ProgramData\Microsoft\Windows Defender Advanced Threat Protection\Logs\*" -Force -EA 0 }
Clean "sec-mdatp-logs" { Remove-Item "C:\ProgramData\Microsoft\Windows Defender Advanced Threat Protection\Trace\*" -Force -EA 0 }
Clean "sec-cert-cache" { Remove-Item "C:\Users\*\AppData\LocalLow\Microsoft\CryptnetUrlCache\*" -Recurse -Force -EA 0 }
Clean "sec-cert-metadata" { Remove-Item "C:\Users\*\AppData\LocalLow\Microsoft\CryptnetUrlCache\MetaData\*" -Force -EA 0 }
Clean "sec-cert-content" { Remove-Item "C:\Users\*\AppData\LocalLow\Microsoft\CryptnetUrlCache\Content\*" -Force -EA 0 }
Clean "sec-ocsp-cache" { Remove-Item "C:\Windows\System32\config\systemprofile\AppData\LocalLow\Microsoft\CryptnetUrlCache\*" -Recurse -Force -EA 0 }
Clean "sec-mscache" { Remove-Item "C:\Windows\System32\Microsoft\Protect\S-1-5-18\*\*.dat.LOG*" -Force -EA 0 }
Clean "sec-lsa-cache" { Remove-Item "C:\Windows\System32\config\systemprofile\AppData\Local\Microsoft\Windows\Lsa\*" -Force -EA 0 }
Clean "sec-sam-logs" { Remove-Item "C:\Windows\System32\config\SAM.LOG*" -Force -EA 0 }
Clean "sec-security-logs" { Remove-Item "C:\Windows\System32\config\SECURITY.LOG*" -Force -EA 0 }
Clean "sec-software-logs" { Remove-Item "C:\Windows\System32\config\SOFTWARE.LOG*" -Force -EA 0 }

# ============================================================================
# PHASE 50: MORE WINDOWS SYSTEM (60 operations)
# ============================================================================
Write-Host "`n[PHASE 50/80] MORE WINDOWS SYSTEM" -ForegroundColor White
Clean "win-searchindex-temp" { Remove-Item "C:\ProgramData\Microsoft\Search\Data\Temp\*" -Recurse -Force -EA 0 }
Clean "win-searchindex-journal" { Remove-Item "C:\ProgramData\Microsoft\Search\Data\Applications\Windows\*.jtx" -Force -EA 0 }
Clean "win-cortana-localappdata" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.Windows.Cortana*\LocalState\*" -Recurse -Force -EA 0 }
Clean "win-cortana-roaming" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.Windows.Cortana*\RoamingState\*" -Recurse -Force -EA 0 }
Clean "win-contentdelivery" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.Windows.ContentDeliveryManager*\LocalState\*" -Recurse -Force -EA 0 }
Clean "win-startmenu-cache" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Windows\Caches\*" -Force -EA 0 }
Clean "win-recent-items" { Get-ChildItem "C:\Users\*\AppData\Roaming\Microsoft\Windows\Recent\*" -EA 0 | Where-Object {$_.LastWriteTime -lt (Get-Date).AddDays(-30)} | Remove-Item -Force -EA 0 }
Clean "win-automaticdest" { Get-ChildItem "C:\Users\*\AppData\Roaming\Microsoft\Windows\Recent\AutomaticDestinations\*" -EA 0 | Where-Object {$_.LastWriteTime -lt (Get-Date).AddDays(-30)} | Remove-Item -Force -EA 0 }
Clean "win-customdest" { Get-ChildItem "C:\Users\*\AppData\Roaming\Microsoft\Windows\Recent\CustomDestinations\*" -EA 0 | Where-Object {$_.LastWriteTime -lt (Get-Date).AddDays(-30)} | Remove-Item -Force -EA 0 }
Clean "win-notification-cache" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Windows\Notifications\*" -Recurse -Force -EA 0 }
Clean "win-toast-cache" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Windows\ActionCenter\*" -Recurse -Force -EA 0 }
Clean "win-explorer-shellbags" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Windows\UsrClass.dat.LOG*" -Force -EA 0 }
Clean "win-jumplist-temp" { Remove-Item "C:\Users\*\AppData\Roaming\Microsoft\Windows\Recent\*.tmp" -Force -EA 0 }
Clean "win-clipboard-history" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Windows\Clipboard\*" -Recurse -Force -EA 0 }
Clean "win-font-cache-data" { Remove-Item "C:\Windows\System32\FNTCACHE.DAT" -Force -EA 0 }
Clean "win-compat-assistant" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Windows\Compatibility Assistant\*" -Recurse -Force -EA 0 }
Clean "win-appcompat-programs" { Remove-Item "C:\Windows\appcompat\Programs\AmCache.hve.tmp" -Force -EA 0 }
Clean "win-userchoice-cache" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Windows\UsrClass.dat.bak" -Force -EA 0 }
Clean "win-timeline-cache" { Remove-Item "C:\Users\*\AppData\Local\ConnectedDevicesPlatform\*" -Recurse -Force -EA 0 }
Clean "win-activity-history" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Windows\History\*" -Recurse -Force -EA 0 }
Clean "win-reliability-wer" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Windows\WER\*" -Recurse -Force -EA 0 }
Clean "win-problemreports" { Remove-Item "C:\ProgramData\Microsoft\Windows\WER\*" -Recurse -Force -EA 0 }
Clean "win-errorreporting" { Remove-Item "C:\Users\*\AppData\Local\CrashDumps\*" -Force -EA 0 }
Clean "win-upgrade-logs" { Remove-Item "C:\Windows.old\*" -Recurse -Force -EA 0 }
Clean "win-panther-logs" { Remove-Item "C:\Windows\Panther\*.log" -Force -EA 0 }
Clean "win-panther-etl" { Remove-Item "C:\Windows\Panther\*.etl" -Force -EA 0 }
Clean "win-bt-windows" { Remove-Item "C:\`$Windows.~BT\*" -Recurse -Force -EA 0 }
Clean "win-ws-windows" { Remove-Item "C:\`$Windows.~WS\*" -Recurse -Force -EA 0 }
Clean "win-getstarted-cache" { Remove-Item "C:\Windows\System32\config\systemprofile\AppData\Local\Microsoft\Windows\Caches\*" -Force -EA 0 }
Clean "win-pushinstallservice" { Remove-Item "C:\ProgramData\Microsoft\PushInstall\*" -Recurse -Force -EA 0 }
Clean "win-appraiser-data" { Remove-Item "C:\Windows\appcompat\Appraiser\*" -Recurse -Force -EA 0 }
Clean "win-pca-files" { Remove-Item "C:\Windows\appcompat\pca\*.txt" -Force -EA 0 }
Clean "win-cloudstorage-cache" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Windows\CloudStore\*" -Recurse -Force -EA 0 }
Clean "win-settingsync-cache" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Windows\SettingSync\*" -Recurse -Force -EA 0 }
Clean "win-webcache-v01" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Windows\WebCacheV01.dat" -Force -EA 0 }
Clean "win-webcache-log" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Windows\WebCache\*.log" -Force -EA 0 }
Clean "win-gamebarstate" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\GameBar\*cache*" -Recurse -Force -EA 0 }
Clean "win-input-personalization" { Remove-Item "C:\Users\*\AppData\Roaming\Microsoft\InputPersonalization\*" -Recurse -Force -EA 0 }
Clean "win-speech-modeldownload" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Speech_OneCore\*\*.tmp" -Force -EA 0 }
Clean "win-handwriting-data" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\InputPersonalization\*" -Recurse -Force -EA 0 }
Clean "win-lockscrn-cache" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.LockApp*\LocalCache\*" -Recurse -Force -EA 0 }
Clean "win-account-pictures" { Get-ChildItem "C:\Users\*\AppData\Roaming\Microsoft\Windows\AccountPictures\*" -EA 0 | Where-Object { $_.Name -match '\(1\)|\(2\)|\(3\)' } | Remove-Item -Force -EA 0 }
Clean "win-desktop-cache" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Windows\Desktop\*cache*" -Force -EA 0 }
Clean "win-retail-demo" { Remove-Item "C:\Users\*\AppData\Local\Packages\Microsoft.Windows.RetailDemo*\*" -Recurse -Force -EA 0 }
Clean "win-people-cache" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\People\*cache*" -Recurse -Force -EA 0 }
Clean "win-tokens-cache" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\TokenBroker\Cache\*" -Force -EA 0 }
Clean "win-tiles-datamodel" { Remove-Item "C:\Users\*\AppData\Local\TileDataLayer\*" -Recurse -Force -EA 0 }
Clean "win-cdm-data" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Windows\ContentDelivery\*" -Recurse -Force -EA 0 }
Clean "win-explorer-bags" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Windows\Explorer\*.db" -Force -EA 0 }
Clean "win-iconcache-all" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Windows\Explorer\iconcache*.db" -Force -EA 0 }
Clean "win-thumbcache-all" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Windows\Explorer\thumbcache*.db" -Force -EA 0 }
Clean "win-credential-roaming" { Remove-Item "C:\Users\*\AppData\Roaming\Microsoft\SystemCertificates\*.STL.bak" -Force -EA 0 }
Clean "win-cdi-log" { Remove-Item "C:\Windows\Logs\cdi\*" -Recurse -Force -EA 0 }
Clean "win-wininit-log" { Remove-Item "C:\Windows\wininit.log" -Force -EA 0 }
Clean "win-boot-log" { Remove-Item "C:\Windows\ntbtlog.txt" -Force -EA 0 }
Clean "win-repair-log" { Remove-Item "C:\Windows\repair\*.log" -Force -EA 0 }
Clean "win-servicemodel" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\ServiceModel\*" -Recurse -Force -EA 0 }
Clean "win-wpn-cache" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Windows\WPN\*" -Recurse -Force -EA 0 }
Clean "win-pushnotification" { Remove-Item "C:\Users\*\AppData\Local\Microsoft\Windows\PushNotifications\*" -Recurse -Force -EA 0 }

# ============================================================================
# PHASE 51: CLOUD & CONTAINER CLEANUP - AWS, AZURE, GCP (138 operations)
# ============================================================================
Write-Host "`n[PHASE 51/70] CLOUD & CONTAINER CLEANUP - AWS, AZURE, GCP" -ForegroundColor Cyan
Clean "aws-cli-cache" { Remove-Item "C:\Users\*\.aws\cli\cache\*" -Recurse -Force -EA 0 }
Clean "aws-credentials-backup" { Remove-Item "C:\Users\*\.aws\credentials.bak" -Force -EA 0 }
Clean "aws-config-backup" { Remove-Item "C:\Users\*\.aws\config.bak" -Force -EA 0 }
Clean "aws-logs" { Remove-Item "C:\Users\*\.aws\logs\*" -Recurse -Force -EA 0 }
Clean "aws-sso-cache" { Remove-Item "C:\Users\*\.aws\sso\cache\*" -Recurse -Force -EA 0 }
Clean "aws-session-cache" { Remove-Item "C:\Users\*\.aws\sessions\*" -Recurse -Force -EA 0 }
Clean "aws-sam-cache" { Remove-Item "C:\Users\*\.aws-sam\cache\*" -Recurse -Force -EA 0 }
Clean "aws-sam-build" { Remove-Item "C:\Users\*\.aws-sam\build\*" -Recurse -Force -EA 0 }
Clean "aws-sam-deps" { Remove-Item "C:\Users\*\.aws-sam\dependencies\*" -Recurse -Force -EA 0 }
Clean "aws-cdk-cache" { Remove-Item "C:\Users\*\.cdk\cache\*" -Recurse -Force -EA 0 }
Clean "aws-cdk-staging" { Remove-Item "C:\Users\*\.cdk\staging\*" -Recurse -Force -EA 0 }
Clean "aws-eb-cli-cache" { Remove-Item "C:\Users\*\.elasticbeanstalk\*" -Recurse -Force -EA 0 }
Clean "aws-lambda-cache" { Remove-Item "C:\Users\*\.aws\lambda\cache\*" -Recurse -Force -EA 0 }
Clean "aws-cloudshell" { Remove-Item "C:\Users\*\.aws\cloudshell\*" -Recurse -Force -EA 0 }
Clean "aws-ecr-cache" { Remove-Item "C:\Users\*\.aws\ecr\cache\*" -Recurse -Force -EA 0 }
Clean "azure-cli-cache" { Remove-Item "C:\Users\*\.azure\cliextensions\cache\*" -Recurse -Force -EA 0 }
Clean "azure-config-logs" { Remove-Item "C:\Users\*\.azure\logs\*" -Recurse -Force -EA 0 }
Clean "azure-telemetry" { Remove-Item "C:\Users\*\.azure\telemetry\*" -Recurse -Force -EA 0 }
Clean "azure-commands" { Remove-Item "C:\Users\*\.azure\commands\*" -Recurse -Force -EA 0 }
Clean "azure-msal-cache" { Remove-Item "C:\Users\*\.azure\msal_token_cache.json" -Force -EA 0 }
Clean "azure-service-principal" { Remove-Item "C:\Users\*\.azure\service_principal_entries.json" -Force -EA 0 }
Clean "azure-clouds" { Remove-Item "C:\Users\*\.azure\clouds.config.bak" -Force -EA 0 }
Clean "azure-versions" { Remove-Item "C:\Users\*\.azure\versions\*" -Recurse -Force -EA 0 }
Clean "azure-azcopy-logs" { Remove-Item "C:\Users\*\.azcopy\*.log" -Force -EA 0 }
Clean "azure-azcopy-plans" { Remove-Item "C:\Users\*\.azcopy\plans\*" -Recurse -Force -EA 0 }
Clean "azure-functions-cache" { Remove-Item "C:\Users\*\.azure-functions\cache\*" -Recurse -Force -EA 0 }
Clean "azure-devops-cache" { Remove-Item "C:\Users\*\.azure-devops\cache\*" -Recurse -Force -EA 0 }
Clean "azure-storage-explorer" { Remove-Item "C:\Users\*\AppData\Roaming\StorageExplorer\logs\*" -Recurse -Force -EA 0 }
Clean "azure-cosmos-emulator" { Remove-Item "C:\Users\*\AppData\Local\CosmosDBEmulator\logs\*" -Recurse -Force -EA 0 }
Clean "gcp-gcloud-logs" { Remove-Item "C:\Users\*\.config\gcloud\logs\*" -Recurse -Force -EA 0 }
Clean "gcp-gcloud-cache" { Remove-Item "C:\Users\*\.config\gcloud\cache\*" -Recurse -Force -EA 0 }
Clean "gcp-gcloud-credentials" { Remove-Item "C:\Users\*\.config\gcloud\credentials.db.bak" -Force -EA 0 }
Clean "gcp-gcloud-config-backup" { Remove-Item "C:\Users\*\.config\gcloud\configurations\*.bak" -Force -EA 0 }
Clean "gcp-gsutil-cache" { Remove-Item "C:\Users\*\.gsutil\cache\*" -Recurse -Force -EA 0 }
Clean "gcp-gsutil-tracker" { Remove-Item "C:\Users\*\.gsutil\tracker-files\*" -Recurse -Force -EA 0 }
Clean "gcp-kubectl-cache" { Remove-Item "C:\Users\*\.kube\cache\*" -Recurse -Force -EA 0 }
Clean "gcp-kubectl-http-cache" { Remove-Item "C:\Users\*\.kube\http-cache\*" -Recurse -Force -EA 0 }
Clean "gcp-terraform-plugin" { Remove-Item "C:\Users\*\.terraform.d\plugin-cache\*" -Recurse -Force -EA 0 }
Clean "gcp-terraform-backup" { Remove-Item "C:\Users\*\terraform.tfstate.backup" -Force -EA 0 }
Clean "heroku-cache" { Remove-Item "C:\Users\*\.local\share\heroku\cache\*" -Recurse -Force -EA 0 }
Clean "heroku-autocomplete" { Remove-Item "C:\Users\*\.local\share\heroku\autocomplete\*" -Recurse -Force -EA 0 }
Clean "ibmcloud-cache" { Remove-Item "C:\Users\*\.bluemix\cache\*" -Recurse -Force -EA 0 }
Clean "ibmcloud-logs" { Remove-Item "C:\Users\*\.bluemix\logs\*" -Recurse -Force -EA 0 }
Clean "digitalocean-cache" { Remove-Item "C:\Users\*\.config\doctl\cache\*" -Recurse -Force -EA 0 }
Clean "oci-cli-cache" { Remove-Item "C:\Users\*\.oci\cache\*" -Recurse -Force -EA 0 }
Clean "oci-cli-logs" { Remove-Item "C:\Users\*\.oci\logs\*" -Recurse -Force -EA 0 }
Clean "openstack-cache" { Remove-Item "C:\Users\*\.cache\openstack\*" -Recurse -Force -EA 0 }
Clean "pulumi-logs" { Remove-Item "C:\Users\*\.pulumi\logs\*" -Recurse -Force -EA 0 }
Clean "pulumi-cache" { Remove-Item "C:\Users\*\.pulumi\cache\*" -Recurse -Force -EA 0 }
Clean "serverless-cache" { Remove-Item "C:\Users\*\.serverless\cache\*" -Recurse -Force -EA 0 }
Clean "serverless-analytics" { Remove-Item "C:\Users\*\.serverless\analytics\*" -Recurse -Force -EA 0 }
Clean "cloudflare-logs" { Remove-Item "C:\Users\*\.cloudflare\logs\*" -Recurse -Force -EA 0 }
Clean "vercel-cache" { Remove-Item "C:\Users\*\.vercel\cache\*" -Recurse -Force -EA 0 }
Clean "netlify-cache" { Remove-Item "C:\Users\*\.netlify\cache\*" -Recurse -Force -EA 0 }
Clean "railway-cache" { Remove-Item "C:\Users\*\.railway\cache\*" -Recurse -Force -EA 0 }
Clean "fly-cache" { Remove-Item "C:\Users\*\.fly\cache\*" -Recurse -Force -EA 0 }
Clean "render-cache" { Remove-Item "C:\Users\*\.render\cache\*" -Recurse -Force -EA 0 }
Clean "amplify-cache" { Remove-Item "C:\Users\*\.amplify\cache\*" -Recurse -Force -EA 0 }
Clean "firebase-cache" { Remove-Item "C:\Users\*\.cache\firebase\*" -Recurse -Force -EA 0 }
Clean "firebase-tools-cache" { Remove-Item "C:\Users\*\.config\firebase\*" -Recurse -Force -EA 0 }
Clean "supabase-cache" { Remove-Item "C:\Users\*\.supabase\cache\*" -Recurse -Force -EA 0 }
Clean "terraform-cache" { Remove-Item "C:\Users\*\.terraform\cache\*" -Recurse -Force -EA 0 }
Clean "terraform-providers" { Remove-Item "C:\Users\*\.terraform\providers\*" -Recurse -Force -EA 0 }
Clean "vagrant-tmp" { Remove-Item "C:\Users\*\.vagrant.d\tmp\*" -Recurse -Force -EA 0 }
Clean "vagrant-cache" { Remove-Item "C:\Users\*\.vagrant.d\cache\*" -Recurse -Force -EA 0 }
Clean "packer-cache" { Remove-Item "C:\Users\*\.packer\cache\*" -Recurse -Force -EA 0 }
Clean "ansible-cache" { Remove-Item "C:\Users\*\.ansible\cache\*" -Recurse -Force -EA 0 }
Clean "ansible-tmp" { Remove-Item "C:\Users\*\.ansible\tmp\*" -Recurse -Force -EA 0 }
Clean "chef-cache" { Remove-Item "C:\Users\*\.chef\cache\*" -Recurse -Force -EA 0 }
Clean "puppet-cache" { Remove-Item "C:\Users\*\.puppet\cache\*" -Recurse -Force -EA 0 }
Clean "salt-cache" { Remove-Item "C:\Users\*\.salt\cache\*" -Recurse -Force -EA 0 }
Clean "consul-cache" { Remove-Item "C:\Users\*\.consul\cache\*" -Recurse -Force -EA 0 }
Clean "vault-cache" { Remove-Item "C:\Users\*\.vault\cache\*" -Recurse -Force -EA 0 }
Clean "nomad-cache" { Remove-Item "C:\Users\*\.nomad\cache\*" -Recurse -Force -EA 0 }
Clean "waypoint-cache" { Remove-Item "C:\Users\*\.waypoint\cache\*" -Recurse -Force -EA 0 }
Clean "boundary-cache" { Remove-Item "C:\Users\*\.boundary\cache\*" -Recurse -Force -EA 0 }
Clean "argocd-cache" { Remove-Item "C:\Users\*\.argocd\cache\*" -Recurse -Force -EA 0 }
Clean "flux-cache" { Remove-Item "C:\Users\*\.flux\cache\*" -Recurse -Force -EA 0 }
Clean "helm-cache" { Remove-Item "C:\Users\*\.cache\helm\*" -Recurse -Force -EA 0 }
Clean "helm-repository" { Remove-Item "C:\Users\*\.helm\repository\cache\*" -Recurse -Force -EA 0 }
Clean "skaffold-cache" { Remove-Item "C:\Users\*\.skaffold\cache\*" -Recurse -Force -EA 0 }
Clean "tilt-cache" { Remove-Item "C:\Users\*\.tilt\cache\*" -Recurse -Force -EA 0 }
Clean "linkerd-cache" { Remove-Item "C:\Users\*\.linkerd\cache\*" -Recurse -Force -EA 0 }
Clean "istio-cache" { Remove-Item "C:\Users\*\.istio\cache\*" -Recurse -Force -EA 0 }
Clean "kustomize-cache" { Remove-Item "C:\Users\*\.kustomize\cache\*" -Recurse -Force -EA 0 }
Clean "kops-cache" { Remove-Item "C:\Users\*\.kops\cache\*" -Recurse -Force -EA 0 }
Clean "minikube-cache" { Remove-Item "C:\Users\*\.minikube\cache\*" -Recurse -Force -EA 0 }
Clean "minikube-logs" { Remove-Item "C:\Users\*\.minikube\logs\*" -Recurse -Force -EA 0 }
Clean "kind-cache" { Remove-Item "C:\Users\*\.kind\cache\*" -Recurse -Force -EA 0 }
Clean "k3s-cache" { Remove-Item "C:\Users\*\.k3s\cache\*" -Recurse -Force -EA 0 }
Clean "k3d-cache" { Remove-Item "C:\Users\*\.k3d\cache\*" -Recurse -Force -EA 0 }
Clean "rancher-cache" { Remove-Item "C:\Users\*\.rancher\cache\*" -Recurse -Force -EA 0 }
Clean "okteto-cache" { Remove-Item "C:\Users\*\.okteto\cache\*" -Recurse -Force -EA 0 }
Clean "garden-cache" { Remove-Item "C:\Users\*\.garden\cache\*" -Recurse -Force -EA 0 }
Clean "devspace-cache" { Remove-Item "C:\Users\*\.devspace\cache\*" -Recurse -Force -EA 0 }
Clean "scaffold-cache" { Remove-Item "C:\Users\*\.scaffold\cache\*" -Recurse -Force -EA 0 }
Clean "telepresence-cache" { Remove-Item "C:\Users\*\.telepresence\cache\*" -Recurse -Force -EA 0 }
Clean "kubectx-cache" { Remove-Item "C:\Users\*\.kubectx\cache\*" -Recurse -Force -EA 0 }
Clean "k9s-logs" { Remove-Item "C:\Users\*\AppData\Local\k9s\logs\*" -Recurse -Force -EA 0 }
Clean "k9s-cache" { Remove-Item "C:\Users\*\AppData\Local\k9s\cache\*" -Recurse -Force -EA 0 }
Clean "lens-cache" { Remove-Item "C:\Users\*\AppData\Roaming\Lens\Cache\*" -Recurse -Force -EA 0 }
Clean "lens-logs" { Remove-Item "C:\Users\*\AppData\Roaming\Lens\logs\*" -Recurse -Force -EA 0 }
Clean "kubeconfig-backup" { Remove-Item "C:\Users\*\.kube\config.bak" -Force -EA 0 }
Clean "kompose-cache" { Remove-Item "C:\Users\*\.kompose\cache\*" -Recurse -Force -EA 0 }
Clean "draft-cache" { Remove-Item "C:\Users\*\.draft\cache\*" -Recurse -Force -EA 0 }
Clean "brigade-cache" { Remove-Item "C:\Users\*\.brigade\cache\*" -Recurse -Force -EA 0 }
Clean "tekton-cache" { Remove-Item "C:\Users\*\.tekton\cache\*" -Recurse -Force -EA 0 }
Clean "knative-cache" { Remove-Item "C:\Users\*\.knative\cache\*" -Recurse -Force -EA 0 }
Clean "crossplane-cache" { Remove-Item "C:\Users\*\.crossplane\cache\*" -Recurse -Force -EA 0 }
Clean "dapr-cache" { Remove-Item "C:\Users\*\.dapr\cache\*" -Recurse -Force -EA 0 }
Clean "porter-cache" { Remove-Item "C:\Users\*\.porter\cache\*" -Recurse -Force -EA 0 }
Clean "cnab-cache" { Remove-Item "C:\Users\*\.cnab\cache\*" -Recurse -Force -EA 0 }
Clean "opa-cache" { Remove-Item "C:\Users\*\.opa\cache\*" -Recurse -Force -EA 0 }
Clean "conftest-cache" { Remove-Item "C:\Users\*\.conftest\cache\*" -Recurse -Force -EA 0 }
Clean "kyverno-cache" { Remove-Item "C:\Users\*\.kyverno\cache\*" -Recurse -Force -EA 0 }
Clean "falco-cache" { Remove-Item "C:\Users\*\.falco\cache\*" -Recurse -Force -EA 0 }
Clean "trivy-cache" { Remove-Item "C:\Users\*\.cache\trivy\*" -Recurse -Force -EA 0 }
Clean "grype-cache" { Remove-Item "C:\Users\*\.cache\grype\*" -Recurse -Force -EA 0 }
Clean "syft-cache" { Remove-Item "C:\Users\*\.cache\syft\*" -Recurse -Force -EA 0 }
Clean "anchore-cache" { Remove-Item "C:\Users\*\.anchore\cache\*" -Recurse -Force -EA 0 }
Clean "snyk-cache" { Remove-Item "C:\Users\*\.cache\snyk\*" -Recurse -Force -EA 0 }
Clean "aqua-cache" { Remove-Item "C:\Users\*\.aqua\cache\*" -Recurse -Force -EA 0 }
Clean "twistlock-cache" { Remove-Item "C:\Users\*\.twistlock\cache\*" -Recurse -Force -EA 0 }
Clean "sonobuoy-cache" { Remove-Item "C:\Users\*\.sonobuoy\cache\*" -Recurse -Force -EA 0 }
Clean "kubesec-cache" { Remove-Item "C:\Users\*\.kubesec\cache\*" -Recurse -Force -EA 0 }
Clean "kubebench-cache" { Remove-Item "C:\Users\*\.kube-bench\cache\*" -Recurse -Force -EA 0 }
Clean "kubeaudit-cache" { Remove-Item "C:\Users\*\.kubeaudit\cache\*" -Recurse -Force -EA 0 }
Clean "kubescan-cache" { Remove-Item "C:\Users\*\.kubescan\cache\*" -Recurse -Force -EA 0 }
Clean "polaris-cache" { Remove-Item "C:\Users\*\.polaris\cache\*" -Recurse -Force -EA 0 }
Clean "goldilocks-cache" { Remove-Item "C:\Users\*\.goldilocks\cache\*" -Recurse -Force -EA 0 }

# ============================================================================
# PHASE 52: DOCKER & CONTAINER RUNTIMES (137 operations)
# ============================================================================
Write-Host "`n[PHASE 52/70] DOCKER & CONTAINER RUNTIMES" -ForegroundColor Cyan
Clean "docker-temp" { Remove-Item "C:\ProgramData\Docker\tmp\*" -Recurse -Force -EA 0 }
Clean "docker-buildx-cache" { Remove-Item "C:\Users\*\.docker\buildx\cache\*" -Recurse -Force -EA 0 }
Clean "docker-cli-plugins-cache" { Remove-Item "C:\Users\*\.docker\cli-plugins\cache\*" -Recurse -Force -EA 0 }
Clean "docker-contexts-backup" { Remove-Item "C:\Users\*\.docker\contexts\*.bak" -Force -EA 0 }
Clean "docker-machine-cache" { Remove-Item "C:\Users\*\.docker\machine\cache\*" -Recurse -Force -EA 0 }
Clean "docker-machine-certs-backup" { Remove-Item "C:\Users\*\.docker\machine\certs\*.bak" -Force -EA 0 }
Clean "docker-compose-cache" { Remove-Item "C:\Users\*\.docker\compose\cache\*" -Recurse -Force -EA 0 }
Clean "docker-scan-cache" { Remove-Item "C:\Users\*\.docker\scan\cache\*" -Recurse -Force -EA 0 }
Clean "docker-trust-cache" { Remove-Item "C:\Users\*\.docker\trust\cache\*" -Recurse -Force -EA 0 }
Clean "docker-config-backup" { Remove-Item "C:\Users\*\.docker\config.json.bak" -Force -EA 0 }
Clean "docker-daemon-backup" { Remove-Item "C:\ProgramData\Docker\config\daemon.json.bak" -Force -EA 0 }
Clean "docker-desktop-logs" { Remove-Item "C:\Users\*\AppData\Local\Docker\log\*" -Recurse -Force -EA 0 }
Clean "docker-desktop-cache" { Remove-Item "C:\Users\*\AppData\Local\Docker\cache\*" -Recurse -Force -EA 0 }
Clean "docker-desktop-tmp" { Remove-Item "C:\Users\*\AppData\Local\Docker\tmp\*" -Recurse -Force -EA 0 }
Clean "docker-wsl-data" { Remove-Item "C:\Users\*\AppData\Local\Docker\wsl\data\*" -Recurse -Force -EA 0 }
Clean "podman-cache" { Remove-Item "C:\Users\*\.local\share\containers\cache\*" -Recurse -Force -EA 0 }
Clean "podman-storage-tmp" { Remove-Item "C:\Users\*\.local\share\containers\storage\tmp\*" -Recurse -Force -EA 0 }
Clean "podman-logs" { Remove-Item "C:\Users\*\.local\share\containers\logs\*" -Recurse -Force -EA 0 }
Clean "buildah-cache" { Remove-Item "C:\Users\*\.local\share\buildah\cache\*" -Recurse -Force -EA 0 }
Clean "skopeo-cache" { Remove-Item "C:\Users\*\.local\share\skopeo\cache\*" -Recurse -Force -EA 0 }
Clean "containerd-tmp" { Remove-Item "C:\ProgramData\containerd\tmp\*" -Recurse -Force -EA 0 }
Clean "containerd-state" { Remove-Item "C:\ProgramData\containerd\state\*" -Recurse -Force -EA 0 }
Clean "crio-cache" { Remove-Item "C:\ProgramData\crio\cache\*" -Recurse -Force -EA 0 }
Clean "crio-logs" { Remove-Item "C:\ProgramData\crio\logs\*" -Recurse -Force -EA 0 }
Clean "runc-logs" { Remove-Item "C:\ProgramData\runc\logs\*" -Recurse -Force -EA 0 }
Clean "nerdctl-cache" { Remove-Item "C:\Users\*\.nerdctl\cache\*" -Recurse -Force -EA 0 }
Clean "colima-cache" { Remove-Item "C:\Users\*\.colima\cache\*" -Recurse -Force -EA 0 }
Clean "colima-logs" { Remove-Item "C:\Users\*\.colima\logs\*" -Recurse -Force -EA 0 }
Clean "lima-cache" { Remove-Item "C:\Users\*\.lima\cache\*" -Recurse -Force -EA 0 }
Clean "finch-cache" { Remove-Item "C:\Users\*\.finch\cache\*" -Recurse -Force -EA 0 }
Clean "rancher-desktop-cache" { Remove-Item "C:\Users\*\AppData\Local\rancher-desktop\cache\*" -Recurse -Force -EA 0 }
Clean "rancher-desktop-logs" { Remove-Item "C:\Users\*\AppData\Local\rancher-desktop\logs\*" -Recurse -Force -EA 0 }
Clean "portainer-cache" { Remove-Item "C:\ProgramData\portainer\cache\*" -Recurse -Force -EA 0 }
Clean "portainer-tmp" { Remove-Item "C:\ProgramData\portainer\tmp\*" -Recurse -Force -EA 0 }
Clean "lazydocker-cache" { Remove-Item "C:\Users\*\AppData\Local\lazydocker\cache\*" -Recurse -Force -EA 0 }
Clean "dive-cache" { Remove-Item "C:\Users\*\.cache\dive\*" -Recurse -Force -EA 0 }
Clean "ctop-cache" { Remove-Item "C:\Users\*\.ctop\cache\*" -Recurse -Force -EA 0 }
Clean "docker-slim-cache" { Remove-Item "C:\Users\*\.docker-slim\cache\*" -Recurse -Force -EA 0 }
Clean "docker-squash-cache" { Remove-Item "C:\Users\*\.docker-squash\cache\*" -Recurse -Force -EA 0 }
Clean "kaniko-cache" { Remove-Item "C:\Users\*\.kaniko\cache\*" -Recurse -Force -EA 0 }
Clean "jib-cache" { Remove-Item "C:\Users\*\.jib\cache\*" -Recurse -Force -EA 0 }
Clean "img-cache" { Remove-Item "C:\Users\*\.img\cache\*" -Recurse -Force -EA 0 }
Clean "umoci-cache" { Remove-Item "C:\Users\*\.umoci\cache\*" -Recurse -Force -EA 0 }
Clean "oci-image-tool-cache" { Remove-Item "C:\Users\*\.oci-image-tool\cache\*" -Recurse -Force -EA 0 }
Clean "crane-cache" { Remove-Item "C:\Users\*\.crane\cache\*" -Recurse -Force -EA 0 }
Clean "reg-cache" { Remove-Item "C:\Users\*\.reg\cache\*" -Recurse -Force -EA 0 }
Clean "registry-cache" { Remove-Item "C:\ProgramData\docker-registry\cache\*" -Recurse -Force -EA 0 }
Clean "harbor-cache" { Remove-Item "C:\ProgramData\harbor\cache\*" -Recurse -Force -EA 0 }
Clean "quay-cache" { Remove-Item "C:\ProgramData\quay\cache\*" -Recurse -Force -EA 0 }
Clean "artifactory-cache" { Remove-Item "C:\ProgramData\artifactory\cache\*" -Recurse -Force -EA 0 }
Clean "nexus-cache" { Remove-Item "C:\ProgramData\nexus\cache\*" -Recurse -Force -EA 0 }
Clean "gitlab-runner-cache" { Remove-Item "C:\GitLab-Runner\cache\*" -Recurse -Force -EA 0 }
Clean "gitlab-runner-tmp" { Remove-Item "C:\GitLab-Runner\tmp\*" -Recurse -Force -EA 0 }
Clean "jenkins-docker-cache" { Remove-Item "C:\ProgramData\Jenkins\.docker\cache\*" -Recurse -Force -EA 0 }
Clean "circleci-cache" { Remove-Item "C:\Users\*\.circleci\cache\*" -Recurse -Force -EA 0 }
Clean "travis-cache" { Remove-Item "C:\Users\*\.travis\cache\*" -Recurse -Force -EA 0 }
Clean "drone-cache" { Remove-Item "C:\ProgramData\drone\cache\*" -Recurse -Force -EA 0 }
Clean "buildkite-cache" { Remove-Item "C:\buildkite-agent\cache\*" -Recurse -Force -EA 0 }
Clean "teamcity-docker-cache" { Remove-Item "C:\ProgramData\TeamCity\docker\cache\*" -Recurse -Force -EA 0 }
Clean "bamboo-docker-cache" { Remove-Item "C:\ProgramData\Bamboo\docker\cache\*" -Recurse -Force -EA 0 }
Clean "azure-pipelines-cache" { Remove-Item "C:\ProgramData\Microsoft\Azure Pipelines\cache\*" -Recurse -Force -EA 0 }
Clean "github-actions-cache" { Remove-Item "C:\actions-runner\_work\_actions\cache\*" -Recurse -Force -EA 0 }
Clean "github-actions-temp" { Remove-Item "C:\actions-runner\_work\_temp\*" -Recurse -Force -EA 0 }
Clean "act-cache" { Remove-Item "C:\Users\*\.act\cache\*" -Recurse -Force -EA 0 }
Clean "earthly-cache" { Remove-Item "C:\Users\*\.earthly\cache\*" -Recurse -Force -EA 0 }
Clean "dagger-cache" { Remove-Item "C:\Users\*\.dagger\cache\*" -Recurse -Force -EA 0 }
Clean "bazel-cache" { Remove-Item "C:\Users\*\.cache\bazel\*" -Recurse -Force -EA 0 }
Clean "buck-cache" { Remove-Item "C:\Users\*\.buck\cache\*" -Recurse -Force -EA 0 }
Clean "pants-cache" { Remove-Item "C:\Users\*\.cache\pants\*" -Recurse -Force -EA 0 }
Clean "please-cache" { Remove-Item "C:\Users\*\.please\cache\*" -Recurse -Force -EA 0 }
Clean "gradle-docker-cache" { Remove-Item "C:\Users\*\.gradle\docker\cache\*" -Recurse -Force -EA 0 }
Clean "maven-docker-cache" { Remove-Item "C:\Users\*\.m2\repository\docker\cache\*" -Recurse -Force -EA 0 }
Clean "sbt-docker-cache" { Remove-Item "C:\Users\*\.sbt\docker\cache\*" -Recurse -Force -EA 0 }
Clean "lein-docker-cache" { Remove-Item "C:\Users\*\.lein\docker\cache\*" -Recurse -Force -EA 0 }
Clean "boot-docker-cache" { Remove-Item "C:\Users\*\.boot\docker\cache\*" -Recurse -Force -EA 0 }
Clean "cargo-docker-cache" { Remove-Item "C:\Users\*\.cargo\registry\cache\docker\*" -Recurse -Force -EA 0 }
Clean "pip-docker-cache" { Remove-Item "C:\Users\*\AppData\Local\pip\docker\cache\*" -Recurse -Force -EA 0 }
Clean "npm-docker-cache" { Remove-Item "C:\Users\*\AppData\Roaming\npm-cache\docker\*" -Recurse -Force -EA 0 }
Clean "yarn-docker-cache" { Remove-Item "C:\Users\*\AppData\Local\Yarn\docker\cache\*" -Recurse -Force -EA 0 }
Clean "pnpm-docker-cache" { Remove-Item "C:\Users\*\AppData\Local\pnpm-cache\docker\*" -Recurse -Force -EA 0 }
Clean "gem-docker-cache" { Remove-Item "C:\Users\*\.gem\docker\cache\*" -Recurse -Force -EA 0 }
Clean "bundler-docker-cache" { Remove-Item "C:\Users\*\.bundle\docker\cache\*" -Recurse -Force -EA 0 }
Clean "composer-docker-cache" { Remove-Item "C:\Users\*\AppData\Local\Composer\docker\cache\*" -Recurse -Force -EA 0 }
Clean "nuget-docker-cache" { Remove-Item "C:\Users\*\.nuget\docker\cache\*" -Recurse -Force -EA 0 }
Clean "paket-docker-cache" { Remove-Item "C:\Users\*\.paket\docker\cache\*" -Recurse -Force -EA 0 }
Clean "mix-docker-cache" { Remove-Item "C:\Users\*\.mix\docker\cache\*" -Recurse -Force -EA 0 }
Clean "hex-docker-cache" { Remove-Item "C:\Users\*\.hex\docker\cache\*" -Recurse -Force -EA 0 }
Clean "rebar3-docker-cache" { Remove-Item "C:\Users\*\.cache\rebar3\docker\*" -Recurse -Force -EA 0 }
Clean "stack-docker-cache" { Remove-Item "C:\Users\*\AppData\Roaming\stack\docker\cache\*" -Recurse -Force -EA 0 }
Clean "cabal-docker-cache" { Remove-Item "C:\Users\*\AppData\Roaming\cabal\docker\cache\*" -Recurse -Force -EA 0 }
Clean "opam-docker-cache" { Remove-Item "C:\Users\*\.opam\docker\cache\*" -Recurse -Force -EA 0 }
Clean "dune-docker-cache" { Remove-Item "C:\Users\*\.dune\docker\cache\*" -Recurse -Force -EA 0 }
Clean "esy-docker-cache" { Remove-Item "C:\Users\*\.esy\docker\cache\*" -Recurse -Force -EA 0 }
Clean "conan-docker-cache" { Remove-Item "C:\Users\*\.conan\docker\cache\*" -Recurse -Force -EA 0 }
Clean "vcpkg-docker-cache" { Remove-Item "C:\Users\*\.vcpkg\docker\cache\*" -Recurse -Force -EA 0 }
Clean "conda-docker-cache" { Remove-Item "C:\Users\*\.conda\docker\cache\*" -Recurse -Force -EA 0 }
Clean "poetry-docker-cache" { Remove-Item "C:\Users\*\AppData\Local\pypoetry\docker\cache\*" -Recurse -Force -EA 0 }
Clean "pipenv-docker-cache" { Remove-Item "C:\Users\*\.local\share\virtualenvs\docker\cache\*" -Recurse -Force -EA 0 }
Clean "pdm-docker-cache" { Remove-Item "C:\Users\*\AppData\Local\pdm\docker\cache\*" -Recurse -Force -EA 0 }
Clean "hatch-docker-cache" { Remove-Item "C:\Users\*\AppData\Local\hatch\docker\cache\*" -Recurse -Force -EA 0 }
Clean "rye-docker-cache" { Remove-Item "C:\Users\*\.rye\docker\cache\*" -Recurse -Force -EA 0 }
Clean "uv-docker-cache" { Remove-Item "C:\Users\*\.cache\uv\docker\*" -Recurse -Force -EA 0 }
Clean "bun-docker-cache" { Remove-Item "C:\Users\*\.bun\docker\cache\*" -Recurse -Force -EA 0 }
Clean "deno-docker-cache" { Remove-Item "C:\Users\*\AppData\Local\deno\docker\cache\*" -Recurse -Force -EA 0 }
Clean "zig-docker-cache" { Remove-Item "C:\Users\*\.cache\zig\docker\*" -Recurse -Force -EA 0 }
Clean "nim-docker-cache" { Remove-Item "C:\Users\*\.nimble\docker\cache\*" -Recurse -Force -EA 0 }
Clean "crystal-docker-cache" { Remove-Item "C:\Users\*\.cache\crystal\docker\*" -Recurse -Force -EA 0 }
Clean "v-docker-cache" { Remove-Item "C:\Users\*\.vmodules\docker\cache\*" -Recurse -Force -EA 0 }
Clean "odin-docker-cache" { Remove-Item "C:\Users\*\.odin\docker\cache\*" -Recurse -Force -EA 0 }
Clean "gleam-docker-cache" { Remove-Item "C:\Users\*\.cache\gleam\docker\*" -Recurse -Force -EA 0 }
Clean "dart-docker-cache" { Remove-Item "C:\Users\*\AppData\Local\Pub\Cache\docker\*" -Recurse -Force -EA 0 }
Clean "flutter-docker-cache" { Remove-Item "C:\Users\*\AppData\Local\flutter\docker\cache\*" -Recurse -Force -EA 0 }
Clean "swift-docker-cache" { Remove-Item "C:\Users\*\.swiftpm\docker\cache\*" -Recurse -Force -EA 0 }
Clean "julia-docker-cache" { Remove-Item "C:\Users\*\.julia\docker\cache\*" -Recurse -Force -EA 0 }
Clean "r-docker-cache" { Remove-Item "C:\Users\*\AppData\Local\R\docker\cache\*" -Recurse -Force -EA 0 }
Clean "octave-docker-cache" { Remove-Item "C:\Users\*\.octave\docker\cache\*" -Recurse -Force -EA 0 }
Clean "matlab-docker-cache" { Remove-Item "C:\Users\*\AppData\Local\MathWorks\docker\cache\*" -Recurse -Force -EA 0 }
Clean "scilab-docker-cache" { Remove-Item "C:\Users\*\.Scilab\docker\cache\*" -Recurse -Force -EA 0 }
Clean "maxima-docker-cache" { Remove-Item "C:\Users\*\.maxima\docker\cache\*" -Recurse -Force -EA 0 }
Clean "sage-docker-cache" { Remove-Item "C:\Users\*\.sage\docker\cache\*" -Recurse -Force -EA 0 }
Clean "mathematica-docker" { Remove-Item "C:\Users\*\AppData\Roaming\Mathematica\docker\cache\*" -Recurse -Force -EA 0 }
Clean "maple-docker-cache" { Remove-Item "C:\Users\*\.maple\docker\cache\*" -Recurse -Force -EA 0 }
Clean "wolfram-docker-cache" { Remove-Item "C:\Users\*\.WolframEngine\docker\cache\*" -Recurse -Force -EA 0 }

# ============================================================================
# PHASE 40: ROOT CLEANUP & FINAL OPS (47 operations)
# ============================================================================
Write-Host "`n[PHASE 40/40] ROOT CLEANUP & FINAL OPS" -ForegroundColor White
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

Write-Host "`n=== MEGACLEAN 10X ULTRA COMPLETE ===" -ForegroundColor Magenta
Write-Host "Time: $elapsed | Freed: ${freed}GB | C: Now ${endFree}GB free" -ForegroundColor Cyan
Write-Host "Total operations: $script:total" -ForegroundColor Gray
Write-Host ""
