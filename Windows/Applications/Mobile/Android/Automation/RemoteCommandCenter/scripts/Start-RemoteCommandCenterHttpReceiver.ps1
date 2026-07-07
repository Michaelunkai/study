param(
    [string]$ConfigPath = "$PSScriptRoot\rcc-config.json",
    [int]$Port = 8777
)

$ErrorActionPreference = 'Continue'
$config = Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json
New-Item -ItemType Directory -Force -Path $config.StateDir, $config.LogDir | Out-Null
$log = Join-Path $config.LogDir 'http-listener.log'
$queueDir = Join-Path $config.StateDir 'local-queue'
New-Item -ItemType Directory -Force -Path $queueDir | Out-Null

function Write-HttpLog { param([string]$Message) Add-Content -LiteralPath $log -Encoding UTF8 -Value ("[{0}] {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'), $Message) }
function ConvertTo-Base64Url { param([byte[]]$Bytes) [Convert]::ToBase64String($Bytes).TrimEnd('=').Replace('+','-').Replace('/','_') }
function Get-HmacSignature {
    param([string]$Text,[string]$Key)
    $hmac = New-Object System.Security.Cryptography.HMACSHA256
    $hmac.Key = [Text.Encoding]::UTF8.GetBytes($Key)
    ConvertTo-Base64Url $hmac.ComputeHash([Text.Encoding]::UTF8.GetBytes($Text))
}
function Test-Command {
    param($Command)
    if ($Command.type -ne 'rcc') { return $false }
    if ([string]$Command.confirm -ne 'REMOTE_COMMAND_CENTER_EXECUTE') { return $false }
    $createdAt = [int64]$Command.createdAt
    if ([Math]::Abs(([DateTimeOffset]::UtcNow.ToUnixTimeSeconds() - $createdAt)) -gt [int]$config.AllowedSkewSeconds) { return $false }
    $dryText = ([string]$Command.dryRun).ToLowerInvariant()
    $canonical = "rcc|$($Command.createdAt)|$($Command.nonce)|$dryText|$($Command.action)|$($Command.confirm)"
    (Get-HmacSignature -Text $canonical -Key $config.SharedKey) -eq [string]$Command.signature
}
function Invoke-CommandBody {
    param([string]$Body)
    $command = $Body | ConvertFrom-Json
    if (-not (Test-Command -Command $command)) { return @{ ok=$false; message='rejected' } }
    $safeNonce = ([string]$command.nonce -replace '[^A-Za-z0-9_-]', '_')
    $path = Join-Path $queueDir ("{0}-{1}.json" -f ([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()), $safeNonce)
    Set-Content -LiteralPath $path -Encoding UTF8 -Value $Body
    & "$env:SystemRoot\System32\schtasks.exe" /Run /TN 'RemoteCommandCenterAgentKick' 2>$null | Out-Null
    & "$env:SystemRoot\System32\schtasks.exe" /Run /TN 'RemoteCommandCenterAgentLogon' 2>$null | Out-Null
    Write-HttpLog "Queued command action=$($command.action) nonce=$($command.nonce) path=$path"
    @{ ok=$true; message='queued'; nonce=[string]$command.nonce }
}
function Get-StatusBody {
    @{
        ok = $true
        state = 'ready'
        machine = $env:COMPUTERNAME
        utc = [DateTimeOffset]::UtcNow.ToString('o')
    } | ConvertTo-Json -Compress
}

$listener = New-Object System.Net.HttpListener
$prefix = "http://+:$Port/rcc/"
$listener.Prefixes.Add($prefix)
$listener.Start()
Write-HttpLog "HTTP receiver started prefix=$prefix"
while ($listener.IsListening) {
    try {
        $context = $listener.GetContext()
        $response = $context.Response
        $response.ContentType = 'application/json; charset=utf-8'
        $path = $context.Request.Url.AbsolutePath
        $method = $context.Request.HttpMethod
        if ($path -eq '/rcc/status' -and $method -in @('GET','POST')) {
            $response.StatusCode = 200
            $out = Get-StatusBody
        } elseif ($method -eq 'POST' -and $path -eq '/rcc/action') {
            $reader = New-Object IO.StreamReader($context.Request.InputStream, [Text.Encoding]::UTF8)
            $result = Invoke-CommandBody -Body $reader.ReadToEnd()
            $response.StatusCode = if ($result.ok) { 202 } else { 403 }
            $out = $result | ConvertTo-Json -Compress
        } else {
            $response.StatusCode = 404
            $out = '{"ok":false,"message":"not found"}'
        }
        $bytes = [Text.Encoding]::UTF8.GetBytes($out)
        $response.ContentLength64 = $bytes.Length
        $response.OutputStream.Write($bytes, 0, $bytes.Length)
        $response.OutputStream.Close()
    } catch {
        Write-HttpLog "Listener failed: $($_.Exception.Message)"
        Start-Sleep -Milliseconds 250
    }
}
