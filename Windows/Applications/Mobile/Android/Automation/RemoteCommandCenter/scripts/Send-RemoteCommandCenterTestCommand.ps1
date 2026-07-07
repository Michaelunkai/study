param(
    [string]$ConfigPath = "$PSScriptRoot\rcc-config.json",
    [string]$Action = 'force_reboot_now',
    [switch]$ProofOnly
)

$ErrorActionPreference = 'Stop'
$config = Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json
function ConvertTo-Base64Url { param([byte[]]$Bytes) [Convert]::ToBase64String($Bytes).TrimEnd('=').Replace('+','-').Replace('/','_') }
function Get-HmacSignature {
    param([string]$Text,[string]$Key)
    $hmac = New-Object System.Security.Cryptography.HMACSHA256
    $hmac.Key = [Text.Encoding]::UTF8.GetBytes($Key)
    ConvertTo-Base64Url $hmac.ComputeHash([Text.Encoding]::UTF8.GetBytes($Text))
}
$nonceBytes = New-Object byte[] 18
[Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($nonceBytes)
$nonce = ConvertTo-Base64Url $nonceBytes
$created = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
$dry = [bool]$ProofOnly
$canonical = "rcc|$created|$nonce|$(([string]$dry).ToLowerInvariant())|$Action|REMOTE_COMMAND_CENTER_EXECUTE"
$body = [ordered]@{
    type = 'rcc'
    createdAt = $created
    nonce = $nonce
    dryRun = $dry
    action = $Action
    confirm = 'REMOTE_COMMAND_CENTER_EXECUTE'
    signature = Get-HmacSignature -Text $canonical -Key $config.SharedKey
} | ConvertTo-Json -Compress
Invoke-RestMethod -Method Post -Uri "http://127.0.0.1:$($config.LocalPort)$($config.LocalPath)" -ContentType 'application/json' -Body $body | Out-Null
Write-Output $nonce
