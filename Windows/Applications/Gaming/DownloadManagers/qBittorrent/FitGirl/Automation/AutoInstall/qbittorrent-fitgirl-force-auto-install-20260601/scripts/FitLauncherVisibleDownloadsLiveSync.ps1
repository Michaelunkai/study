$ErrorActionPreference='Continue'
$manager = Join-Path $env:APPDATA 'com.fitlauncher.carrotrub\manager.json'
$log = Join-Path $env:APPDATA 'com.fitlauncher.carrotrub\logs\visible-downloads-live-sync.log'
New-Item -ItemType Directory -Path (Split-Path -Parent $manager) -Force | Out-Null
New-Item -ItemType Directory -Path (Split-Path -Parent $log) -Force | Out-Null
function Write-Log([string]$m){ Add-Content -LiteralPath $log -Encoding UTF8 -Value ("{0} {1}" -f (Get-Date -Format o),$m) }
function Invoke-Aria2([string]$Method,[object[]]$Params){
  $body = @{ jsonrpc='2.0'; id=[guid]::NewGuid().ToString('N'); method=$Method; params=$Params } | ConvertTo-Json -Depth 30 -Compress
  Invoke-RestMethod -Uri 'http://127.0.0.1:6899/jsonrpc' -Method Post -ContentType 'application/json' -Body $body -TimeoutSec 3
}
function Load-JsonObject([string]$Path){
  if(-not(Test-Path -LiteralPath $Path -PathType Leaf)){ return [ordered]@{} }
  try {
    $raw=[IO.File]::ReadAllText($Path,[Text.UTF8Encoding]::new($false))
    if([string]::IsNullOrWhiteSpace($raw)){ return [ordered]@{} }
    $obj=$raw | ConvertFrom-Json
    $h=[ordered]@{}
    foreach($p in @($obj.PSObject.Properties)){ $h[$p.Name]=$p.Value }
    return $h
  } catch { Write-Log "LOAD_WARN path='$Path' error='$($_.Exception.Message)'"; return [ordered]@{} }
}
function Write-JsonNoBom([string]$Path,[object]$Obj){
  $json=$Obj | ConvertTo-Json -Depth 80
  $tmp="$Path.tmp"
  [IO.File]::WriteAllText($tmp,$json,[Text.UTF8Encoding]::new($false))
  Move-Item -LiteralPath $tmp -Destination $Path -Force
}
function To-Long($v){ try { return [int64]$v } catch { return 0L } }
function Format-Bytes([int64]$Bytes){
  if($Bytes -ge 1099511627776){ return ('{0:N2} TB' -f ($Bytes/1099511627776.0)) }
  if($Bytes -ge 1073741824){ return ('{0:N2} GB' -f ($Bytes/1073741824.0)) }
  if($Bytes -ge 1048576){ return ('{0:N2} MB' -f ($Bytes/1048576.0)) }
  if($Bytes -ge 1024){ return ('{0:N2} KB' -f ($Bytes/1024.0)) }
  return ("$Bytes B")
}
function Format-Speed([int64]$BytesPerSecond){
  if($BytesPerSecond -le 0){ return '0 B/s' }
  return ((Format-Bytes $BytesPerSecond) + '/s').Replace(' B/s/s',' B/s')
}
function New-ManagerJob($a){
  $gid=''+$a.gid; $files=@($a.files); $first=$files | Select-Object -First 1
  $fpath=(''+$first.path).Replace('/','\')
  $jobPath='F:\Downloads\Unknown Aria2 Download'
  if(-not[string]::IsNullOrWhiteSpace($fpath)){ $jobPath=Split-Path -Parent $fpath }
  $title=Split-Path -Leaf $jobPath
  if([string]::IsNullOrWhiteSpace($title)){ $title="Aria2 Download $gid" }
  $total=To-Long $a.totalLength; $done=To-Long $a.completedLength; $speed=To-Long $a.downloadSpeed
  $progress=0.0; if($total -gt 0){ $progress=[Math]::Round(($done*100.0/$total),4) }
  $per=[ordered]@{}
  $fileList=@()
  foreach($f in $files){
    $fp=(''+$f.path).Replace('/','\')
    $fl=To-Long $f.length; $fc=To-Long $f.completedLength
    $fileList += [ordered]@{ index=''+$f.index; path=$fp; length=''+$fl; completedLength=''+$fc; completed_length=$fc; selected=''+$f.selected; uris=$f.uris }
  }
  $per[$gid]=[ordered]@{ gid=$gid; status=''+$a.status; total_length=$total; totalLength=$total; completed_length=$done; completedLength=$done; download_speed=$speed; downloadSpeed=$speed; upload_speed=0; uploadSpeed=0; progress_percentage=$progress; progress=$progress; files=$fileList }
  return [ordered]@{
    id=$gid; gid=$gid; gids=@($gid); title=$title; name=$title; job_path=$jobPath; path=$jobPath; state=''+$a.status; type='direct'; kind='direct'; category='direct'; download_type='direct'; downloadType='direct'; source='aria2'; progress=$progress; percent=$progress; size=Format-Bytes $total; total_length=$total; completed_length=$done; downloaded_bytes=$done; download_speed=$speed; speed=$speed; speed_text=Format-Speed $speed; status=[ordered]@{ state=''+$a.status; total_length=$total; totalLength=$total; completed_length=$done; completedLength=$done; downloaded_bytes=$done; downloaded=$done; download_speed=$speed; downloadSpeed=$speed; real_download_speed=$speed; realDownloadSpeed=$speed; progress_percentage=$progress; progress=$progress; files=$fileList }; per_gid=$per; updated_at=(Get-Date).ToString('o')
  }
}
function Write-AscendaraDownloadRow($a){
  try {
    $job=New-ManagerJob $a
    $gid=''+$a.gid; $status=(''+$a.status).ToLowerInvariant()
    $total=To-Long $a.totalLength; $done=To-Long $a.completedLength; $speed=To-Long $a.downloadSpeed
    $progress=0.0; if($total -gt 0){ $progress=[Math]::Round(($done*100.0/$total),2) }
    $eta='Calculating...'
    if($speed -gt 0 -and $total -gt $done){
      $seconds=[int][Math]::Ceiling(($total-$done)/[double]$speed)
      $ts=[TimeSpan]::FromSeconds($seconds)
      if($ts.TotalHours -ge 1){ $eta=('{0}h {1}m remaining' -f [int]$ts.TotalHours,$ts.Minutes) } elseif($ts.TotalMinutes -ge 1){ $eta=('{0}m {1}s remaining' -f [int]$ts.TotalMinutes,$ts.Seconds) } else { $eta=('{0}s remaining' -f $ts.Seconds) }
    }
    $dir=$job.job_path; $title=$job.title
    if([string]::IsNullOrWhiteSpace($dir) -or [string]::IsNullOrWhiteSpace($title)){ return $false }
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    $infoPath=Join-Path $dir ("$title.ascendara.json")
    $existing=[ordered]@{}
    if(Test-Path -LiteralPath $infoPath -PathType Leaf){ $existing=Load-JsonObject $infoPath }
    $existing['game']=$title
    $existing['name']=$title
    $existing['title']=$title
    $existing['version']='FitGirl Repack'
    $existing['size']=Format-Bytes $total
    $existing['online']= $true
    $existing['isCustomGame']=$true
    $existing['downloadPath']=$dir
    $existing['path']=$dir
    $existing['source']='aria2-visible-live-sync'
    $existing['gid']=$gid
    $existing['downloadingData']=[ordered]@{
      downloading=($status -eq 'active' -or $status -eq 'waiting')
      extracting=$false
      updating=$false
      verifying=$false
      stopped=($status -eq 'paused')
      paused=($status -eq 'paused')
      waiting=($status -eq 'waiting')
      progressCompleted=(('{0:N2}%' -f $progress))
      progressDownloadSpeeds=(Format-Speed $speed)
      timeUntilComplete=$eta
      totalLength=$total
      completedLength=$done
      downloadedBytes=$done
      downloadSpeed=$speed
      gid=$gid
      status=$status
      files=$job.status.files
      lastSyncedAt=(Get-Date).ToString('o')
    }
    Write-JsonNoBom $infoPath $existing
    return $true
  } catch { Write-Log "ASCENDARA_ROW_ERR gid='$($a.gid)' error='$($_.Exception.Message)'"; return $false }
}
function Sync-Once {
  $keys=@('gid','status','totalLength','completedLength','downloadSpeed','files')
  $active=@((Invoke-Aria2 -Method 'aria2.tellActive' -Params (, $keys)).result)
  $waiting=@((Invoke-Aria2 -Method 'aria2.tellWaiting' -Params (0,100,$keys)).result)
  $items=@($active+$waiting) | Where-Object { $_ -and $_.gid }
  $jobs=Load-JsonObject $manager
  foreach($k in @($jobs.Keys)){ if($k -like 'aria2_*'){ $jobs.Remove($k) } }
  $rowCount=0
  foreach($a in $items){
    $jobs[('aria2_'+$a.gid)] = New-ManagerJob $a
    if(Write-AscendaraDownloadRow $a){ $rowCount++ }
  }
  Write-JsonNoBom $manager $jobs
  $summary=($items | ForEach-Object { '{0}:{1}/{2}@{3}' -f $_.gid,$_.completedLength,$_.totalLength,$_.downloadSpeed }) -join ';'
  Write-Log "SYNC count=$($items.Count) rows=$rowCount $summary"
}
if($args -contains '-Once'){
  try { Sync-Once } catch { Write-Log "SYNC_ERR error='$($_.Exception.Message)'"; exit 1 }
  exit 0
}
while($true){
  try { Sync-Once } catch { Write-Log "SYNC_ERR error='$($_.Exception.Message)'" }
  Start-Sleep -Seconds 2
}
