$ErrorActionPreference='Continue'
$thresholdSeconds=20
$cooldownSeconds=120
$scriptDir=Split-Path -Parent $PSCommandPath
$projectRoot=(Get-Item -LiteralPath (Join-Path $scriptDir '..')).FullName
$stateDir=Join-Path $projectRoot 'runtime\fitlauncher-zero-download-guardian'
$stateFile=Join-Path $stateDir 'zero-download-guardian-state.json'
$log=Join-Path $stateDir 'zero-download-guardian.log'
$canonical='F:\study\Windows\Applications\Gaming\DownloadManagers\qBittorrent\FitGirl\Automation\AutoInstall\qbittorrent-fitgirl-force-auto-install-20260601\scripts\Force-QbitFitGirlAutoInstall.ps1'
$syncTask='FitLauncher Visible Downloads Live Sync'
$fitExe='F:\backup\windowsapps\installed\Fit Launcher\Fit Launcher.exe'
New-Item -ItemType Directory -Path $stateDir -Force | Out-Null
New-Item -ItemType Directory -Path (Split-Path -Parent $log) -Force | Out-Null
function L($m){ Add-Content -LiteralPath $log -Encoding UTF8 -Value ("{0} {1}" -f (Get-Date -Format o),$m) }
function Load-State { if(Test-Path $stateFile){ try { return Get-Content $stateFile -Raw | ConvertFrom-Json } catch {} }; return [pscustomobject]@{ zeroSince=$null; lastReset=$null } }
function Save-State($s){ $s | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $stateFile -Encoding UTF8 }
function Invoke-Aria2($m,$p){ $body=@{jsonrpc='2.0';id='guardian';method=$m;params=$p}|ConvertTo-Json -Depth 10 -Compress; Invoke-RestMethod -Uri 'http://127.0.0.1:6899/jsonrpc' -Method Post -ContentType 'application/json' -Body $body -TimeoutSec 2 }
function Get-AriaCountSpeed {
  $keys=@('gid','status','totalLength','completedLength','downloadSpeed','files')
  try { $a=@((Invoke-Aria2 'aria2.tellActive' (, $keys)).result); $w=@((Invoke-Aria2 'aria2.tellWaiting' @(0,100,$keys)).result); $items=@($a+$w)|?{$_ -and $_.gid}; $speed=0L; foreach($i in $items){ try{$speed += [int64]$i.downloadSpeed}catch{} }; return @($items.Count,$speed) } catch { return @(0,0) }
}
function ManagerJobCount {
  $m=Join-Path $env:APPDATA 'com.fitlauncher.carrotrub\manager.json'
  if(-not(Test-Path $m)){ return 0 }
  try { $raw=Get-Content $m -Raw; if([string]::IsNullOrWhiteSpace($raw)){ return 0 }; $o=$raw|ConvertFrom-Json; return @($o.PSObject.Properties).Count } catch { return 0 }
}
function Reset-Retry {
  $ts=Get-Date -Format yyyyMMdd-HHmmss
  $backup="F:\Downloads\.fitgirl_tmp\zero-download-guardian-reset-$ts"
  New-Item -ItemType Directory -Path $backup -Force | Out-Null
  L "RESET_BEGIN backup=$backup"
  schtasks /End /TN $syncTask 2>&1 | Out-Null
  Get-Process 'Fit Launcher','FitLauncherService','aria2c','aria2c.real' -ErrorAction SilentlyContinue | % { L "STOP pid=$($_.Id) name=$($_.ProcessName)"; Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue }
  Start-Sleep -Seconds 1
  foreach($p in @((Join-Path $env:APPDATA 'com.fitlauncher.carrotrub'),(Join-Path $env:LOCALAPPDATA 'com.fitlauncher.carrotrub'))){
    if(Test-Path $p){ Copy-Item -LiteralPath $p -Destination (Join-Path $backup ([IO.Path]::GetFileName($p))) -Recurse -Force -ErrorAction SilentlyContinue; Get-ChildItem -LiteralPath $p -Force -ErrorAction SilentlyContinue | ? { $_.Name -ne 'logs' -and $_.Name -ne 'guardian' } | % { try { Remove-Item -LiteralPath $_.FullName -Recurse -Force -ErrorAction Stop; L "DELETED $($_.FullName)" } catch { L "SKIP_DELETE $($_.FullName) $($_.Exception.Message)" } } }
  }
  schtasks /Change /TN $syncTask /ENABLE 2>&1 | Out-Null
  schtasks /Run /TN $syncTask 2>&1 | Out-Null
  & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $canonical -Install -RunOnceAfterInstall 2>&1 | Select-Object -Last 80 | % { L "CANON $_" }
  L "CANON_EXIT=$LASTEXITCODE"
  if(Test-Path $fitExe){ Start-Process -FilePath $fitExe; L "REOPENED_FIT_LAUNCHER" }
  L "RESET_END"
}
while($true){
  try {
    $fit=@(Get-Process 'Fit Launcher' -ErrorAction SilentlyContinue | ? { $_.MainWindowTitle -or $_.Path })
    $aria=Get-AriaCountSpeed; $count=[int]$aria[0]; $speed=[int64]$aria[1]; $mj=ManagerJobCount
    $s=Load-State; $now=Get-Date
    if($fit.Count -gt 0 -and $count -eq 0 -and $speed -eq 0 -and $mj -eq 0){
      if(-not $s.zeroSince){ $s.zeroSince=$now.ToString('o'); L "ZERO_START fit=$($fit.Count)" }
      $elapsed=($now-[datetime]$s.zeroSince).TotalSeconds
      $lastResetElapsed=999999; if($s.lastReset){ $lastResetElapsed=($now-[datetime]$s.lastReset).TotalSeconds }
      if($elapsed -ge $thresholdSeconds -and $lastResetElapsed -ge $cooldownSeconds){ $s.lastReset=$now.ToString('o'); Save-State $s; L "ZERO_THRESHOLD elapsed=$([int]$elapsed) resetting"; Reset-Retry; $s.zeroSince=$null }
    } else {
      if($s.zeroSince){ L "ZERO_CLEARED fit=$($fit.Count) ariaCount=$count speed=$speed managerJobs=$mj" }
      $s.zeroSince=$null
    }
    Save-State $s
  } catch { L "ERR $($_.Exception.Message)" }
  Start-Sleep -Seconds 5
}
