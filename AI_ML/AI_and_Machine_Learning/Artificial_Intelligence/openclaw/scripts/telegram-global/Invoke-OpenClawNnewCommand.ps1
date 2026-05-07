param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Args
)

$ErrorActionPreference = 'Stop'

. 'F:\study\AI_ML\AI_and_Machine_Learning\Artificial_Intelligence\openclaw\scripts\Resolve-OpenClawPaths.ps1'
$paths = Get-OpenClawPaths

function Resolve-TelegramUserId {
    param([string[]]$RawArgs)

    foreach ($arg in @($RawArgs)) {
        if ([string]$arg -match '\b(?<id>\d{5,})\b') {
            return $Matches['id']
        }
    }

    $ids = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($storePath in Get-ChildItem -LiteralPath $paths.AgentsRoot -Recurse -File -Filter 'sessions.json' -ErrorAction SilentlyContinue) {
        try {
            $store = Get-Content -Raw -LiteralPath $storePath.FullName | ConvertFrom-Json
            foreach ($prop in $store.PSObject.Properties) {
                if ($prop.Name -match ':telegram:[^:]+:direct:(?<id>\d+)$') {
                    [void]$ids.Add($Matches['id'])
                }
            }
        } catch {
        }
    }

    if ($ids.Count -eq 1) {
        return @($ids)[0]
    }

    throw 'Could not infer Telegram user id. Pass the numeric Telegram user id after /nnew.'
}

try {
    $userId = Resolve-TelegramUserId -RawArgs $Args
    $resetScript = Join-Path $paths.RepoRoot 'scripts\telegram-global\Reset-OpenClawTelegramSessions.ps1'
    $raw = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $resetScript -UserId $userId 2>&1
    $exitCode = $LASTEXITCODE
    $text = (($raw | ForEach-Object { [string]$_ }) -join [Environment]::NewLine).Trim()
    if ($exitCode -ne 0) {
        if ([string]::IsNullOrWhiteSpace($text)) {
            $text = "reset exited with code $exitCode"
        }
        throw $text
    }

    $results = $text | ConvertFrom-Json
    $updated = @($results | Where-Object { $_.updated }).Count
    Write-Output ("OpenClaw fresh sessions reset for Telegram user {0}: {1}/4 bot sessions refreshed." -f $userId, $updated)
    foreach ($entry in @($results)) {
        Write-Output ('- {0}/{1}: {2}' -f $entry.agentId, $entry.accountId, $(if ($entry.updated) { 'fresh' } else { [string]$entry.reason }))
    }
    exit 0
} catch {
    $message = $_.Exception.Message
    if ([string]::IsNullOrWhiteSpace($message)) {
        $message = [string]$_
    }
    Write-Output ("OpenClaw /nnew failed: {0}" -f $message.Trim())
    exit 1
}
