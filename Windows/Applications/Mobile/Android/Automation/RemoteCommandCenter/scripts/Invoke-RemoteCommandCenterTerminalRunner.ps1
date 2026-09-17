param(
    [Parameter(Mandatory = $true)][string]$CommandFile,
    [Parameter(Mandatory = $true)][string]$LogFile,
    [Parameter(Mandatory = $true)][string]$CompletionNonce,
    [Parameter(Mandatory = $true)][string]$ResultFile,
    [Parameter(Mandatory = $true)][string]$ResultDeadlineUtc,
    [string]$BootstrapFile = ''
)

$ErrorActionPreference = 'Stop'

function Write-RccTerminalRunLog {
    param([Parameter(Mandatory = $true)][string]$Message)
    try {
        Add-Content -LiteralPath $LogFile -Encoding UTF8 -Value ("[{0}] TERMINAL_RUN {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'), $Message)
    } catch {
    }
}

function Publish-RccTerminalRunResult {
    param(
        [Parameter(Mandatory = $true)][string]$State,
        [Parameter(Mandatory = $true)][int]$ExitCode,
        [Parameter(Mandatory = $true)][string]$Message
    )
    try {
        if ($CompletionNonce -cnotmatch '^[A-Za-z0-9_-]{16,128}$') { return }
        $deadline = [DateTimeOffset]::Parse($ResultDeadlineUtc, [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::RoundtripKind)
        if ([DateTimeOffset]::UtcNow -ge $deadline) {
            Write-RccTerminalRunLog 'RESULT_SUPPRESSED after-wait-deadline=True'
            return
        }
        $record = [ordered]@{
            type = 'rcc-terminal-result'
            nonce = $CompletionNonce
            state = $State
            exitCode = $ExitCode
            message = $Message
            updatedUtc = [DateTimeOffset]::UtcNow.ToString('o')
        }
        $temporaryFile = "$ResultFile.$PID.tmp"
        Set-Content -LiteralPath $temporaryFile -Encoding UTF8 -Value ($record | ConvertTo-Json -Compress)
        Move-Item -LiteralPath $temporaryFile -Destination $ResultFile -ErrorAction Stop
    } catch {
        Write-RccTerminalRunLog 'RESULT_WRITE_FAILED'
    }
}

$commandText = $null
try {
    Write-RccTerminalRunLog 'START'
    $commandText = Get-Content -LiteralPath $CommandFile -Raw -Encoding UTF8 -ErrorAction Stop
    Remove-Item -LiteralPath $CommandFile -Force -ErrorAction Stop
    Write-RccTerminalRunLog ("COMMAND_LOADED chars={0}" -f $commandText.Length)

    if (-not [string]::IsNullOrWhiteSpace($BootstrapFile)) {
        if (-not (Test-Path -LiteralPath $BootstrapFile -PathType Leaf)) {
            throw 'The terminal bootstrap file is missing.'
        }
        $bootstrapText = Get-Content -LiteralPath $BootstrapFile -Raw -Encoding UTF8 -ErrorAction Stop
        Remove-Item -LiteralPath $BootstrapFile -Force -ErrorAction SilentlyContinue
        if (-not [string]::IsNullOrWhiteSpace($bootstrapText)) {
            Invoke-Expression $bootstrapText
        }
    }

    $global:LASTEXITCODE = 0
    $ErrorActionPreference = 'Stop'
    Invoke-Expression $commandText
    $exitCode = if ($null -eq $global:LASTEXITCODE) { 0 } else { [int]$global:LASTEXITCODE }
    if ($exitCode -ne 0) {
        Write-RccTerminalRunLog ("COMMAND_FAILED exitCode={0}" -f $exitCode)
        Publish-RccTerminalRunResult -State 'failed' -ExitCode $exitCode -Message 'PowerShell invocation returned a nonzero native exit code.'
        Write-Host 'The PowerShell line returned a nonzero native exit code.' -ForegroundColor Red
    } else {
        Write-RccTerminalRunLog 'COMMAND_RETURNED exitCode=0'
        Publish-RccTerminalRunResult -State 'completed' -ExitCode 0 -Message 'PowerShell invocation returned.'
    }
} catch {
    $ErrorActionPreference = 'Continue'
    Write-RccTerminalRunLog 'COMMAND_FAILED PowerShell invocation raised an error.'
    Publish-RccTerminalRunResult -State 'failed' -ExitCode 1 -Message 'PowerShell invocation raised an error.'
    Write-Host 'The PowerShell line raised an error; error details were omitted from the action log.' -ForegroundColor Red
} finally {
    Remove-Item -LiteralPath $CommandFile -Force -ErrorAction SilentlyContinue
    if (-not [string]::IsNullOrWhiteSpace($BootstrapFile)) {
        Remove-Item -LiteralPath $BootstrapFile -Force -ErrorAction SilentlyContinue
    }
}
