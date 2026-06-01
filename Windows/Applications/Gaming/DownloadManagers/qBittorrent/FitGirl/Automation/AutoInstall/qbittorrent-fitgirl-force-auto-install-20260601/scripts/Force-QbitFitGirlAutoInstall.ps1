<# Permanent qBittorrent -> FitGirl auto-install handoff for F:\Downloads. #>
[CmdletBinding()]
param(
  [switch]$Install,[switch]$Once,[switch]$Daemon,[switch]$RunOnceAfterInstall,
  [string]$DownloadRoot='F:\Downloads',[int]$PollSeconds=5,
  [string]$StateDir='F:\Downloads\.fitgirl_tmp\qbit-force-auto-install',
  [string]$QbitConfig="$env:APPDATA\qBittorrent\qBittorrent.ini",
  [string]$TorrentName,[string]$TorrentPath,[string]$TorrentRootPath,[string]$ContentPath
)
Set-StrictMode -Version 2.0
$ErrorActionPreference='Stop'

function Write-Log {
  param([string]$Message)
  if(-not(Test-Path -LiteralPath $StateDir)){ New-Item -ItemType Directory -Path $StateDir -Force | Out-Null }
  $line = ('{0:yyyy-MM-dd HH:mm:ss} {1}' -f (Get-Date), $Message)
  $logPath = Join-Path $StateDir 'force-auto-install.log'
  $wrote = $false
  for($attempt=1; $attempt -le 5 -and -not $wrote; $attempt++){
    try {
      Add-Content -LiteralPath $logPath -Value $line -Encoding UTF8 -ErrorAction Stop
      $wrote = $true
    } catch {
      Start-Sleep -Milliseconds (80 * $attempt)
    }
  }
  if(-not $wrote){
    try { [IO.File]::AppendAllText($logPath, $line + [Environment]::NewLine, [Text.Encoding]::UTF8) } catch {}
  }
  Write-Output $line
}
function ConvertTo-GameName {
  param([string]$Name)
  $n=[IO.Path]::GetFileName(($Name -replace '[\\/]+$',''))
  $n=$n -replace '\s*\[[^\]]*FitGirl[^\]]*\]\s*',''
  $n=$n -replace '\s*\([^\)]*FitGirl[^\)]*\)\s*',''
  $n=$n -replace '\s*[-–—]\s*FitGirl.*$',''
  $n=($n -replace '\s+',' ').Trim(' ','.','-','_')
  if([string]::IsNullOrWhiteSpace($n)){ $n='FitGirl Game' }
  foreach($c in [IO.Path]::GetInvalidFileNameChars()){ $n=$n.Replace([string]$c,'_') }
  return $n
}
function Find-BytesIndex {
  param([byte[]]$Haystack,[byte[]]$Needle,[int]$Start=0)
  for($i=$Start; $i -le $Haystack.Length-$Needle.Length; $i++){
    $ok=$true
    for($j=0; $j -lt $Needle.Length; $j++){ if($Haystack[$i+$j] -ne $Needle[$j]){ $ok=$false; break } }
    if($ok){ return $i }
  }
  return -1
}
function Test-QbitFastresumeCompleteForFolder {
  param([string]$FolderName)
  $bt=Join-Path $env:LOCALAPPDATA 'qBittorrent\BT_backup'
  if(-not(Test-Path -LiteralPath $bt)){ return $null }
  $nameBytes=[Text.Encoding]::UTF8.GetBytes($FolderName)
  $piecesTag=[Text.Encoding]::ASCII.GetBytes('6:pieces')
  foreach($fr in Get-ChildItem -LiteralPath $bt -Filter '*.fastresume' -File -ErrorAction SilentlyContinue){
    $bytes=[IO.File]::ReadAllBytes($fr.FullName)
    if((Find-BytesIndex $bytes $nameBytes 0) -lt 0){ continue }
    $pi=Find-BytesIndex $bytes $piecesTag 0
    if($pi -lt 0){ return $true }
    $i=$pi+$piecesTag.Length; $lenText=''
    while($i -lt $bytes.Length -and $bytes[$i] -ge 48 -and $bytes[$i] -le 57){ $lenText += [char]$bytes[$i]; $i++ }
    if($i -ge $bytes.Length -or $bytes[$i] -ne 58 -or [string]::IsNullOrWhiteSpace($lenText)){ return $null }
    $i++; $len=[int]$lenText
    if($i+$len -gt $bytes.Length){ return $null }
    for($k=$i; $k -lt $i+$len; $k++){ if($bytes[$k] -ne 1){ return $false } }
    return $true
  }
  return $null
}
function Test-SetupFolderComplete {
  param([string]$Folder)
  if(-not(Test-Path -LiteralPath $Folder -PathType Container)){ return $false }
  if(-not(Test-Path -LiteralPath (Join-Path $Folder 'setup.exe') -PathType Leaf)){ return $false }
  $partial=Get-ChildItem -LiteralPath $Folder -Recurse -Force -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -like '*.parts' -or $_.Name -like '*.!qB' -or $_.Name -like '*.aria2' -or $_.Name -like '*.part' } | Select-Object -First 1
  if($partial){ return $false }
  $bins=Get-ChildItem -LiteralPath $Folder -Force -File -ErrorAction SilentlyContinue | Where-Object { ($_.Name -like 'fg-*.bin' -or $_.Name -like '*.bin') -and $_.Length -gt 1MB } | Select-Object -First 1
  return [bool]$bins
}
function Get-RunningSetupCommandLines { try { Get-CimInstance Win32_Process -Filter "name='setup.exe'" | Select-Object ProcessId,ExecutablePath,CommandLine } catch { @() } }
function Test-AlreadyRunningForSetup {
  param([string]$SetupPath)
  $needle=$SetupPath.ToLowerInvariant()
  foreach($p in Get-RunningSetupCommandLines){
    $ep=[string]$p.ExecutablePath; $cl=[string]$p.CommandLine
    if($ep.ToLowerInvariant() -eq $needle -or $cl.ToLowerInvariant().Contains($needle)){ return $true }
  }
  return $false
}
function Test-FileLocked {
  param([string]$Path)
  if(-not(Test-Path -LiteralPath $Path -PathType Leaf)){ return $false }
  $fs=$null
  try { $fs=[IO.File]::Open($Path,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::None); return $false }
  catch { return $true }
  finally { if($fs){ $fs.Dispose() } }
}
function Start-FitGirlSetupExact {
  param([string]$SetupPath,[string]$InstallDir)
  if(-not(Test-Path -LiteralPath $InstallDir)){ New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null }
  $setupDir=[IO.Path]::GetDirectoryName($SetupPath)
  $marker=Join-Path $setupDir '.qbit-force-install-target.txt'
  Set-Content -LiteralPath $marker -Value ("setup={0}`r`ninstall_dir={1}`r`nstarted_utc={2:o}" -f $SetupPath,$InstallDir,(Get-Date).ToUniversalTime()) -Encoding UTF8
  $psi=New-Object Diagnostics.ProcessStartInfo
  $psi.FileName=$SetupPath; $psi.WorkingDirectory=$setupDir; $psi.Arguments=('/DIR="{0}" /NORESTART /SUPPRESSMSGBOXES /TASKS="" /MERGETASKS=""' -f $InstallDir); $psi.UseShellExecute=$false
  $p=[Diagnostics.Process]::Start($psi)
  Write-Log ("LAUNCHED setup pid={0} setup='{1}' install_dir='{2}'" -f $p.Id,$SetupPath,$InstallDir)
}
function Invoke-CompletedSweep {
  param([string[]]$Hints=@())
  if(-not(Test-Path -LiteralPath $StateDir)){ New-Item -ItemType Directory -Path $StateDir -Force | Out-Null }
  $launched=0; $skipped=0; $checked=0
  $roots=New-Object Collections.Generic.List[string]
  foreach($h in $Hints){
    if(-not[string]::IsNullOrWhiteSpace($h)){
      $p=$h.Trim('"'); if(Test-Path -LiteralPath $p -PathType Leaf){ $p=[IO.Path]::GetDirectoryName($p) }
      if(Test-Path -LiteralPath $p -PathType Container){ [void]$roots.Add($p) }
    }
  }
  if(Test-Path -LiteralPath $DownloadRoot){
    Get-ChildItem -LiteralPath $DownloadRoot -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -match 'FitGirl|Repack' -or (Test-Path -LiteralPath (Join-Path $_.FullName 'setup.exe')) } | ForEach-Object { [void]$roots.Add($_.FullName) }
  }
  $seen=@{}
  foreach($root in $roots){
    $item=Get-Item -LiteralPath $root -ErrorAction SilentlyContinue; if(-not$item){ continue }
    $full=$item.FullName; if([string]::IsNullOrWhiteSpace($full) -or $seen.ContainsKey($full.ToLowerInvariant())){ continue }
    $seen[$full.ToLowerInvariant()]=$true; $checked++
    if(-not(Test-SetupFolderComplete -Folder $full)){ $skipped++; Write-Log "SKIP not-complete-or-not-fitgirl '$full'"; continue }
    $qbtComplete=Test-QbitFastresumeCompleteForFolder -FolderName ([IO.Path]::GetFileName($full))
    if($qbtComplete -ne $true){ $skipped++; Write-Log "SKIP qbit-fastresume-not-confirmed-100pct '$full' state=$qbtComplete"; continue }
    $setup=Join-Path $full 'setup.exe'; $launchMarker=Join-Path $full '.qbit-force-install-target.txt'; $game=ConvertTo-GameName $full; $installDir=Join-Path $DownloadRoot $game
    if(Test-Path -LiteralPath $launchMarker -PathType Leaf){
      if(Test-AlreadyRunningForSetup -SetupPath $setup){ $skipped++; Write-Log "SKIP already-running marker='$launchMarker'"; continue }
      $targetFiles=@(Get-ChildItem -LiteralPath $installDir -Recurse -Force -File -ErrorAction SilentlyContinue)
      $mainExe=@($targetFiles | Where-Object { $_.Extension -eq '.exe' -and $_.Name -notmatch '^(unins|UnityCrash|QuickSFV|dxwebsetup|vc_redist)' } | Select-Object -First 1)
      if($mainExe.Count -gt 0){ $skipped++; Write-Log "SKIP already-installed marker='$launchMarker' target='$installDir' files=$($targetFiles.Count) main='$($mainExe[0].FullName)'"; continue }
      Remove-Item -LiteralPath $launchMarker -Force -ErrorAction SilentlyContinue
      Write-Log "RETRY stale-or-partial-marker marker='$launchMarker' target='$installDir' files=$($targetFiles.Count)"
    }
    if(Test-AlreadyRunningForSetup -SetupPath $setup){ $skipped++; Write-Log "SKIP already-running setup='$setup'"; continue }
    if(Test-FileLocked -Path $setup){ $skipped++; Write-Log "SKIP setup-locked-will-retry setup='$setup'"; continue }
    try { Start-FitGirlSetupExact -SetupPath $setup -InstallDir $installDir; $launched++ } catch { $skipped++; Write-Log ("SKIP launch-failed setup='{0}' install_dir='{1}' error='{2}'" -f $setup,$installDir,$_.Exception.Message) }
  }
  Write-Log ("SWEEP checked={0} launched={1} skipped={2}" -f $checked,$launched,$skipped)
}
function New-CommandWrappers {
  $wrapDir=Join-Path $env:APPDATA 'qbit-fitgirl-auto-install'; if(-not(Test-Path -LiteralPath $wrapDir)){ New-Item -ItemType Directory -Path $wrapDir -Force | Out-Null }
  $watcher=Join-Path $wrapDir 'watcher.cmd'; $hook=Join-Path $wrapDir 'qbit-hook.cmd'; $clicker=Join-Path $wrapDir 'clicker.cmd'; $ahkScript=Join-Path ([IO.Path]::GetDirectoryName($PSCommandPath)) 'FitGirlAutoClicker.ahk'; $nl=[Environment]::NewLine
  Set-Content -LiteralPath $watcher -Encoding ASCII -Value (("@echo off"+$nl+"powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"{0}`" -Daemon -PollSeconds {1}"+$nl) -f $PSCommandPath,$PollSeconds)
  Set-Content -LiteralPath $hook -Encoding ASCII -Value (("@echo off"+$nl+"powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"{0}`" -Once -TorrentName `"%~1`" -TorrentRootPath `"%~2`" -ContentPath `"%~3`""+$nl) -f $PSCommandPath)
  Set-Content -LiteralPath $clicker -Encoding ASCII -Value (("@echo off"+$nl+"`"C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe`" `"{0}`""+$nl) -f $ahkScript)
  [pscustomobject]@{Dir=$wrapDir;Watcher=$watcher;Hook=$hook;Clicker=$clicker;AhkScript=$ahkScript}
}
function Update-QbitCompletionHook {
  if(-not(Test-Path -LiteralPath $QbitConfig)){ Write-Log "qBittorrent config not found: $QbitConfig"; return }
  $wrappers=New-CommandWrappers; $cmd='"'+$wrappers.Hook+'" "%N" "%R" "%F"'; $stamp=Get-Date -Format 'yyyyMMdd-HHmmss'; $bak="$QbitConfig.qbit-force-auto-install-$stamp.bak"
  Copy-Item -LiteralPath $QbitConfig -Destination $bak -Force
  $lines=[Collections.Generic.List[string]](Get-Content -LiteralPath $QbitConfig -Encoding UTF8)
  $map=@{'Downloads\RunExternalProgram'='true';'Downloads\RunExternalProgramCommand'=$cmd}
  foreach($key in @($map.Keys)){
    $escaped=[regex]::Escape($key); $found=$false
    for($i=0; $i -lt $lines.Count; $i++){ if($lines[$i] -match "^$escaped="){ $lines[$i]="$key=$($map[$key])"; $found=$true; break } }
    if(-not$found){ $lines.Add("$key=$($map[$key])") }
  }
  Set-Content -LiteralPath $QbitConfig -Value $lines -Encoding UTF8
  Write-Log "qBittorrent completion hook configured; backup=$bak; command=$cmd"
}
function Register-Tasks {
  $wrappers=New-CommandWrappers
  $taskName='qBittorrent FitGirl Force AutoInstall Watcher'
  & schtasks.exe /Create /TN $taskName /SC ONLOGON /RL HIGHEST /F /TR ('"'+$wrappers.Watcher+'"') | Out-Null
  & schtasks.exe /Run /TN $taskName | Out-Null
  Write-Log "Scheduled task enabled and started: $taskName wrapper=$($wrappers.Watcher)"
  $ahk='C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe'
  if((Test-Path -LiteralPath $ahk -PathType Leaf) -and (Test-Path -LiteralPath $wrappers.AhkScript -PathType Leaf)){
    $clickTask='qBittorrent FitGirl Installer Dialog Watchdog'
    & schtasks.exe /Create /TN $clickTask /SC ONLOGON /RL HIGHEST /F /TR ('"'+$wrappers.Clicker+'"') | Out-Null
    & schtasks.exe /Run /TN $clickTask | Out-Null
    Write-Log "Installer dialog AutoHotkey task enabled and started: $clickTask wrapper=$($wrappers.Clicker)"
  }
}
if($Install){ Write-Log 'INSTALL starting'; Update-QbitCompletionHook; Register-Tasks; if($RunOnceAfterInstall){ Invoke-CompletedSweep -Hints @($TorrentRootPath,$ContentPath,$TorrentPath) }; Write-Log 'INSTALL finished'; return }
if($Daemon){ Write-Log "DAEMON started poll=${PollSeconds}s download_root=$DownloadRoot"; while($true){ try{ Invoke-CompletedSweep -Hints @($TorrentRootPath,$ContentPath,$TorrentPath) } catch { Write-Log ('ERROR '+$_.Exception.Message) }; Start-Sleep -Seconds $PollSeconds } }
Invoke-CompletedSweep -Hints @($TorrentRootPath,$ContentPath,$TorrentPath)
