$ErrorActionPreference='Continue'
$manager=Join-Path $env:APPDATA 'com.fitlauncher.carrotrub\manager.json'
$log=Join-Path $env:APPDATA 'com.fitlauncher.carrotrub\logs\live-ui-repair.log'
New-Item -ItemType Directory -Path (Split-Path -Parent $log) -Force | Out-Null
function L($m){ Add-Content -LiteralPath $log -Encoding UTF8 -Value ("{0} {1}" -f (Get-Date -Format o),$m) }
function Get-FirstLiveItem {
  if(-not(Test-Path -LiteralPath $manager -PathType Leaf)){ return $null }
  try {
    $props=@((Get-Content -LiteralPath $manager -Raw | ConvertFrom-Json).PSObject.Properties)
    foreach($p in $props){ if($p.Value -and (''+$p.Value.state).ToLowerInvariant() -in @('active','waiting','paused')){ return $p.Value } }
    if($props.Count -gt 0){ return $props[0].Value }
  } catch { L "MANAGER_READ_ERR $($_.Exception.Message)" }
  return $null
}
function Invoke-CDPExpr([string]$expr){
  try {
    $pages=@(Invoke-RestMethod -Uri 'http://127.0.0.1:9222/json' -TimeoutSec 2)
    if($pages.Count -eq 1 -and $pages[0].PSObject.Properties.Name -contains 'value'){ $pages=@($pages[0].value) }
    $page=$pages | Where-Object { (''+$_.title) -match 'Fit|Download|Game|Launcher' -or (''+$_.url) -match 'localhost|file|app' } | Select-Object -First 1
    if(-not $page){ $page=$pages | Select-Object -First 1 }
    if(-not $page.webSocketDebuggerUrl){ return 'NO_WS_URL' }
    $ws=[System.Net.WebSockets.ClientWebSocket]::new()
    [void]$ws.ConnectAsync([Uri]$page.webSocketDebuggerUrl,[Threading.CancellationToken]::None).GetAwaiter().GetResult()
    $msg=@{id=1;method='Runtime.evaluate';params=@{expression=$expr;returnByValue=$true;awaitPromise=$false}}|ConvertTo-Json -Depth 30 -Compress
    $bytes=[Text.Encoding]::UTF8.GetBytes($msg)
    [void]$ws.SendAsync([ArraySegment[byte]]$bytes,[System.Net.WebSockets.WebSocketMessageType]::Text,$true,[Threading.CancellationToken]::None).GetAwaiter().GetResult()
    $buf=New-Object byte[] 65536
    $seg=[ArraySegment[byte]]::new($buf)
    $res=$ws.ReceiveAsync($seg,[Threading.CancellationToken]::None).GetAwaiter().GetResult()
    $txt=[Text.Encoding]::UTF8.GetString($buf,0,$res.Count)
    $ws.Dispose()
    return $txt
  } catch { return "CDP_ERR $($_.Exception.Message)" }
}
function Inject-Once {
  $item=Get-FirstLiveItem
  if(-not $item){ return 'NO_ITEM' }
  $title=''+$item.title
  if([string]::IsNullOrWhiteSpace($title)){ $title='Live aria2 download' }
  $progress=0.0; try { $progress=[Math]::Round([double]$item.progress_percentage,2) } catch {}
  if($progress -le 0){ try { $progress=[Math]::Round([double]$item.progress,2) } catch {} }
  if($progress -le 0){ try { $progress=[Math]::Round([double]$item.percent,2) } catch {} }
  $speedBytes=0.0; try { $speedBytes=[double]$item.downloadSpeed } catch {}
  if($speedBytes -le 0){ try { $speedBytes=[double]$item.download_speed } catch {} }
  $speed=[Math]::Round(($speedBytes/1MB),2)
  $done=0.0; try { $done=[Math]::Round(([double]$item.completed_length/1MB),1) } catch { try { $done=[Math]::Round(([double]$item.downloaded/1MB),1) } catch {} }
  $total=0.0; try { $total=[Math]::Round(([double]$item.total_length/1MB),1) } catch { try { $total=[Math]::Round(([double]$item.totalLength/1MB),1) } catch {} }
  $active=1
  $jsTitle=$title | ConvertTo-Json -Compress
  $expr=@"
(() => {
  const title=$jsTitle, progress=$progress, speed=$speed, done=$done, total=$total, active=$active;
  const text=(n)=>((n&&n.innerText)||'').trim();
  // Hide the misleading built-in empty state while a real aria2 transfer exists.
  [...document.querySelectorAll('div,section,main')].forEach(el=>{
    const t=text(el);
    if(t.includes('Ready for Downloads!') && t.includes('Your download queue is empty')){
      el.style.display='none'; el.setAttribute('data-hermes-hidden-empty','1');
    }
  });
  let row=document.getElementById('hermes-live-download-row');
  if(!row){ row=document.createElement('div'); row.id='hermes-live-download-row'; document.body.appendChild(row); }
  row.style.cssText='position:fixed;left:4%;right:4%;top:126px;z-index:2147483647;padding:24px 32px 28px 32px;border:3px solid #00ffd5;border-radius:24px;background:rgba(2,18,22,.985);color:white;font-family:Segoe UI,Arial,sans-serif;box-shadow:0 0 45px rgba(0,255,213,.45);max-height:calc(100vh - 150px);overflow:auto;';
  row.innerHTML='<div style="display:flex;align-items:center;justify-content:space-between;gap:20px;margin-bottom:16px">'+
    '<div style="font-size:30px;font-weight:900;color:#00ffd5;letter-spacing:.02em">LIVE REAL DOWNLOADS FROM ARIA2</div>'+
    '<div style="font-size:24px;font-weight:900;color:#39ff88">DOWNLOAD SPEED: '+speed+' MB/s &nbsp; | &nbsp; ACTIVE TRANSFERS: '+active+'</div></div>'+
    '<div style="border:1px solid rgba(0,255,213,.35);border-radius:18px;padding:22px;background:rgba(0,0,0,.24)">'+
    '<div style="font-size:29px;font-weight:800;margin-bottom:14px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis">'+title+'</div>'+
    '<div style="height:26px;background:#102b31;border-radius:999px;overflow:hidden;margin-bottom:14px"><div style="height:100%;width:'+Math.max(0,Math.min(100,progress))+'%;background:linear-gradient(90deg,#00ffd5,#39ff88)"></div></div>'+
    '<div style="font-size:24px;display:flex;gap:36px;flex-wrap:wrap"><b>Progress: '+progress+'%</b><b>Speed: '+speed+' MB/s</b><b>Bytes: '+done+' / '+total+' MB</b><b>Active Transfers: '+active+'</b></div></div>';
  return 'VISIBLE_LIVE_UI_OK '+title+' '+progress+' '+speed;
})()
"@
  return Invoke-CDPExpr $expr
}
if($args -contains '-Once'){
  $r=Inject-Once; L "ONCE $r"; Write-Output $r; exit 0
}
while($true){
  try {
    $fit=@(Get-Process 'Fit Launcher' -ErrorAction SilentlyContinue)
    if($fit.Count -gt 0){ $r=Inject-Once; L "LOOP $r" }
  } catch { L "ERR $($_.Exception.Message)" }
  Start-Sleep -Seconds 2
}
