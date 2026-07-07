param(
    [int[]]$Ports = @(7, 9, 40000, 40009),
    [string]$ExpectedMac = '30:56:0F:40:D2:4C',
    [int]$Seconds = 30,
    [string]$ProofPath = 'F:\study\Windows\Applications\Mobile\Android\Automation\RemoteCommandCenter\runtime\logs\wake-packet-proof.json'
)

$ErrorActionPreference = 'Stop'
$expectedClean = ($ExpectedMac -replace '[:-]', '').ToUpperInvariant()
$expectedBytes = for ($i = 0; $i -lt 6; $i++) { [Convert]::ToByte($expectedClean.Substring($i * 2, 2), 16) }
$listeners = @()
$results = New-Object System.Collections.ArrayList

function Test-WakePayload {
    param([byte[]]$Bytes)
    if ($Bytes.Length -lt 102) { return $false }
    for ($i = 0; $i -lt 6; $i++) {
        if ($Bytes[$i] -ne 0xFF) { return $false }
    }
    for ($repeat = 0; $repeat -lt 16; $repeat++) {
        for ($i = 0; $i -lt 6; $i++) {
            if ($Bytes[6 + ($repeat * 6) + $i] -ne $expectedBytes[$i]) { return $false }
        }
    }
    return $true
}

try {
    foreach ($port in $Ports) {
        $udp = [Net.Sockets.UdpClient]::new($port)
        $udp.Client.ReceiveTimeout = 250
        $listeners += [pscustomobject]@{ Port = $port; Client = $udp }
    }

    $deadline = [DateTime]::UtcNow.AddSeconds($Seconds)
    while ([DateTime]::UtcNow -lt $deadline) {
        foreach ($listener in $listeners) {
            $remote = [Net.IPEndPoint]::new([Net.IPAddress]::Any, 0)
            try {
                $bytes = $listener.Client.Receive([ref]$remote)
                $isWake = Test-WakePayload -Bytes $bytes
                [void]$results.Add([pscustomobject]@{
                    TimeUtc = [DateTime]::UtcNow.ToString('o')
                    Port = $listener.Port
                    Remote = $remote.ToString()
                    Length = $bytes.Length
                    WakePayloadForExpectedMac = $isWake
                })
            } catch [Net.Sockets.SocketException] {
                if ($_.Exception.SocketErrorCode -ne [Net.Sockets.SocketError]::TimedOut) { throw }
            }
        }
    }
} finally {
    foreach ($listener in $listeners) { $listener.Client.Close() }
}

$summary = [pscustomobject]@{
    ExpectedMac = $ExpectedMac
    Ports = $Ports
    Seconds = $Seconds
    ReceivedCount = $results.Count
    MatchedPorts = @($results | Where-Object WakePayloadForExpectedMac | Select-Object -ExpandProperty Port -Unique | Sort-Object)
    Events = @($results)
}

New-Item -ItemType Directory -Force -Path (Split-Path -Parent $ProofPath) | Out-Null
$summary | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $ProofPath -Encoding UTF8
$summary | ConvertTo-Json -Depth 5

if (@($summary.MatchedPorts).Count -eq 0) { exit 2 }
exit 0
