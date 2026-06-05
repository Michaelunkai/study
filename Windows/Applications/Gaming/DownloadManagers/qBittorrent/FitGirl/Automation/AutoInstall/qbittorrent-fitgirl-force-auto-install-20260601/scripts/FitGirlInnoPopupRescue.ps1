param([switch]$SelfTest,[switch]$Once)
$ErrorActionPreference='SilentlyContinue'
Add-Type -AssemblyName System.Windows.Forms | Out-Null
Add-Type @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public class Win32InnoRescue {
  public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);
  [DllImport("user32.dll")] public static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);
  [DllImport("user32.dll")] public static extern bool EnumChildWindows(IntPtr hWndParent, EnumWindowsProc lpEnumFunc, IntPtr lParam);
  [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);
  [DllImport("user32.dll")] public static extern int GetClassName(IntPtr hWnd, StringBuilder lpClassName, int nMaxCount);
  [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr hWnd);
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
  [DllImport("user32.dll")] public static extern IntPtr SendMessage(IntPtr hWnd, int Msg, IntPtr wParam, IntPtr lParam);
}
'@ | Out-Null
$LogDir='F:\Downloads\.fitgirl_tmp\qbit-force-auto-install'
try{ New-Item -ItemType Directory -Path $LogDir -Force | Out-Null }catch{}
$LogFile=Join-Path $LogDir 'fitgirl-inno-popup-rescue.log'
function Log([string]$m){ try{ Add-Content -LiteralPath $LogFile -Value ((Get-Date -Format 'yyyy-MM-dd HH:mm:ss')+' '+$m) -Encoding UTF8 }catch{} }
function Get-WText([IntPtr]$h){ $sb=New-Object Text.StringBuilder 2048; [void][Win32InnoRescue]::GetWindowText($h,$sb,$sb.Capacity); $sb.ToString() }
function Get-WClass([IntPtr]$h){ $sb=New-Object Text.StringBuilder 256; [void][Win32InnoRescue]::GetClassName($h,$sb,$sb.Capacity); $sb.ToString() }
function Get-Children([IntPtr]$h){ $list=New-Object System.Collections.Generic.List[object]; [Win32InnoRescue]::EnumChildWindows($h,{ param($c,$l) $list.Add([pscustomobject]@{H=$c;Text=(Get-WText $c);Class=(Get-WClass $c)}) | Out-Null; return $true },[IntPtr]::Zero) | Out-Null; $list }
function Is-MissingSourceIgnorePopup([string]$blob){
  $b=$blob.ToLowerInvariant()
  if($b -notmatch '(source file|trying to read the source file)' -or $b -notmatch '(does not exist|cannot find|system cannot find)'){ return $false }
  if($b -match '(archive.*corrupt|checksum|crc|isdone|unarc|disk full|not enough disk|write error)'){ return $false }
  if($b -match '(ignore to skip|\bignore\b)' -and $b -match '(\babort\b|\bretry\b)'){ return $true }
  if($b -match 'c:\\temp\\is-[^\s]+\\' -or $b -match '(vc_redist|vcredist|redist|directx|dxwebsetup|nodist|no[_-]?dist)'){ return $true }
  return $false
}
function Invoke-RescueOnce{
  $script:handled=0
  [Win32InnoRescue]::EnumWindows({ param($h,$l)
    if(-not [Win32InnoRescue]::IsWindowVisible($h)){ return $true }
    $title=Get-WText $h
    if($title -notmatch '^(Error|Setup Error|Download failed|Cannot connect|Security Warning)$'){ return $true }
    $children=Get-Children $h
    $blob=($title+' '+(($children|ForEach-Object Text) -join ' '))
    if(-not (Is-MissingSourceIgnorePopup $blob)){ return $true }
    $ignore=@($children | Where-Object { $_.Text -replace '&','' -match '^(Ignore|Skip)$' } | Select-Object -First 1)
    if($ignore.Count -gt 0){
      [void][Win32InnoRescue]::SetForegroundWindow($h)
      Start-Sleep -Milliseconds 50
      [void][Win32InnoRescue]::SendMessage($ignore[0].H,0x00F5,[IntPtr]::Zero,[IntPtr]::Zero)
      Log ("INNO_MISSING_SOURCE_IGNORE_CLICK title='$title' text='"+($blob -replace '\s+',' ').Substring(0,[Math]::Min(500,($blob -replace '\s+',' ').Length))+"'")
      $script:handled++
    } else {
      [void][Win32InnoRescue]::SetForegroundWindow($h)
      Start-Sleep -Milliseconds 50
      [System.Windows.Forms.SendKeys]::SendWait('%i')
      Log "INNO_MISSING_SOURCE_IGNORE_ALT_I title='$title'"
      $script:handled++
    }
    return $true
  },[IntPtr]::Zero) | Out-Null
  return $script:handled
}
if($SelfTest){
  $marker=Join-Path $env:TEMP 'qbit-fitgirl-inno-popup-rescue-selftest.txt'
  try{ Remove-Item $marker -Force -ErrorAction SilentlyContinue }catch{}
  $form=New-Object Windows.Forms.Form
  $form.Text='Error'; $form.Width=650; $form.Height=260; $form.TopMost=$true
  $label=New-Object Windows.Forms.Label; $label.AutoSize=$false; $label.Left=30; $label.Top=30; $label.Width=560; $label.Height=110
  $label.Text='An error occurred while trying to read the source file:`r`nThe source file "C:\Temp\is-8DURD.tmp\vc_redist.x86.exe" does not exist.`r`n`r`nClick Retry to try again, Ignore to skip this file (not recommended), or Abort to cancel installation.'
  $form.Controls.Add($label)
  foreach($spec in @(@('Abort',280),@('Retry',400),@('Ignore',520))){ $btn=New-Object Windows.Forms.Button; $btn.Text=$spec[0]; $btn.Left=$spec[1]; $btn.Top=160; $btn.Width=100; if($spec[0] -eq 'Ignore'){ $btn.Add_Click({ Set-Content -LiteralPath $marker -Value 'ignore' -Force }) }; $form.Controls.Add($btn) }
  $form.Show(); [Windows.Forms.Application]::DoEvents(); Start-Sleep -Milliseconds 300
  $n=Invoke-RescueOnce; [Windows.Forms.Application]::DoEvents(); Start-Sleep -Milliseconds 500
  $ok=Test-Path -LiteralPath $marker
  $form.Close(); $form.Dispose()
  if($n -ge 1 -and $ok){ Log 'SELFTEST_OK'; exit 0 }
  Log "SELFTEST_FAIL handled=$n marker=$ok"; exit 2
}
Log 'POPUP_RESCUE_START'
do { [void](Invoke-RescueOnce); if($Once){ break }; Start-Sleep -Milliseconds 250 } while($true)
