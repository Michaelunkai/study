<# Permanent qBittorrent -> FitGirl auto-install handoff for F:\Downloads. #>
[CmdletBinding()]
param(
  [switch]$Install,[switch]$Once,[switch]$Daemon,[switch]$RunOnceAfterInstall,
  [string]$DownloadRoot='F:\Downloads',[int]$PollSeconds=1,[int]$PollMilliseconds=250,[int]$MaxConcurrentInstalls=0,[int]$InstallStallMinutes=6,
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
  $n=$n -replace '\s*[-]\s*FitGirl.*$',''
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
function Normalize-QbitComparableName {
  param([string]$Name)
  $n=($Name -replace '[\/]+$','')
  try { $n=[Net.WebUtility]::HtmlDecode($n) } catch {}
  $n=$n.Normalize([Text.NormalizationForm]::FormD)
  $n=([regex]::Replace($n,'\p{Mn}',''))
  $n=$n.ToLowerInvariant()
  $n=$n -replace '&',' and '
  $n=$n -replace '\bsr\b',' soul reaver '
  $n=$n -replace '[\/]+',' '
  $n=$n -replace '\[[^\]]*\]',' '
  $n=$n -replace '\([^\)]*\)',' '
  $n=$n -replace '[:_–—]+',' '
  $n=$n -replace '-',' '
  $n=$n -replace 'fitgirl|hypervisor|repack|selective|download|complete|edition|supporter|digital deluxe|early adopter|multi\d+|dlcs?|bonuses|bonus|content|release|from\s+\d+(\.\d+)?\s*(gb|mb)|v\d+(\.\d+)*',' '
  $n=$n -replace '[^a-z0-9]+',' '
  $n=($n -replace '\s+',' ').Trim()
  return $n
}
function Test-QbitNameMatch {
  param([string]$FolderNorm,[string]$TorrentNorm)
  if([string]::IsNullOrWhiteSpace($FolderNorm) -or [string]::IsNullOrWhiteSpace($TorrentNorm)){ return $false }
  $folderTokens=@($FolderNorm -split '\s+' | Where-Object { $_.Length -ge 2 -and $_ -notmatch '^(the|and|of|za|z|a)$' })
  $torrentTokens=@($TorrentNorm -split '\s+' | Where-Object { $_.Length -ge 2 -and $_ -notmatch '^(the|and|of|za|z|a)$' })
  if($folderTokens.Count -eq 0 -or $torrentTokens.Count -eq 0){ return $false }
  function Test-TokenPrefix([string[]]$Short,[string[]]$Long){
    if($Short.Count -gt $Long.Count){ return $false }
    for($i=0; $i -lt $Short.Count; $i++){ if($Short[$i] -ne $Long[$i]){ return $false } }
    return $true
  }
  # Strict anti-wrong-game gate: only accept exact token-prefix matches. This keeps
  # yakuza 3 -> yakuza 3 remastered valid while refusing sibling titles such as
  # yakuza 3 vs yakuza kiwami, or Hermes Auto Test Alpha vs Beta/Gamma.
  if(Test-TokenPrefix -Short $folderTokens -Long $torrentTokens){ return $true }
  if(Test-TokenPrefix -Short $torrentTokens -Long $folderTokens){ return $true }
  return $false
}
function Test-HintMatchesFolder {
  param([string]$Folder,[string[]]$Hints=@(),[string]$TorrentName='')
  if([string]::IsNullOrWhiteSpace($Folder)){ return $false }
  $folderFull=([IO.Path]::GetFullPath($Folder)).TrimEnd('\')
  $folderName=[IO.Path]::GetFileName($folderFull)
  foreach($h in $Hints){
    if([string]::IsNullOrWhiteSpace($h)){ continue }
    try {
      $p=$h.Trim('"')
      if(Test-Path -LiteralPath $p -PathType Leaf){ $p=[IO.Path]::GetDirectoryName($p) }
      if(Test-Path -LiteralPath $p -PathType Container){
        $hintFull=([IO.Path]::GetFullPath($p)).TrimEnd('\')
        if($hintFull.Equals($folderFull,[StringComparison]::OrdinalIgnoreCase)){ return $true }
        if($folderFull.StartsWith($hintFull+'\',[StringComparison]::OrdinalIgnoreCase)){ return $true }
        if($hintFull.StartsWith($folderFull+'\',[StringComparison]::OrdinalIgnoreCase)){ return $true }
      }
    } catch {}
  }
  if(-not [string]::IsNullOrWhiteSpace($TorrentName)){
    try {
      $folderNorm=Normalize-QbitComparableName $folderName
      $torrentNorm=Normalize-QbitComparableName $TorrentName
      if(Test-QbitNameMatch -FolderNorm $folderNorm -TorrentNorm $torrentNorm){ return $true }
    } catch {}
  }
  return $false
}
function Get-BencodedStringAfterKey {
  param([string]$Text,[string]$Key)
  $idx=$Text.IndexOf($Key,[StringComparison]::Ordinal)
  if($idx -lt 0){ return $null }
  $pos=$idx + $Key.Length
  $colon=$Text.IndexOf(':',$pos)
  if($colon -lt 0){ return $null }
  $lenText=$Text.Substring($pos,$colon-$pos)
  $n=0
  if(-not [int]::TryParse($lenText,[ref]$n)){ return $null }
  $start=$colon+1
  if($start+$n -gt $Text.Length){ return $null }
  return $Text.Substring($start,$n)
}
function Test-QbitFastresumeCompleteForFolder {
  param([string]$FolderName)
  $bt=Join-Path $env:LOCALAPPDATA 'qBittorrent\BT_backup'
  if(-not(Test-Path -LiteralPath $bt)){ return $null }
  $folderNorm=Normalize-QbitComparableName $FolderName
  $matchedIncomplete=$false
  foreach($fr in Get-ChildItem -LiteralPath $bt -Filter '*.fastresume' -File -ErrorAction SilentlyContinue){
    $bytes=[IO.File]::ReadAllBytes($fr.FullName)
    $text=[Text.Encoding]::UTF8.GetString($bytes)
    $torrentName=Get-BencodedStringAfterKey -Text $text -Key '8:qBt-name'
    if([string]::IsNullOrWhiteSpace($torrentName)){ $torrentName=Get-BencodedStringAfterKey -Text $text -Key '4:name' }
    if([string]::IsNullOrWhiteSpace($torrentName)){ continue }
    $torrentNorm=Normalize-QbitComparableName $torrentName
    if([string]::IsNullOrWhiteSpace($folderNorm) -or [string]::IsNullOrWhiteSpace($torrentNorm)){ continue }
    $match=Test-QbitNameMatch -FolderNorm $folderNorm -TorrentNorm $torrentNorm
    if(-not $match){ continue }
    $completedTime=0; $finishedTime=0; $seedStatus=-1
    if($text -match '14:completed_timei(?<v>-?\d+)e'){ $completedTime=[int64]$Matches.v }
    if($text -match '13:finished_timei(?<v>-?\d+)e'){ $finishedTime=[int64]$Matches.v }
    if($text -match '14:qBt-seedStatusi(?<v>-?\d+)e'){ $seedStatus=[int]$Matches.v }
    Write-Log ("FASTRESUME_MATCH folder='{0}' torrent='{1}' completed_time={2} finished_time={3} seed_status={4}" -f $FolderName,$torrentName,$completedTime,$finishedTime,$seedStatus) | Out-Null
    # Strict 100% gate: qBittorrent must have recorded completion for this torrent.
    # Do not accept seedStatus/finishedTime alone because partially-downloaded folders can still contain setup.exe + .bin files.
    if($completedTime -gt 0){ return $true }
    $matchedIncomplete=$true
  }
  if($matchedIncomplete){ return $false }
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

function Get-SourcePayloadSignature {
  param([string]$Folder,[string]$Md5Path)
  $items=New-Object Collections.Generic.List[string]
  try {
    if(Test-Path -LiteralPath $Md5Path -PathType Leaf){
      $md5Item=Get-Item -LiteralPath $Md5Path -ErrorAction Stop
      [void]$items.Add(('md5={0}|{1}|{2}' -f $md5Item.FullName.ToLowerInvariant(),$md5Item.Length,$md5Item.LastWriteTimeUtc.Ticks))
      foreach($line in Get-Content -LiteralPath $Md5Path -ErrorAction Stop){
        $trim=$line.Trim()
        if($trim -eq '' -or $trim.StartsWith(';') -or $trim.StartsWith('#')){ continue }
        if($trim -notmatch '^(?<hash>[a-fA-F0-9]{32})\s+\*?(?<rel>.+)$'){ continue }
        $rel=$Matches.rel.Trim().Trim('"')
        $file=[IO.Path]::GetFullPath((Join-Path ([IO.Path]::GetDirectoryName($Md5Path)) $rel))
        if(Test-Path -LiteralPath $file -PathType Leaf){
          $it=Get-Item -LiteralPath $file -ErrorAction Stop
          [void]$items.Add(('{0}|{1}|{2}' -f $it.FullName.ToLowerInvariant(),$it.Length,$it.LastWriteTimeUtc.Ticks))
        } else {
          [void]$items.Add(('missing={0}' -f $file.ToLowerInvariant()))
        }
      }
    } else {
      foreach($it in Get-ChildItem -LiteralPath $Folder -File -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -like 'fg-*.bin' -or $_.Name -like '*.bin' }){
        [void]$items.Add(('{0}|{1}|{2}' -f $it.FullName.ToLowerInvariant(),$it.Length,$it.LastWriteTimeUtc.Ticks))
      }
    }
  } catch {
    [void]$items.Add(('signature-error={0}' -f $_.Exception.Message))
  }
  return (($items | Sort-Object) -join "`n")
}

function Test-FitGirlMd5Preflight {
  param([string]$SetupPath)
  $setupDir=[IO.Path]::GetDirectoryName($SetupPath)
  $md5Path=Join-Path $setupDir 'MD5\fitgirl-bins.md5'
  # Immediate-launch policy: never block a ready qBittorrent-completed download for long full-file hashes.
  # This preflight is intentionally fast: catch missing/empty required payloads only, then let setup start immediately.
  # Runtime AHK still catches ISDone/Unarc CRC/checksum popups and marks only that exact source.
  if(-not(Test-Path -LiteralPath $md5Path -PathType Leaf)){
    Write-Log "PREFLIGHT_MD5_ABSENT_ALLOW_FAST setup_dir='$setupDir'" | Out-Null
    return $true
  }
  $failures=New-Object Collections.Generic.List[string]
  $checked=0
  foreach($line in Get-Content -LiteralPath $md5Path -ErrorAction Stop){
    $trim=$line.Trim()
    if($trim -eq '' -or $trim.StartsWith(';') -or $trim.StartsWith('#')){ continue }
    if($trim -notmatch '^(?<hash>[a-fA-F0-9]{32})\s+\*?(?<rel>.+)$'){ continue }
    $rel=$Matches.rel.Trim().Trim('"')
    $file=[IO.Path]::GetFullPath((Join-Path ([IO.Path]::GetDirectoryName($md5Path)) $rel))
    $name=[IO.Path]::GetFileName($file)
    $isOptional=($name -match 'optional|selective|bonus|tutorial|video|language|credits|ost')
    if(-not(Test-Path -LiteralPath $file -PathType Leaf)){
      if($isOptional){ Write-Log "PREFLIGHT_MD5_OPTIONAL_MISSING_OK file='$file'" | Out-Null; continue }
      [void]$failures.Add("missing-required-bin:$file")
      continue
    }
    try {
      $item=Get-Item -LiteralPath $file -ErrorAction Stop
      $checked++
      if($item.Length -le 0){ [void]$failures.Add("empty-required-bin:$file") }
    } catch {
      [void]$failures.Add("bin-read-error:$file error=$($_.Exception.Message)")
    }
  }
  if($failures.Count -gt 0){
    $reason='SOURCE_INTEGRITY_FAILED_FAST '+(($failures | Select-Object -First 8) -join '; ')
    Write-SourceHardFailMarker -SetupPath $SetupPath -Reason $reason
    Write-Log "PREFLIGHT_MD5_FAST_FAILED setup='$SetupPath' checked=$checked failures='$($failures.Count)'" | Out-Null
    return $false
  }
  Write-Log "PREFLIGHT_MD5_FAST_OK_NO_HASH_DELAY setup='$SetupPath' checked=$checked" | Out-Null
  return $true
}

function Test-InstallTargetPreflight {
  param([string]$InstallDir,[string]$SetupPath)
  try {
    $root=[IO.Path]::GetPathRoot([IO.Path]::GetFullPath($InstallDir))
    $drive=Get-PSDrive -Name $root.Substring(0,1) -ErrorAction Stop
    $sourceBytes=(Get-ChildItem -LiteralPath ([IO.Path]::GetDirectoryName($SetupPath)) -Recurse -Force -File -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
    $required=[Math]::Max(10GB,[int64]($sourceBytes * 1.15))
    if($drive.Free -lt $required){
      Write-Log ("PREFLIGHT_DISK_BLOCK install_dir='{0}' free_gb={1:n1} required_gb={2:n1}" -f $InstallDir,($drive.Free/1GB),($required/1GB)) | Out-Null
      return $false
    }
    $probeDir=Split-Path -Parent $InstallDir
    if(-not(Test-Path -LiteralPath $probeDir -PathType Container)){ New-Item -ItemType Directory -Path $probeDir -Force | Out-Null }
    $probe=Join-Path $probeDir ('.qbit-write-probe-{0}.tmp' -f ([guid]::NewGuid().ToString('N')))
    Set-Content -LiteralPath $probe -Value 'probe' -Encoding ASCII -Force
    Remove-Item -LiteralPath $probe -Force -ErrorAction SilentlyContinue
    return $true
  } catch {
    Write-Log ("PREFLIGHT_TARGET_BLOCK install_dir='{0}' error='{1}'" -f $InstallDir,$_.Exception.Message) | Out-Null
    return $false
  }
}

function Get-StabilityMarkerPath {
  param([string]$Folder)
  if(-not(Test-Path -LiteralPath $StateDir)){ New-Item -ItemType Directory -Path $StateDir -Force | Out-Null }
  $sha=[Security.Cryptography.SHA256]::Create()
  try {
    $bytes=[Text.Encoding]::UTF8.GetBytes(([IO.Path]::GetFullPath($Folder)).ToLowerInvariant())
    $hash=([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-','').ToLowerInvariant()
    return (Join-Path $StateDir ("stable-ready-$hash.txt"))
  } finally { $sha.Dispose() }
}
function Test-ExternalDownloaderIncompleteForFolder {
  param([string]$Folder)
  try {
    if([string]::IsNullOrWhiteSpace($Folder)){ return $false }
    $full=[IO.Path]::GetFullPath($Folder).TrimEnd('\')
    $leaf=[IO.Path]::GetFileName($full)
    $norm=Normalize-QbitComparableName $leaf
    $manager=Join-Path $env:APPDATA 'com.fitlauncher.carrotrub\manager.json'
    if(Test-Path -LiteralPath $manager -PathType Leaf){
      try {
        $jobs=Get-Content -LiteralPath $manager -Raw -Encoding UTF8 | ConvertFrom-Json
        foreach($entry in @($jobs.PSObject.Properties)){
          $j=$entry.Value; if($null -eq $j){ continue }
          $paths=@(''+$j.job_path,''+$j.path)
          $titles=@(''+$j.title,''+$j.name,''+$j.metadata.game_title,''+$j.game.title)
          $match=$false
          foreach($jp in $paths){ if(-not[string]::IsNullOrWhiteSpace($jp)){ try { if([IO.Path]::GetFullPath($jp).TrimEnd('\') -ieq $full){ $match=$true } } catch {} } }
          if(-not $match){ foreach($t in $titles){ if((Normalize-QbitComparableName $t) -eq $norm -and -not[string]::IsNullOrWhiteSpace($norm)){ $match=$true } } }
          if(-not $match){ continue }
          $total=0L; $done=0L; try{$total=[int64]$j.totalLength}catch{}; try{$done=[int64]$j.downloaded}catch{}
          try{ if($j.status.totalLength -and [int64]$j.status.totalLength -gt $total){$total=[int64]$j.status.totalLength} }catch{}
          try{ if($j.status.completedLength -and [int64]$j.status.completedLength -gt $done){$done=[int64]$j.status.completedLength} }catch{}
          $state=(''+$j.state+' '+$j.status.state).ToLowerInvariant()
          if(($state -match 'active|waiting|paused|downloading') -or ($total -gt 0 -and $done -lt $total)){
            Write-Log ("WAIT external-downloader-incomplete folder='{0}' job='{1}' state='{2}' bytes={3}/{4}" -f $Folder,$entry.Name,$state,$done,$total) | Out-Null
            return $true
          }
        }
      } catch { Write-Log ("EXTERNAL_DOWNLOADER_MANAGER_WARN folder='{0}' error='{1}'" -f $Folder,$_.Exception.Message) | Out-Null }
    }
  } catch { Write-Log ("EXTERNAL_DOWNLOADER_INCOMPLETE_WARN folder='{0}' error='{1}'" -f $Folder,$_.Exception.Message) | Out-Null }
  return $false
}

function Test-FilesystemStableReady {
  param([string]$Folder)
  $setup=Join-Path $Folder 'setup.exe'
  if(-not(Test-SetupFolderComplete -Folder $Folder)){ return $false }
  if(Test-FileLocked -Path $setup){ return $false }
  $files=@(Get-ChildItem -LiteralPath $Folder -Recurse -Force -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -notlike '*.aria2' -and $_.Name -notlike '*.!qB' -and $_.Name -notlike '*.part' -and $_.Name -notlike '*.parts' })
  if($files.Count -eq 0){ return $false }
  $bytes=($files | Measure-Object Length -Sum).Sum
  $maxTicks=($files | Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 1).LastWriteTimeUtc.Ticks
  $sig="count=$($files.Count);bytes=$bytes;maxticks=$maxTicks"
  $marker=Get-StabilityMarkerPath -Folder $Folder
  $prev=''
  try { if(Test-Path -LiteralPath $marker -PathType Leaf){ $prev=Get-Content -LiteralPath $marker -Raw -ErrorAction Stop } } catch {}
  Set-Content -LiteralPath $marker -Value $sig -Encoding ASCII -Force
  return ($prev.Trim() -eq $sig)
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

function Get-MainInstalledExe {
  param([string]$InstallDir)
  if(-not(Test-Path -LiteralPath $InstallDir -PathType Container)){ return $null }
  $main=@(Get-ChildItem -LiteralPath $InstallDir -Recurse -Force -File -ErrorAction SilentlyContinue | Where-Object {
    if($_.Extension -ne '.exe'){ return $false }
    if($_.Name -match '^(unins|UnityCrash|CrashReport|QuickSFV|FitGirl-Launcher|dxwebsetup|vc_redist|vcredist|directx|redist)'){ return $false }
    if($_.Name -match '^(Language Selector|LanguageSelector|Launcher Helper)\.exe$'){ return $false }
    $full=$_.FullName
    if($full -match '\\(_Redist|Redist|DirectX|Support|temp|tmp)\\'){ return $false }
    if($_.Length -lt 512KB){ return $false }
    return $true
  } | Sort-Object Length -Descending | Select-Object -First 1)
  if($main.Count -gt 0){ return $main[0].FullName }
  return $null
}
function Get-DoneMarkerData {
  param([string]$Marker)
  if(-not(Test-Path -LiteralPath $Marker -PathType Leaf)){ return @{} }
  try { return ConvertFrom-MarkerText -Text (Get-Content -LiteralPath $Marker -Raw -ErrorAction Stop) } catch { return @{} }
}
function Test-TrustedAhkDoneMarker {
  param([hashtable]$Data,[string]$InstallDir)
  if(-not(Test-Path -LiteralPath $InstallDir -PathType Container)){ return $false }
  $reason=''
  if($Data.ContainsKey('reason')){ $reason=[string]$Data['reason'] }
  return ($reason -match '^(finish-button-clicked|final-page-left-open|finalization-missing-helper)')
}
function Get-SetupSignature {
  param([string]$SetupPath)
  $i=Get-Item -LiteralPath $SetupPath -ErrorAction Stop
  return ('{0}|{1}|{2}' -f $i.FullName.ToLowerInvariant(),$i.Length,$i.LastWriteTimeUtc.Ticks)
}
function ConvertFrom-MarkerText {
  param([string]$Text)
  $map=@{}
  if([string]::IsNullOrWhiteSpace($Text)){ return $map }
  foreach($line in ($Text -replace "`r",'') -split "`n"){
    if([string]::IsNullOrWhiteSpace($line)){ continue }
    $idx=$line.IndexOf('=')
    if($idx -le 0){ continue }
    $key=$line.Substring(0,$idx).Trim()
    $val=$line.Substring($idx+1).Trim()
    if(-not [string]::IsNullOrWhiteSpace($key)){ $map[$key]=$val }
  }
  return $map
}
function Get-LaunchMarkerData {
  param([string]$Marker)
  if(-not(Test-Path -LiteralPath $Marker -PathType Leaf)){ return @{} }
  try { return ConvertFrom-MarkerText -Text (Get-Content -LiteralPath $Marker -Raw -ErrorAction Stop) } catch { return @{} }
}

function Write-SourceHardFailMarker {
  param([string]$SetupPath,[string]$Reason)
  $setupDir=[IO.Path]::GetDirectoryName($SetupPath)
  $marker=Join-Path $setupDir '.qbit-force-hard-fail.txt'
  $line=('{0:yyyy-MM-dd HH:mm:ss} {1}' -f (Get-Date),$Reason)
  Add-Content -LiteralPath $marker -Value $line -Encoding UTF8
  Write-Log ("HARD_FAIL_MARKER_WRITTEN setup='{0}' reason='{1}'" -f $SetupPath,$Reason) | Out-Null
}
function Remove-IncompleteInstallTarget {
  param([string]$InstallDir,[string]$Reason)
  if([string]::IsNullOrWhiteSpace($InstallDir)){ return }
  if(-not(Test-Path -LiteralPath $InstallDir -PathType Container)){ return }
  try {
    $targetRoot=[IO.Path]::GetFullPath($InstallDir).TrimEnd('\\')
    $targetPrefix=$targetRoot+'\\'
    $procs=@(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object { $ep=''+$_.ExecutablePath; ($ep -ieq $targetRoot) -or $ep.StartsWith($targetPrefix,[StringComparison]::OrdinalIgnoreCase) })
    foreach($proc in $procs){ try { Stop-Process -Id $proc.ProcessId -Force -ErrorAction SilentlyContinue; Write-Log ("STOP incomplete-target-process pid={0} exe='{1}' reason='{2}'" -f $proc.ProcessId,$proc.ExecutablePath,$Reason) } catch {} }
    Remove-Item -LiteralPath $InstallDir -Recurse -Force -ErrorAction Stop
    Write-Log ("DELETE_INCOMPLETE_INSTALL_TARGET target='{0}' reason='{1}'" -f $InstallDir,$Reason)
  } catch {
    Write-Log ("DELETE_INCOMPLETE_INSTALL_TARGET_FAILED target='{0}' reason='{1}' error='{2}'" -f $InstallDir,$Reason,$_.Exception.Message)
  }
}
function Test-PriorLaunchCrashedOrStopped {
  param([string]$SetupPath,[string]$InstallDir,[string]$LaunchMarker)
  if(-not(Test-Path -LiteralPath $LaunchMarker -PathType Leaf)){ return $false }
  if(Test-SetupProcessRunningForSource -SetupPath $SetupPath){ return $false }
  if(-not [string]::IsNullOrWhiteSpace((Get-MainInstalledExe -InstallDir $InstallDir))){ return $false }
  $data=Get-LaunchMarkerData -Marker $LaunchMarker
  $startedText=''
  if($data.ContainsKey('started_utc')){ $startedText=[string]$data['started_utc'] }
  $started=[datetime]::MinValue
  if(-not [datetime]::TryParse($startedText,[Globalization.CultureInfo]::InvariantCulture,[Globalization.DateTimeStyles]::AssumeUniversal,[ref]$started)){ $started=(Get-Item -LiteralPath $LaunchMarker).LastWriteTimeUtc }
  $age=[datetime]::UtcNow - $started.ToUniversalTime()
  if($age.TotalSeconds -lt 120){ return $false }
  $reason=('previous-launched-installer-exited-without-success age_seconds={0:n0}' -f $age.TotalSeconds)
  Write-SourceHardFailMarker -SetupPath $SetupPath -Reason $reason
  Remove-IncompleteInstallTarget -InstallDir $InstallDir -Reason $reason
  try { Remove-Item -LiteralPath $LaunchMarker -Force -ErrorAction SilentlyContinue } catch {}
  return $true
}
function Write-LaunchMarker {
  param([string]$Marker,[string]$SetupPath,[string]$InstallDir,[string]$Status='launched')
  $sig=Get-SetupSignature -SetupPath $SetupPath
  Set-Content -LiteralPath $Marker -Value ("setup={0}`r`ninstall_dir={1}`r`nsignature={2}`r`nstatus={3}`r`nstarted_utc={4:o}" -f $SetupPath,$InstallDir,$sig,$Status,(Get-Date).ToUniversalTime()) -Encoding UTF8
}
function Write-InstallDoneMarker {
  param([string]$SetupPath,[string]$InstallDir,[string]$Reason='detected-installed')
  $setupDir=[IO.Path]::GetDirectoryName($SetupPath)
  $marker=Join-Path $setupDir '.qbit-force-install-done.txt'
  $exe=Get-MainInstalledExe -InstallDir $InstallDir
  Set-Content -LiteralPath $marker -Value ("setup={0}`r`ninstall_dir={1}`r`nmain_exe={2}`r`nreason={3}`r`ndone_utc={4:o}" -f $SetupPath,$InstallDir,$exe,$Reason,(Get-Date).ToUniversalTime()) -Encoding UTF8
  Write-Log ("INSTALL_DONE_MARKER setup='{0}' install_dir='{1}' exe='{2}' reason='{3}'" -f $SetupPath,$InstallDir,$exe,$Reason)
}
function Test-InstallDoneMarker {
  param([string]$SetupPath,[string]$InstallDir)
  $setupDir=[IO.Path]::GetDirectoryName($SetupPath)
  $marker=Join-Path $setupDir '.qbit-force-install-done.txt'
  $exe=Get-MainInstalledExe -InstallDir $InstallDir
  if(Test-Path -LiteralPath $marker -PathType Leaf){
    $data=Get-DoneMarkerData -Marker $marker
    if(-not [string]::IsNullOrWhiteSpace($exe)){ return $true }
    if(Test-TrustedAhkDoneMarker -Data $data -InstallDir $InstallDir){ return $true }
    Remove-Item -LiteralPath $marker -Force -ErrorAction SilentlyContinue
    Write-Log "STALE_DONE_MARKER_REMOVED setup='$SetupPath' install_dir='$InstallDir' reason='no-credible-main-exe-or-trusted-finish-marker'"
    return $false
  }
  if(-not [string]::IsNullOrWhiteSpace($exe)){
    Write-InstallDoneMarker -SetupPath $SetupPath -InstallDir $InstallDir -Reason 'credible-main-exe-present'
    return $true
  }
  return $false
}
function Test-SetupProcessRunningForSource {
  param([string]$SetupPath)
  $needle=[IO.Path]::GetFullPath($SetupPath)
  foreach($p in Get-RunningSetupCommandLines){
    $ep=[string]$p.ExecutablePath; $cl=[string]$p.CommandLine
    if($ep.Equals($needle,[StringComparison]::OrdinalIgnoreCase) -or $cl.IndexOf($needle,[StringComparison]::OrdinalIgnoreCase) -ge 0){ return $true }
  }
  return $false
}

function Get-SetupProcessTreeIdsForSource {
  param([string]$SetupPath)
  $needle=[IO.Path]::GetFullPath($SetupPath)
  $all=@(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue)
  $ids=@{}
  foreach($p in $all){
    $cl=''+$p.CommandLine; $ep=''+$p.ExecutablePath
    if($ep.Equals($needle,[StringComparison]::OrdinalIgnoreCase) -or $cl.IndexOf($needle,[StringComparison]::OrdinalIgnoreCase) -ge 0){ $ids[[int]$p.ProcessId]=$true }
  }
  $changed=$true
  while($changed){
    $changed=$false
    foreach($p in $all){
      $pidNum=[int]$p.ProcessId; $parentNum=[int]$p.ParentProcessId
      if((-not $ids.ContainsKey($pidNum)) -and $ids.ContainsKey($parentNum)){ $ids[$pidNum]=$true; $changed=$true }
    }
  }
  return @($ids.Keys)
}
function Get-InstallProgressSignature {
  param([string]$SetupPath,[string]$InstallDir)
  $bytes=[int64]0; $count=0; $latest=[int64]0
  if(Test-Path -LiteralPath $InstallDir -PathType Container){
    foreach($f in Get-ChildItem -LiteralPath $InstallDir -Recurse -Force -File -ErrorAction SilentlyContinue){
      $count++; $bytes += [int64]$f.Length
      if($f.LastWriteTimeUtc.Ticks -gt $latest){ $latest=[int64]$f.LastWriteTimeUtc.Ticks }
    }
  }
  $cpu=[double]0
  foreach($id in Get-SetupProcessTreeIdsForSource -SetupPath $SetupPath){
    try { $gp=Get-Process -Id $id -ErrorAction Stop; $cpu += [double]$gp.CPU } catch {}
  }
  return ('files={0};bytes={1};latest={2};cpu={3:N1}' -f $count,$bytes,$latest,$cpu)
}
function Test-RunningInstallStalled {
  param([string]$SetupPath,[string]$InstallDir)
  if($InstallStallMinutes -lt 1){ return $false }
  $stallDir=Join-Path $StateDir 'stall-watch'
  if(-not(Test-Path -LiteralPath $stallDir -PathType Container)){ New-Item -ItemType Directory -Path $stallDir -Force | Out-Null }
  $sha=[Security.Cryptography.SHA256]::Create()
  try { $key=([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes(([IO.Path]::GetFullPath($SetupPath)).ToLowerInvariant())))).Replace('-','').Substring(0,16) } finally { $sha.Dispose() }
  $state=Join-Path $stallDir ($key+'.txt')
  $now=(Get-Date).ToUniversalTime()
  $sig=Get-InstallProgressSignature -SetupPath $SetupPath -InstallDir $InstallDir
  $prevSig=''; $prevTicks=[int64]0
  if(Test-Path -LiteralPath $state -PathType Leaf){
    try {
      $lines=Get-Content -LiteralPath $state -ErrorAction Stop
      if($lines.Count -ge 2){ $prevTicks=[int64]$lines[0]; $prevSig=[string]$lines[1] }
    } catch {}
  }
  if($sig -ne $prevSig -or $prevTicks -le 0){
    Set-Content -LiteralPath $state -Encoding ASCII -Value @([string]$now.Ticks,$sig)
    Write-Log "INSTALL_PROGRESS_ACTIVE setup='$SetupPath' install_dir='$InstallDir' signature='$sig'" | Out-Null
    return $false
  }
  $age=[TimeSpan]::FromTicks($now.Ticks - $prevTicks)
  if($age.TotalMinutes -ge $InstallStallMinutes){
    Write-Log ("INSTALL_STALL_DETECTED setup='{0}' install_dir='{1}' idle_minutes={2:N1} signature='{3}'" -f $SetupPath,$InstallDir,$age.TotalMinutes,$sig) | Out-Null
    Remove-Item -LiteralPath $state -Force -ErrorAction SilentlyContinue
    return $true
  }
  Write-Log ("INSTALL_PROGRESS_UNCHANGED setup='{0}' idle_minutes={1:N1} threshold={2} signature='{3}'" -f $SetupPath,$age.TotalMinutes,$InstallStallMinutes,$sig) | Out-Null
  return $false
}
function Get-RunningTopLevelFitGirlSetupCount {
  $setups=@{}
  $rootPrefix=([IO.Path]::GetFullPath($DownloadRoot)).TrimEnd('\')+'\'
  foreach($p in Get-RunningSetupCommandLines){
    $ep=[string]$p.ExecutablePath
    if([string]::IsNullOrWhiteSpace($ep)){ continue }
    $fullEp=([IO.Path]::GetFullPath($ep))
    if(-not $fullEp.StartsWith($rootPrefix,[StringComparison]::OrdinalIgnoreCase)){ continue }
    if($fullEp -notmatch '\setup\.exe$'){ continue }
    $parent=[IO.Directory]::GetParent($fullEp)
    if($null -eq $parent -or $parent.Name -notmatch 'FitGirl|Repack'){ continue }
    # Finished installers are intentionally left open at the Finish page; once AHK writes the done marker,
    # they must not occupy a queue slot, otherwise the next ready game would never start.
    $doneMarker=Join-Path $parent.FullName '.qbit-force-install-done.txt'
    if(Test-Path -LiteralPath $doneMarker -PathType Leaf){ continue }
    $setups[$fullEp.ToLowerInvariant()]=$true
  }
  return $setups.Count
}

function Stop-SetupProcessesForSource {
  param([string]$SetupPath,[string]$Reason)
  $needle=[IO.Path]::GetFullPath($SetupPath)
  $procs=@(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object {
    $cl=''+$_.CommandLine; $ep=''+$_.ExecutablePath
    ($ep.Equals($needle,[StringComparison]::OrdinalIgnoreCase)) -or ($cl.IndexOf($needle,[StringComparison]::OrdinalIgnoreCase) -ge 0)
  })
  $ids=@{}
  foreach($p in $procs){ $ids[[int]$p.ProcessId]=$true }
  foreach($p in @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object { $ids.ContainsKey([int]$_.ParentProcessId) })) { $ids[[int]$p.ProcessId]=$true }
  foreach($id in @($ids.Keys)){
    try { Stop-Process -Id $id -Force -ErrorAction Stop; Write-Log ("STOP_UNFINISHED_OR_ERROR_SETUP pid={0} setup='{1}' reason='{2}'" -f $id,$SetupPath,$Reason) } catch {}
  }
  return ($ids.Count -gt 0)
}

function Test-SourceHardFailMarker {
  param([string]$SetupPath)
  $setupDir=[IO.Path]::GetDirectoryName($SetupPath)
  $marker=Join-Path $setupDir '.qbit-force-hard-fail.txt'
  if(Test-Path -LiteralPath $marker -PathType Leaf){
    try {
      $reason=(Get-Content -LiteralPath $marker -Raw -ErrorAction Stop).Trim()
      # Inno/ISExec temp-helper start errors such as C:\Temp\is-*\FlushFileCache.exe are retryable
      # scratch/temp launch failures, not permanent source/archive corruption. Clear only that exact class
      # so every qBittorrent-completed source gets another immediate handoff after the per-source TEMP fix.
      if($reason -match 'FlushFileCache\.exe\s+in\s+the\s+module\s+ISExec' -and $reason -match 'C:\\Temp\\is-'){
        Remove-Item -LiteralPath $marker -Force -ErrorAction SilentlyContinue
        Write-Log "STALE_RETRYABLE_TEMP_HELPER_HARDFAIL_REMOVED setup='$SetupPath' reason='$reason'" | Out-Null
        return $null
      }
      # ISDone/Unarc dialogs that include "Unable to write data to disk" are not treated as
      # permanent source corruption in this project. They usually mean target/temp/lock/scratch
      # write failure during extraction; clear the stale marker so the next run recreates a clean
      # target and relaunches instead of skipping a qBittorrent-completed source forever.
      $reasonLower=$reason.ToLowerInvariant()
      if($reasonLower.Contains('unable to write data to disk') -or $reasonLower.Contains('write error') -or $reasonLower.Contains('not enough disk') -or $reasonLower.Contains('disk full')){
        Remove-Item -LiteralPath $marker -Force -ErrorAction SilentlyContinue
        Write-Log "STALE_RETRYABLE_WRITE_TARGET_HARDFAIL_REMOVED setup='$SetupPath' reason='$reason'" | Out-Null
        return $null
      }
      # User-forced retry policy: do not let an ISDone/Unarc/CRC/archive-corruption marker permanently skip a qBittorrent-completed source.
      # Clean target/temp state and relaunch immediately; the AHK watchdog dismisses future dialogs and resets the source instead of persisting a hard-fail marker.
      if(($reasonLower.Contains('isdone') -or $reasonLower.Contains('unarc') -or $reasonLower.Contains('checksum') -or $reasonLower.Contains('crc') -or $reasonLower.Contains('archive') -or $reasonLower.Contains('corrupt') -or $reasonLower.Contains('decompression fails') -or $reasonLower.Contains('failed to unpack') -or $reasonLower.Contains('returned an error code'))){
        Remove-Item -LiteralPath $marker -Force -ErrorAction SilentlyContinue
        Write-Log "USER_FORCED_RETRY_ARCHIVE_HARDFAIL_REMOVED setup='$SetupPath' reason='$reason'" | Out-Null
        return $null
      }
      return $reason
    } catch { return 'hard-fail-marker-present' }
  }
  return $null
}

function Prepare-FitGirlSourceFolder {
  param([string]$SetupPath)
  $setupDir=[IO.Path]::GetDirectoryName($SetupPath)
  try {
    Get-ChildItem -LiteralPath $setupDir -Recurse -Force -File -ErrorAction SilentlyContinue | Where-Object { $_.Extension -match '^(\.exe|\.dll|\.bin)$' -or $_.Name -match '^(cls|srep|oo2|xtool|razor|unarc|isdone)' } | ForEach-Object {
      try { Unblock-File -LiteralPath $_.FullName -ErrorAction SilentlyContinue } catch {}
      try { $_.Attributes = ($_.Attributes -band (-bnot [IO.FileAttributes]::ReadOnly)) } catch {}
    }
    Write-Log "PREPARED_SOURCE_UNBLOCKED setup_dir='$setupDir'"
  } catch { Write-Log ("PREPARE_SOURCE_WARN setup_dir='{0}' error='{1}'" -f $setupDir,$_.Exception.Message) }
}

function Get-FitGirlClickerScriptPath {
  try { return (Join-Path (Split-Path -Parent $PSCommandPath) 'FitGirlAutoClicker.ahk') } catch { return '' }
}

function Test-FitGirlClickerRunning {
  $ahkScript=Get-FitGirlClickerScriptPath
  if([string]::IsNullOrWhiteSpace($ahkScript)){ return $false }
  try {
    $full=[IO.Path]::GetFullPath($ahkScript)
    $matches=@(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object {
      $_.Name -ieq 'AutoHotkey64.exe' -and (''+$_.CommandLine).IndexOf($full,[StringComparison]::OrdinalIgnoreCase) -ge 0
    })
    return ($matches.Count -gt 0)
  } catch { return $false }
}

function Start-FitGirlSetupExact {
  param([string]$SetupPath,[string]$InstallDir)
  if(-not(Test-FitGirlClickerRunning)){ throw "AHK clicker is not running; launch/relaunch is paused" }
  $setupDir=[IO.Path]::GetDirectoryName($SetupPath)
  $hardFail=Test-SourceHardFailMarker -SetupPath $SetupPath
  if(-not [string]::IsNullOrWhiteSpace($hardFail)){ throw "source has prior hard-fail marker: $hardFail" }
  if(-not(Test-Path -LiteralPath $InstallDir)){ New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null }
  Prepare-FitGirlSourceFolder -SetupPath $SetupPath
  $marker=Join-Path $setupDir '.qbit-force-install-target.txt'
  Write-LaunchMarker -Marker $marker -SetupPath $SetupPath -InstallDir $InstallDir -Status 'launched'
  $tempBase=Join-Path $StateDir 'inno-temp'
  if(-not(Test-Path -LiteralPath $tempBase -PathType Container)){ New-Item -ItemType Directory -Path $tempBase -Force | Out-Null }
  $sha=[Security.Cryptography.SHA256]::Create()
  try {
    $hash=([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($setupDir.ToLowerInvariant())))).Replace('-','').Substring(0,16)
  } finally { $sha.Dispose() }
  $perSourceTemp=Join-Path $tempBase $hash
  if(Test-Path -LiteralPath $perSourceTemp -PathType Container){
    try { Get-ChildItem -LiteralPath $perSourceTemp -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue } catch {}
  }
  New-Item -ItemType Directory -Path $perSourceTemp -Force | Out-Null
  $psi=New-Object Diagnostics.ProcessStartInfo
  $psi.FileName=$SetupPath
  $psi.WorkingDirectory=$setupDir
  # Offline-first Inno/FitGirl launch: disable optional tasks/components up front so VC++/DirectX web downloads cannot loop on certificate/TLS failures.
  $psi.Arguments=('/SP- /DIR="{0}" /NORESTART /SUPPRESSMSGBOXES /TASKS="" /MERGETASKS="" /COMPONENTS=""' -f $InstallDir)
  $psi.UseShellExecute=$false
  $psi.EnvironmentVariables['TEMP']=$perSourceTemp
  $psi.EnvironmentVariables['TMP']=$perSourceTemp
  $p=[Diagnostics.Process]::Start($psi)
  Write-Log ("LAUNCHED setup pid={0} setup='{1}' install_dir='{2}' temp_dir='{3}'" -f $p.Id,$SetupPath,$InstallDir,$perSourceTemp)
}
function Invoke-CompletedSweep {
  param([string[]]$Hints=@(),[switch]$ForceRerunDone,[switch]$ExactOnly)
  $sweepMutex = New-Object Threading.Mutex($false,'Global\QbitFitGirlForceAutoInstallSweep')
  if(-not $sweepMutex.WaitOne(0)){ Write-Log 'SKIP sweep-already-running'; return }
  try {
  if(-not(Test-Path -LiteralPath $StateDir)){ New-Item -ItemType Directory -Path $StateDir -Force | Out-Null }
  if(-not(Test-FitGirlClickerRunning)){
    Write-Log "SWEEP_PAUSED_AHK_CLICKER_NOT_RUNNING no target cleanup or setup launch attempted"
    return
  }
  $parallelPolicy='unlimited-qbittorrent-completed-all-ready-no-artificial-slot-cap'
  $launched=0; $skipped=0; $checked=0
  $roots=New-Object Collections.Generic.List[string]
  foreach($h in $Hints){
    if(-not[string]::IsNullOrWhiteSpace($h)){
      $p=$h.Trim('"'); if(Test-Path -LiteralPath $p -PathType Leaf){ $p=[IO.Path]::GetDirectoryName($p) }
      if(Test-Path -LiteralPath $p -PathType Container){ [void]$roots.Add($p) }
    }
  }
  if(( -not $ExactOnly) -and (Test-Path -LiteralPath $DownloadRoot)){
    # Discover every candidate FitGirl/Inno source under F:\Downloads, not just top-level folders.
    # The strict qBittorrent completed_time gate below is still the only launch authority, so this broader scan cannot launch unfinished downloads.
    Get-ChildItem -LiteralPath $DownloadRoot -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -match 'FitGirl|Repack' -or (Test-Path -LiteralPath (Join-Path $_.FullName 'setup.exe')) } | ForEach-Object { [void]$roots.Add($_.FullName) }
    Get-ChildItem -LiteralPath $DownloadRoot -Recurse -Filter 'setup.exe' -File -ErrorAction SilentlyContinue | ForEach-Object {
      $dir=$_.DirectoryName
      if([string]::IsNullOrWhiteSpace($dir)){ return }
      $dirFull=[IO.Path]::GetFullPath($dir)
      # Ignore generated scratch install targets that are already marked done; source folders own .bin payloads and qBittorrent fastresume proof.
      [void]$roots.Add($dirFull)
    }
  }
  $seen=@{}
  foreach($root in $roots){
    $item=Get-Item -LiteralPath $root -ErrorAction SilentlyContinue; if(-not$item){ continue }
    $full=$item.FullName; if([string]::IsNullOrWhiteSpace($full) -or $seen.ContainsKey($full.ToLowerInvariant())){ continue }
    $seen[$full.ToLowerInvariant()]=$true; $checked++
    $setup=Join-Path $full 'setup.exe'
    $qbtComplete=$null
    try { $qbtComplete=Test-QbitFastresumeCompleteForFolder -FolderName ([IO.Path]::GetFileName($full)) } catch { $qbtComplete=$null }
    # Explicit qBittorrent incomplete proof is authoritative even if a setup is already running.
    # This prevents a stale hook/manual launch from continuing an unfinished torrent.
    if((Test-Path -LiteralPath $setup -PathType Leaf) -and $qbtComplete -eq $false -and (Test-SetupProcessRunningForSource -SetupPath $setup)){
      $incompleteInstallDir=Join-Path $DownloadRoot (ConvertTo-GameName $full)
      $setupRootIncomplete=[IO.Path]::GetFullPath($full).TrimEnd('\')
      $targetRootIncomplete=[IO.Path]::GetFullPath($incompleteInstallDir).TrimEnd('\')
      if($targetRootIncomplete -ieq $setupRootIncomplete){ $incompleteInstallDir=Join-Path $DownloadRoot ((ConvertTo-GameName $full) + ' Installed') }
      Stop-SetupProcessesForSource -SetupPath $setup -Reason 'qbit-explicitly-incomplete-running' | Out-Null
      Remove-Item -LiteralPath (Join-Path $full '.qbit-force-install-target.txt') -Force -ErrorAction SilentlyContinue
      Remove-Item -LiteralPath (Join-Path $full '.qbit-force-install-done.txt') -Force -ErrorAction SilentlyContinue
      if((Test-Path -LiteralPath $incompleteInstallDir -PathType Container) -and ([IO.Path]::GetFullPath($incompleteInstallDir).TrimEnd('\') -ne $setupRootIncomplete)){
        try { Remove-Item -LiteralPath $incompleteInstallDir -Recurse -Force -ErrorAction Stop; Write-Log "DELETE_INCOMPLETE_QBIT_TARGET target='$incompleteInstallDir' setup='$setup'" } catch { Write-Log ("INCOMPLETE_QBIT_TARGET_DELETE_WARN target='{0}' error='{1}'" -f $incompleteInstallDir,$_.Exception.Message) }
      }
      $skipped++; Write-Log "KILL qbit-explicitly-incomplete-running setup='$setup' install_dir='$incompleteInstallDir' qbit_state=$qbtComplete"; continue
    }
    # If this exact setup is already running, never re-evaluate readiness unless qBittorrent explicitly proves it is incomplete.
    if((Test-Path -LiteralPath $setup -PathType Leaf) -and (Test-SetupProcessRunningForSource -SetupPath $setup)){
      $runningInstallDir=Join-Path $DownloadRoot (ConvertTo-GameName $full)
      $setupRootEarly=[IO.Path]::GetFullPath($full).TrimEnd('\')
      $targetRootEarly=[IO.Path]::GetFullPath($runningInstallDir).TrimEnd('\')
      if($targetRootEarly -ieq $setupRootEarly){ $runningInstallDir=Join-Path $DownloadRoot ((ConvertTo-GameName $full) + ' Installed') }
      if(Test-RunningInstallStalled -SetupPath $setup -InstallDir $runningInstallDir){
        Stop-SetupProcessesForSource -SetupPath $setup -Reason 'install-progress-stalled' | Out-Null
        Remove-Item -LiteralPath (Join-Path $full '.qbit-force-install-target.txt') -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath (Join-Path $full '.qbit-force-install-done.txt') -Force -ErrorAction SilentlyContinue
        if((Test-Path -LiteralPath $runningInstallDir -PathType Container) -and ([IO.Path]::GetFullPath($runningInstallDir).TrimEnd('\') -ne $setupRootEarly)){
          try { Remove-Item -LiteralPath $runningInstallDir -Recurse -Force -ErrorAction Stop; Write-Log "DELETE_STALLED_INSTALL_TARGET target='$runningInstallDir' setup='$setup'" } catch { Write-Log ("STALL_TARGET_DELETE_WARN target='{0}' error='{1}'" -f $runningInstallDir,$_.Exception.Message) }
        }
        $skipped++; Write-Log "STALL_RESET_DONE_WAIT_NEXT_SWEEP setup='$setup' install_dir='$runningInstallDir'"; continue
      }
      $skipped++; Write-Log "WAIT exact-source-setup-running setup='$setup'"; continue
    }
    if(-not(Test-SetupFolderComplete -Folder $full)){
      # Do not auto-launch unfinished folders, but also do not kill unrelated/running setups here; exact running setup was handled above.
      $skipped++; Write-Log "SKIP not-complete-or-not-fitgirl '$full'"; continue
    }
    if($null -eq $qbtComplete){ $qbtComplete=Test-QbitFastresumeCompleteForFolder -FolderName ([IO.Path]::GetFileName($full)) }
    $hookHintComplete=Test-HintMatchesFolder -Folder $full -Hints $Hints -TorrentName $TorrentName
    # Explicit qBittorrent incomplete proof is authoritative. Hook hints may bridge only unknown/null
    # fastresume state, never a known incomplete torrent.
    if($qbtComplete -eq $false){
      $skipped++; Write-Log "SKIP qbit-explicitly-incomplete '$full' qbit_state=$qbtComplete hook_hint=$hookHintComplete"; continue
    }
    # Immediate completion hook gate: qBittorrent/aria2 external hooks fire after that item reaches 100%.
    # Accept the exact hinted source immediately only when qBittorrent proof is unavailable/null.
    # Non-hinted/background sweep items still require completed_time > 0 or the conservative fallback below.
    if($qbtComplete -ne $true -and $hookHintComplete){
      if(Test-ExternalDownloaderIncompleteForFolder -Folder $full){
        $skipped++; Write-Log "WAIT hook-hint-but-external-downloader-incomplete '$full' qbit_state=$qbtComplete hook_hint=$hookHintComplete"; continue
      }
      $qbtComplete=$true
      Write-Log "HOOK_HINT_COMPLETION_ACCEPTED folder='$full' torrent='$TorrentName' external_incomplete=False" | Out-Null
    }
    # Completion gate: explicit incomplete qBittorrent proof is authoritative and skipped.
    # If qBittorrent proof is unavailable/null (missed fastresume match, stale BT_backup, or freshly completed folder before flush),
    # use a conservative two-scan filesystem-complete fallback so already-ready downloads are not permanently skipped.
    if($qbtComplete -ne $true){
      if($ForceRerunDone){
        if(Test-ExternalDownloaderIncompleteForFolder -Folder $full){
          $skipped++; Write-Log "WAIT force-rerun-refused-external-downloader-incomplete '$full' qbit_state=$qbtComplete hook_hint=$hookHintComplete"; continue
        }
        $qbtComplete=$true
        Write-Log "USER_RUN_FILESYSTEM_COMPLETION_ACCEPTED folder='$full' qbit_state=null hook_hint=$hookHintComplete force_rerun_done=True"
      } elseif($hookHintComplete -and -not (Test-ExternalDownloaderIncompleteForFolder -Folder $full) -and (Test-FilesystemStableReady -Folder $full)){
        $qbtComplete=$true
        Write-Log "HOOK_FILESYSTEM_STABLE_COMPLETION_ACCEPTED folder='$full' qbit_state=null hook_hint=$hookHintComplete external_incomplete=False"
      } else {
        $skipped++; Write-Log "WAIT filesystem-stability-confirmation '$full' qbit_state=$qbtComplete hook_hint=$hookHintComplete"; continue
      }
    }
    $launchMarker=Join-Path $full '.qbit-force-install-target.txt'; $game=ConvertTo-GameName $full; $installDir=Join-Path $DownloadRoot $game
    # Scratch install policy for not-yet-installed targets only: fully installed targets are skipped before this point.
    # This only touches the clean target F:\Downloads\<game name>; it refuses to delete the repack source folder containing setup.exe.
    $setupRoot=[IO.Path]::GetFullPath($full).TrimEnd('\\')
    $targetRoot=[IO.Path]::GetFullPath($installDir).TrimEnd('\\')
    if($targetRoot -ieq $setupRoot){ $installDir=Join-Path $DownloadRoot ($game + ' Installed'); $targetRoot=[IO.Path]::GetFullPath($installDir).TrimEnd('\\') }
    $hardFail=Test-SourceHardFailMarker -SetupPath $setup
    if(-not [string]::IsNullOrWhiteSpace($hardFail)){ $skipped++; Write-Log "SKIP source-hard-fail-marker setup='$setup' reason='$hardFail'"; continue }
    if(Test-InstallDoneMarker -SetupPath $setup -InstallDir $installDir){
      # User-required policy: never reinstall/delete a target that is already fully installed in that folder,
      # even when the canonical manual command uses -RunOnceAfterInstall. The manual run should open only
      # ready/not-installed sources and leave fully installed folders alone.
      $skipped++; Write-Log "SKIP already-successfully-installed-never-rerun setup='$setup' install_dir='$installDir' force_rerun_done=$ForceRerunDone"; continue
    }
    # Permanent no-popup preflight: verify FitGirl source MD5 before setup can ever display an ISDone/CRC dialog.
    if(-not(Test-FitGirlMd5Preflight -SetupPath $setup)){ $skipped++; Write-Log "SKIP source-md5-preflight-failed setup='$setup'"; continue }
    # Do not infer failure merely because a previous setup process is no longer running; some installers exit/restart/stage silently.
    # Only explicit AHK-detected helper/Unarc/ISDone failures write hard-fail markers.
    if(Test-SetupProcessRunningForSource -SetupPath $setup){ $skipped++; Write-Log "WAIT exact-source-setup-running setup='$setup'"; continue }
    # No artificial launch-slot cap: every qBittorrent-completed, deduped setup is launched in this sweep.
    $setupRootPrefix=$setupRoot.TrimEnd('\\')+'\\'
    $sourceBusy=@(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object { $cl=''+$_.CommandLine; $ep=''+$_.ExecutablePath; $cl.IndexOf($setup,[StringComparison]::OrdinalIgnoreCase) -ge 0 -or $ep.StartsWith($setupRootPrefix,[StringComparison]::OrdinalIgnoreCase) })
    if($sourceBusy.Count -gt 0){ $skipped++; Write-Log "WAIT source-installer-active-not-deleting setup='$setup' pids='$($sourceBusy.ProcessId -join ',')'"; continue }
    if($qbtComplete -ne $true -and (Test-FileLocked -Path $setup)){ $skipped++; Write-Log "WAIT setup-locked-and-not-qbit-complete setup='$setup'"; continue }
    if(Test-Path -LiteralPath $installDir -PathType Container){
      try {
        $targetPrefix=$targetRoot.TrimEnd('\\')+'\\'; $procs=@(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object { $ep=''+$_.ExecutablePath; ($ep -ieq $targetRoot) -or $ep.StartsWith($targetPrefix,[StringComparison]::OrdinalIgnoreCase) })
        foreach($proc in $procs){ try { Stop-Process -Id $proc.ProcessId -Force -ErrorAction SilentlyContinue; Write-Log ("STOP target-process-before-scratch-install pid={0} exe='{1}'" -f $proc.ProcessId,$proc.ExecutablePath) } catch {} }
        Remove-Item -LiteralPath $installDir -Recurse -Force -ErrorAction Stop
        Write-Log "DELETE_EXISTING_INSTALL_TARGET target='$installDir' source='$full'"
      } catch {
        $skipped++; Write-Log ("SKIP cannot-delete-existing-install-target target='{0}' error='{1}'" -f $installDir,$_.Exception.Message); continue
      }
    }
    if(-not(Test-InstallTargetPreflight -InstallDir $installDir -SetupPath $setup)){ $skipped++; Write-Log "SKIP install-target-preflight-blocked setup='$setup' install_dir='$installDir'"; continue }
    New-Item -ItemType Directory -Path $installDir -Force | Out-Null
    if(Test-Path -LiteralPath $launchMarker -PathType Leaf){
      Remove-Item -LiteralPath $launchMarker -Force -ErrorAction SilentlyContinue
      Write-Log "RETRY not-installed-yet-removing-marker marker='$launchMarker' target='$installDir'"
    }
    $launchOk = $false
    $lastLaunchError = $null
    for($launchAttempt=1; $launchAttempt -le 12 -and -not $launchOk; $launchAttempt++){
      try {
        Start-FitGirlSetupExact -SetupPath $setup -InstallDir $installDir
        $launchOk = $true
        $launched++
      } catch {
        $lastLaunchError = $_.Exception.Message
        if($lastLaunchError -notmatch 'being used by another process|access.*denied|cannot access the file'){
          break
        }
        Write-Log ("RETRY launch-transient-lock attempt={0} setup='{1}' install_dir='{2}' error='{3}'" -f $launchAttempt,$setup,$installDir,$lastLaunchError)
        Start-Sleep -Milliseconds ([Math]::Min(2000, 150 * $launchAttempt))
      }
    }
    if(-not $launchOk){ $skipped++; Write-Log ("SKIP launch-failed setup='{0}' install_dir='{1}' error='{2}' attempts=12" -f $setup,$installDir,$lastLaunchError) }
  }
  Write-Log ("SWEEP policy={0} checked={1} launched={2} skipped={3}" -f $parallelPolicy,$checked,$launched,$skipped)
  } finally {
    try { [void]$sweepMutex.ReleaseMutex() } catch {}
    try { $sweepMutex.Dispose() } catch {}
  }
}
function Get-QbitApiSession {
  $base='http://127.0.0.1:8080'
  $existing=Get-Variable -Name QbitApiSession -Scope Script -ErrorAction SilentlyContinue
  if($existing -and $existing.Value){ return [pscustomobject]@{Base=$base;Session=$existing.Value} }
  $session=New-Object Microsoft.PowerShell.Commands.WebRequestSession
  $passwords=New-Object Collections.Generic.List[string]
  if($env:QBT_PASSWORD){ [void]$passwords.Add($env:QBT_PASSWORD) }
  if(-not $passwords.Contains('adminadmin')){ [void]$passwords.Add('adminadmin') }
  foreach($pass in $passwords){
    try {
      $login=Invoke-WebRequest -UseBasicParsing -Uri "$base/api/v2/auth/login" -Method Post -Body @{username='admin';password=$pass} -WebSession $session -TimeoutSec 2
      if((''+$login.Content) -match 'Ok\.'){ $script:QbitApiSession=$session; return [pscustomobject]@{Base=$base;Session=$session} }
    } catch {}
  }
  return $null
}
function Invoke-QbitApiCompletionSweep {
  $api=Get-QbitApiSession
  if(-not $api){ Write-Log "QBIT_API_COMPLETION_WARN reason='session-unavailable'"; return $false }
  try {
    $response=Invoke-WebRequest -UseBasicParsing -Uri "$($api.Base)/api/v2/torrents/info" -WebSession $api.Session -TimeoutSec 2
    $torrents=$response.Content | ConvertFrom-Json
  } catch {
    $script:QbitApiSession=$null
    Write-Log ("QBIT_API_COMPLETION_WARN reason='query-failed' error='{0}'" -f $_.Exception.Message)
    return $false
  }
  $now=[DateTimeOffset]::Now.ToUnixTimeSeconds()
  $seenVar=Get-Variable -Name QbitApiCompletionStableSeen -Scope Script -ErrorAction SilentlyContinue
  if(-not $seenVar -or -not $seenVar.Value){ $script:QbitApiCompletionStableSeen=@{} }
  foreach($t in @($torrents)){
    $name=''+$t.name
    $content=''+$t.content_path
    if([string]::IsNullOrWhiteSpace($content)){ continue }
    if($name -notmatch 'FitGirl' -and $content -notmatch 'FitGirl|Repack'){ continue }
    $complete=($t.progress -ge 1 -and [int64]$t.amount_left -eq 0 -and [int64]$t.completion_on -gt 0)
    if(-not $complete){ continue }
    if(-not (Test-Path -LiteralPath $content -PathType Container)){ continue }
    $setup=Join-Path $content 'setup.exe'
    if(-not (Test-Path -LiteralPath $setup -PathType Leaf)){ continue }
    $game=ConvertTo-GameName $content
    $installDir=Join-Path $DownloadRoot $game
    $setupRoot=[IO.Path]::GetFullPath($content).TrimEnd('\')
    $targetRoot=[IO.Path]::GetFullPath($installDir).TrimEnd('\')
    if($targetRoot -ieq $setupRoot){ $installDir=Join-Path $DownloadRoot ($game + ' Installed') }
    $seenKey=("{0}|{1}" -f $content,[int64]$t.completion_on).ToLowerInvariant()
    if(Test-SetupProcessRunningForSource -SetupPath $setup){
      if(-not $script:QbitApiCompletionStableSeen.ContainsKey($seenKey)){
        $script:QbitApiCompletionStableSeen[$seenKey]='running'
        Write-Log ("QBIT_API_COMPLETED_ALREADY_RUNNING name='{0}' content='{1}' completion_on={2}" -f $name,$content,[int64]$t.completion_on)
      }
      continue
    }
    if(Test-InstallDoneMarker -SetupPath $setup -InstallDir $installDir){
      if(-not $script:QbitApiCompletionStableSeen.ContainsKey($seenKey)){
        $script:QbitApiCompletionStableSeen[$seenKey]='done'
        Write-Log ("QBIT_API_COMPLETED_ALREADY_INSTALLED name='{0}' content='{1}' completion_on={2} install_dir='{3}'" -f $name,$content,[int64]$t.completion_on,$installDir)
      }
      continue
    }
    if($script:QbitApiCompletionStableSeen.ContainsKey($seenKey)){ [void]$script:QbitApiCompletionStableSeen.Remove($seenKey) }
    $lag=$now-[int64]$t.completion_on
    Write-Log ("QBIT_API_COMPLETED_TARGET name='{0}' content='{1}' completion_on={2} lag_seconds={3}" -f $name,$content,[int64]$t.completion_on,$lag)
    Invoke-CompletedSweep -Hints @($content) -ExactOnly
  }
  return $true
}
function New-CommandWrappers {
  $scriptDir=[IO.Path]::GetDirectoryName($PSCommandPath)
  $projectRoot=[IO.DirectoryInfo]$scriptDir
  if($projectRoot.Parent){ $projectRoot=$projectRoot.Parent }
  $wrapDir=Join-Path $projectRoot.FullName 'runtime\qbit-fitgirl-auto-install'
  if(-not(Test-Path -LiteralPath $wrapDir)){ New-Item -ItemType Directory -Path $wrapDir -Force | Out-Null }
  $watcher=Join-Path $wrapDir 'watcher.cmd'; $hook=Join-Path $wrapDir 'qbit-hook.cmd'; $hookLauncher=Join-Path $wrapDir 'qbit-hook-launcher.vbs'; $clicker=Join-Path $wrapDir 'clicker.cmd'; $rescue=Join-Path $wrapDir 'popup-rescue.cmd'; $zeroGuardian=Join-Path $wrapDir 'zero-download-guardian.cmd'; $ahkScript=Join-Path $scriptDir 'FitGirlAutoClicker.ahk'; $popupRescueScript=Join-Path $scriptDir 'FitGirlInnoPopupRescue.ps1'; $zeroGuardianScript=Join-Path $scriptDir 'FitLauncherZeroDownloadGuardian.ps1'; $nl=[Environment]::NewLine
  Set-Content -LiteralPath $watcher -Encoding ASCII -Value (@('@echo off',('start "" /B powershell.exe -NoProfile -ExecutionPolicy Bypass -File "{0}" -Daemon -PollMilliseconds 250' -f $PSCommandPath),'exit /b 0') -join $nl)
  $vbs = @(
    'Option Explicit',
    'Dim torrentName, torrentRootPath, contentPath',
    'torrentName = ""',
    'torrentRootPath = ""',
    'contentPath = ""',
    'If WScript.Arguments.Count > 0 Then torrentName = WScript.Arguments(0)',
    'If WScript.Arguments.Count > 1 Then torrentRootPath = WScript.Arguments(1)',
    'If WScript.Arguments.Count > 2 Then contentPath = WScript.Arguments(2)',
    'Dim ps, forceScript, command, shell',
    'ps = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"',
    ('forceScript = "{0}"' -f ($PSCommandPath -replace '"','""')),
    'command = Quote(ps) & " -WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File " & Quote(forceScript) & " -Once"',
    'If Len(torrentName) > 0 Then command = command & " -TorrentName " & Quote(torrentName)',
    'If Len(torrentRootPath) > 0 Then command = command & " -TorrentRootPath " & Quote(torrentRootPath)',
    'If Len(contentPath) > 0 Then command = command & " -ContentPath " & Quote(contentPath)',
    'Set shell = CreateObject("WScript.Shell")',
    'shell.Run command, 0, False',
    'Function Quote(value)',
    '  Quote = Chr(34) & Replace(value, Chr(34), Chr(34) & Chr(34)) & Chr(34)',
    'End Function'
  ) -join $nl
  Set-Content -LiteralPath $hookLauncher -Encoding ASCII -Value $vbs
  Set-Content -LiteralPath $hook -Encoding ASCII -Value (@('@@echo off'.Replace('@@','@'),('wscript.exe //B "%~dp0{0}" "%~1" "%~2" "%~3" >NUL 2>NUL' -f ([IO.Path]::GetFileName($hookLauncher))),'exit /b 0') -join $nl)
  Set-Content -LiteralPath $clicker -Encoding ASCII -Value (("@echo off"+$nl+"`"C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe`" `"{0}`"") -f $ahkScript)
  Set-Content -LiteralPath $rescue -Encoding ASCII -Value (("@echo off"+$nl+"powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"{0}`"") -f $popupRescueScript)
  Set-Content -LiteralPath $zeroGuardian -Encoding ASCII -Value (("@echo off"+$nl+"powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"{0}`"") -f $zeroGuardianScript)
  [pscustomobject]@{Dir=$wrapDir;Watcher=$watcher;Hook=$hook;HookLauncher=$hookLauncher;Clicker=$clicker;Rescue=$rescue;ZeroGuardian=$zeroGuardian;AhkScript=$ahkScript;PopupRescueScript=$popupRescueScript;ZeroGuardianScript=$zeroGuardianScript}
}
function Set-QbitLiveCompletionHook {
  param([string]$Command)
  $base='http://127.0.0.1:8080'
  $session=New-Object Microsoft.PowerShell.Commands.WebRequestSession
  $passwords=New-Object Collections.Generic.List[string]
  if($env:QBT_PASSWORD){ [void]$passwords.Add($env:QBT_PASSWORD) }
  if(-not $passwords.Contains('adminadmin')){ [void]$passwords.Add('adminadmin') }
  $loggedIn=$false
  foreach($pass in $passwords){
    try {
      $login=Invoke-WebRequest -UseBasicParsing -Uri "$base/api/v2/auth/login" -Method Post -Body @{username='admin';password=$pass} -WebSession $session -TimeoutSec 5
      if((''+$login.Content) -match 'Ok\.'){ $loggedIn=$true; break }
    } catch {}
  }
  if(-not $loggedIn){ Write-Log "QBIT_LIVE_AUTORUN_WARN reason='login-failed' base=$base"; return $false }
  $prefs=[ordered]@{autorun_enabled=$true;autorun_program=$Command}
  try {
    Invoke-WebRequest -UseBasicParsing -Uri "$base/api/v2/app/setPreferences" -Method Post -Body @{json=($prefs|ConvertTo-Json -Compress)} -WebSession $session -TimeoutSec 5 | Out-Null
    $verify=Invoke-WebRequest -UseBasicParsing -Uri "$base/api/v2/app/preferences" -WebSession $session -TimeoutSec 5
    $parsed=$verify.Content | ConvertFrom-Json
    if($parsed.autorun_enabled -eq $true -and (''+$parsed.autorun_program) -eq $Command){
      Write-Log "QBIT_LIVE_AUTORUN_CONFIGURED base=$base command=$Command"
      return $true
    }
    Write-Log ("QBIT_LIVE_AUTORUN_WARN reason='verify-mismatch' enabled='{0}' command='{1}' expected='{2}'" -f $parsed.autorun_enabled,$parsed.autorun_program,$Command)
  } catch {
    Write-Log ("QBIT_LIVE_AUTORUN_WARN reason='api-error' error='{0}'" -f $_.Exception.Message)
  }
  return $false
}
function Update-QbitCompletionHook {
  if(-not(Test-Path -LiteralPath $QbitConfig)){ Write-Log "qBittorrent config not found: $QbitConfig"; return }
  $wrappers=New-CommandWrappers; $hookForQbit=($wrappers.Hook -replace '\\','/'); $hookForApi=$wrappers.Hook; $cmd='"'+$hookForQbit+'" "%N" "%R" "%F"'; $apiCmd='"'+$hookForApi+'" "%N" "%R" "%F"'; $stamp=Get-Date -Format 'yyyyMMdd-HHmmss'; $bak="$QbitConfig.qbit-force-auto-install-$stamp.bak"
  [void](Set-QbitLiveCompletionHook -Command $apiCmd)
  Copy-Item -LiteralPath $QbitConfig -Destination $bak -Force
  $lines=[Collections.Generic.List[string]](Get-Content -LiteralPath $QbitConfig -Encoding UTF8)
  $autoRunIniProgram=($apiCmd -replace '\\','\\' -replace '"','\"')
  $map=@{'Downloads\RunExternalProgram'='true';'Downloads\RunExternalProgramCommand'=$cmd}
  foreach($key in @($map.Keys)){
    $escaped=[regex]::Escape($key); $found=$false
    for($i=0; $i -lt $lines.Count; $i++){ if($lines[$i] -match "^$escaped="){ $lines[$i]="$key=$($map[$key])"; $found=$true; break } }
    if(-not$found){ $lines.Add("$key=$($map[$key])") }
  }
  $autoRunIndex=-1
  for($i=0; $i -lt $lines.Count; $i++){ if($lines[$i] -match '^\[AutoRun\]$'){ $autoRunIndex=$i; break } }
  if($autoRunIndex -lt 0){ $lines.Add('[AutoRun]'); $lines.Add("program=$autoRunIniProgram") }
  else {
    $insertAt=$autoRunIndex+1; $foundProgram=$false
    for($i=$autoRunIndex+1; $i -lt $lines.Count; $i++){
      if($lines[$i] -match '^\['){ $insertAt=$i; break }
      if($lines[$i] -match '^program='){ $lines[$i]="program=$autoRunIniProgram"; $foundProgram=$true; break }
    }
    if(-not $foundProgram){ $lines.Insert($insertAt,"program=$autoRunIniProgram") }
  }
  Set-Content -LiteralPath $QbitConfig -Value $lines -Encoding UTF8
  Write-Log "qBittorrent completion hook configured; backup=$bak; command=$cmd"
}
function Stop-ExistingAutomationHelpers {
  param([pscustomobject]$Wrappers)
  $self=[int]$PID
  try {
    $scriptPath=[IO.Path]::GetFullPath($PSCommandPath)
    $ahkPath=[IO.Path]::GetFullPath($Wrappers.AhkScript)
    $rescuePath=[IO.Path]::GetFullPath($Wrappers.PopupRescueScript)
    $zeroGuardianPath=[IO.Path]::GetFullPath($Wrappers.ZeroGuardianScript)
    $targets=@(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object {
      $pidNum=[int]$_.ProcessId
      if($pidNum -eq $self){ return $false }
      $cl=''+$_.CommandLine
      $name=''+$_.Name
      (($name -ieq 'powershell.exe' -and $cl.IndexOf($scriptPath,[StringComparison]::OrdinalIgnoreCase) -ge 0 -and $cl.IndexOf(' -Daemon',[StringComparison]::OrdinalIgnoreCase) -ge 0) -or
       ($name -ieq 'powershell.exe' -and $cl.IndexOf($rescuePath,[StringComparison]::OrdinalIgnoreCase) -ge 0) -or
       ($name -ieq 'powershell.exe' -and $cl.IndexOf($zeroGuardianPath,[StringComparison]::OrdinalIgnoreCase) -ge 0) -or
       ($name -ieq 'AutoHotkey64.exe' -and $cl.IndexOf($ahkPath,[StringComparison]::OrdinalIgnoreCase) -ge 0))
    })
    foreach($p in $targets){
      try { Stop-Process -Id $p.ProcessId -Force -ErrorAction Stop; Write-Log ("STOP_OLD_AUTOMATION_HELPER pid={0} name='{1}'" -f $p.ProcessId,$p.Name) | Out-Null } catch {}
    }
  } catch { Write-Log ("STOP_OLD_AUTOMATION_HELPER_WARN error='{0}'" -f $_.Exception.Message) | Out-Null }
}
function Enable-ScheduledTaskVerified {
  param([string]$TaskName)
  $lastState=''
  for($attempt=1; $attempt -le 3; $attempt++){
    & schtasks.exe /Change /TN $TaskName /ENABLE | Out-Null
    Start-Sleep -Milliseconds (250 * $attempt)
    $query=& schtasks.exe /Query /TN $TaskName /FO LIST /V 2>$null
    $lastState=($query | Where-Object { $_ -match '^Scheduled Task State:' } | Select-Object -First 1)
    if($lastState -match 'Enabled'){
      Write-Log ("TASK_ENABLE_VERIFIED task='{0}' state='{1}'" -f $TaskName,$lastState.Trim()) | Out-Null
      return $true
    }
  }
  Write-Log ("TASK_ENABLE_FAILED task='{0}' last_state='{1}'" -f $TaskName,$lastState)
  return $false
}
function Register-StartupRunKeys {
  param([pscustomobject]$Wrappers)
  $runKey='HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
  if(-not(Test-Path -LiteralPath $runKey)){ New-Item -Path $runKey -Force | Out-Null }
  $entries=@(
    @{ Name='FitGirlAutoInstallWatcher'; Path=$Wrappers.Watcher },
    @{ Name='FitGirlInstallerDialogWatchdog'; Path=$Wrappers.Clicker },
    @{ Name='FitGirlInnoMissingSourcePopupRescue'; Path=$Wrappers.Rescue },
    @{ Name='FitLauncherZeroDownloadGuardian'; Path=$Wrappers.ZeroGuardian }
  )
  foreach($entry in $entries){
    if(Test-Path -LiteralPath $entry.Path -PathType Leaf){
      $command='"{0}"' -f $entry.Path
      Set-ItemProperty -LiteralPath $runKey -Name $entry.Name -Value $command -Type String
      Write-Log ("STARTUP_RUN_KEY_SET name='{0}' command='{1}'" -f $entry.Name,$command) | Out-Null
    }
  }
}
function Register-Tasks {
  $wrappers=New-CommandWrappers
  Stop-ExistingAutomationHelpers -Wrappers $wrappers
  Register-StartupRunKeys -Wrappers $wrappers
  $taskName='qBittorrent FitGirl Force AutoInstall Watcher'
  & schtasks.exe /Create /TN $taskName /SC ONLOGON /RL HIGHEST /IT /F /TR ('"'+$wrappers.Watcher+'"') | Out-Null
  [void](Enable-ScheduledTaskVerified -TaskName $taskName)
  $ahk='C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe'
  if((Test-Path -LiteralPath $ahk -PathType Leaf) -and (Test-Path -LiteralPath $wrappers.AhkScript -PathType Leaf)){
    $clickTask='qBittorrent FitGirl Installer Dialog Watchdog'
    & schtasks.exe /Create /TN $clickTask /SC ONLOGON /RL HIGHEST /IT /F /TR ('"'+$wrappers.Clicker+'"') | Out-Null
    [void](Enable-ScheduledTaskVerified -TaskName $clickTask)
    Start-Sleep -Milliseconds 500
    $already=@(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq 'AutoHotkey64.exe' -and (''+$_.CommandLine).IndexOf($wrappers.AhkScript,[StringComparison]::OrdinalIgnoreCase) -ge 0 })
    if($already.Count -eq 0){ try { Start-Process -FilePath $ahk -ArgumentList ('"'+$wrappers.AhkScript+'"') -WindowStyle Hidden | Out-Null } catch {} }
    Write-Log "Installer dialog AutoHotkey task enabled; foreground run starts a bounded clicker only when needed: $clickTask wrapper=$($wrappers.Clicker)"
  }
  $daemon=$null
  if(Test-FitGirlClickerRunning){
    try {
      $daemon=Start-Process -FilePath 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe' -ArgumentList @('-WindowStyle','Hidden','-NoProfile','-ExecutionPolicy','Bypass','-File',$PSCommandPath,'-Daemon','-PollMilliseconds','250') -WindowStyle Hidden -PassThru
    } catch {
      Write-Log ("WATCHER_FORCE_START_WARN task='{0}' error='{1}'" -f $taskName,$_.Exception.Message)
    }
  } else {
    Write-Log "WATCHER_FORCE_START_BLOCKED_AHK_CLICKER_NOT_RUNNING wrapper=$($wrappers.Watcher)"
  }
  if($daemon){ Write-Log ("Scheduled task enabled and watcher force-started: {0} wrapper={1} pid={2} poll=250ms immediate-hook=enabled parallel=unlimited-all-qbittorrent-completed ahk_required=True" -f $taskName,$wrappers.Watcher,$daemon.Id) }
  else { Write-Log "Scheduled task enabled but watcher force-start failed or blocked: $taskName wrapper=$($wrappers.Watcher) poll=250ms immediate-hook=enabled parallel=unlimited-all-qbittorrent-completed ahk_required=True" }
  if(Test-Path -LiteralPath $wrappers.PopupRescueScript -PathType Leaf){
    $rescueTask='qBittorrent FitGirl Inno Missing Source Popup Rescue'
    & schtasks.exe /Create /TN $rescueTask /SC ONLOGON /RL HIGHEST /IT /F /TR ('"'+$wrappers.Rescue+'"') | Out-Null
    [void](Enable-ScheduledTaskVerified -TaskName $rescueTask)
    Write-Log "Installer Inno missing-source PowerShell rescue task enabled but not force-started: $rescueTask wrapper=$($wrappers.Rescue)"
  }
  if(Test-Path -LiteralPath $wrappers.ZeroGuardianScript -PathType Leaf){
    $zeroTask='FitLauncher Zero Download Guardian'
    & schtasks.exe /Create /TN $zeroTask /SC ONLOGON /RL HIGHEST /IT /F /TR ('"'+$wrappers.ZeroGuardian+'"') | Out-Null
    [void](Enable-ScheduledTaskVerified -TaskName $zeroTask)
    Write-Log "FitLauncher zero-download guardian task enabled but not force-started: $zeroTask wrapper=$($wrappers.ZeroGuardian)"
  }
}
if($Install){ Write-Log 'INSTALL starting'; Update-QbitCompletionHook; Register-Tasks; if($RunOnceAfterInstall){ Invoke-CompletedSweep -Hints @($TorrentRootPath,$ContentPath,$TorrentPath) -ForceRerunDone }; Write-Log 'INSTALL finished'; return }
if($Daemon){
  if($PollMilliseconds -lt 50){ $PollMilliseconds=50 }
  $fullSweepIntervalSeconds=30
  $lastFullSweep=[DateTime]::MinValue
  Write-Log "DAEMON started poll=${PollMilliseconds}ms download_root=$DownloadRoot api_completion_first=True full_sweep_interval_seconds=$fullSweepIntervalSeconds"
  while($true){
    try{
      if(-not(Test-FitGirlClickerRunning)){
        Write-Log "DAEMON_STOP_AHK_CLICKER_CLOSED no further launch/relaunch attempts will run"
        return
      }
      [void](Invoke-QbitApiCompletionSweep)
      if(((Get-Date)-$lastFullSweep).TotalSeconds -ge $fullSweepIntervalSeconds){
        Invoke-CompletedSweep -Hints @($TorrentRootPath,$ContentPath,$TorrentPath)
        $lastFullSweep=Get-Date
      }
    } catch { Write-Log ('ERROR '+$_.Exception.Message) }
    Start-Sleep -Milliseconds $PollMilliseconds
  }
}
Invoke-CompletedSweep -Hints @($TorrentRootPath,$ContentPath,$TorrentPath)
