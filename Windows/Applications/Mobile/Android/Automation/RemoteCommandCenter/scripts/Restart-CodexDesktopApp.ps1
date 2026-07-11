param(
    [switch]$ProbeOnly,
    [int]$ReadyTimeoutSeconds = 20
)

$ErrorActionPreference = 'Stop'
$mutex = [Threading.Mutex]::new($false, 'Global\RemoteCommandCenterRestartCodexDesktop')
$lockTaken = $false

function Get-CodexDesktopPackage {
    Get-AppxPackage -Name 'OpenAI.Codex' -ErrorAction SilentlyContinue |
        Sort-Object Version -Descending |
        Select-Object -First 1
}

function Get-CodexDesktopProcesses {
    param([string]$ExecutablePath)
    @(Get-Process -Name 'ChatGPT' -ErrorAction SilentlyContinue | Where-Object {
        try { [string]::Equals($_.Path, $ExecutablePath, [StringComparison]::OrdinalIgnoreCase) } catch { $false }
    })
}

try {
    try {
        $lockTaken = $mutex.WaitOne(0)
    } catch [Threading.AbandonedMutexException] {
        $lockTaken = $true
    }
    if (-not $lockTaken) {
        [pscustomobject]@{ ok = $true; state = 'already-running' } | ConvertTo-Json -Compress
        exit 0
    }

    $package = Get-CodexDesktopPackage
    if (-not $package) { throw 'OpenAI.Codex package is not installed.' }
    $executable = Join-Path $package.InstallLocation 'app\ChatGPT.exe'
    if (-not (Test-Path -LiteralPath $executable -PathType Leaf)) {
        throw "Codex desktop executable was not found at $executable"
    }
    $bootstrap = Join-Path $env:USERPROFILE '.codex\bin\CodexStartupBootstrap.exe'
    $launcher = if (Test-Path -LiteralPath $bootstrap -PathType Leaf) { $bootstrap } else { $executable }
    $before = @(Get-CodexDesktopProcesses -ExecutablePath $executable)

    if ($ProbeOnly) {
        [pscustomobject]@{
            ok = $true
            state = 'ready'
            package = $package.PackageFullName
            version = [string]$package.Version
            executable = $executable
            launcher = $launcher
            processCount = $before.Count
        } | ConvertTo-Json -Compress
        exit 0
    }

    foreach ($process in $before) {
        try { $null = $process.CloseMainWindow() } catch {}
    }
    if ($before.Count -gt 0) {
        Start-Sleep -Milliseconds 1200
        foreach ($process in @(Get-CodexDesktopProcesses -ExecutablePath $executable)) {
            Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
        }
    }

    Start-Process -FilePath $launcher | Out-Null
    $deadline = [DateTime]::UtcNow.AddSeconds($ReadyTimeoutSeconds)
    do {
        Start-Sleep -Milliseconds 250
        $after = @(Get-CodexDesktopProcesses -ExecutablePath $executable)
        if ($after.Count -gt 0) {
            [pscustomobject]@{
                ok = $true
                state = 'restarted'
                version = [string]$package.Version
                processIds = @($after.Id)
                launcher = $launcher
            } | ConvertTo-Json -Compress
            exit 0
        }
    } while ([DateTime]::UtcNow -lt $deadline)

    throw "Codex desktop did not become ready within $ReadyTimeoutSeconds seconds."
} finally {
    if ($lockTaken) {
        try { $mutex.ReleaseMutex() } catch {}
    }
    $mutex.Dispose()
}
