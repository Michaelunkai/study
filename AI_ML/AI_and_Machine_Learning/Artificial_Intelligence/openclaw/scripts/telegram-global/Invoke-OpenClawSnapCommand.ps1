param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Args
)

$ErrorActionPreference = 'Stop'

. 'F:\study\AI_ML\AI_and_Machine_Learning\Artificial_Intelligence\openclaw\scripts\Resolve-OpenClawPaths.ps1'
$paths = Get-OpenClawPaths
$outboundRoot = Join-Path $paths.StateRoot 'media\outbound'

function Get-RequestedMonitorIndex {
    param([string]$RequestText)

    if ($RequestText -match 'monitor\s+(?<index>\d+)') {
        return [int]$Matches['index']
    }

    return $null
}

function New-Screenshot {
    param(
        [AllowNull()][Nullable[int]]$MonitorIndex,
        [Parameter(Mandatory = $true)][string]$OutputPath
    )

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $screens = [System.Windows.Forms.Screen]::AllScreens
    if (-not $screens -or $screens.Count -eq 0) {
        throw 'No Windows screen was available for /snap.'
    }

    if ($null -ne $MonitorIndex) {
        if ($MonitorIndex -lt 1 -or $MonitorIndex -gt $screens.Count) {
            throw "Monitor $MonitorIndex is not available. Detected monitors: $($screens.Count)."
        }
        $bounds = $screens[$MonitorIndex - 1].Bounds
    } else {
        $left = ($screens | ForEach-Object { $_.Bounds.Left } | Measure-Object -Minimum).Minimum
        $top = ($screens | ForEach-Object { $_.Bounds.Top } | Measure-Object -Minimum).Minimum
        $right = ($screens | ForEach-Object { $_.Bounds.Right } | Measure-Object -Maximum).Maximum
        $bottom = ($screens | ForEach-Object { $_.Bounds.Bottom } | Measure-Object -Maximum).Maximum
        $bounds = [System.Drawing.Rectangle]::FromLTRB([int]$left, [int]$top, [int]$right, [int]$bottom)
    }

    if ($bounds.Width -le 0 -or $bounds.Height -le 0) {
        throw "Invalid screen bounds for /snap: $bounds"
    }

    $bitmap = [System.Drawing.Bitmap]::new($bounds.Width, $bounds.Height)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    try {
        $graphics.CopyFromScreen($bounds.Left, $bounds.Top, 0, 0, $bounds.Size)
        $bitmap.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)
    } finally {
        $graphics.Dispose()
        $bitmap.Dispose()
    }
}

try {
    New-Item -ItemType Directory -Force -Path $outboundRoot | Out-Null

    $request = (($Args | Where-Object { $_ -ne $null }) -join ' ').Trim().ToLowerInvariant()
    $monitorIndex = Get-RequestedMonitorIndex -RequestText $request
    $fileName = 'snap-{0}.png' -f [guid]::NewGuid().ToString('N')
    $outputPath = Join-Path $outboundRoot $fileName

    New-Screenshot -MonitorIndex $monitorIndex -OutputPath $outputPath

    if (-not (Test-Path -LiteralPath $outputPath)) {
        throw "Screenshot capture completed without creating: $outputPath"
    }

    Write-Output ("MEDIA:{0}" -f $outputPath)
    if ($null -ne $monitorIndex) {
        Write-Output ("Captured monitor {0} screenshot." -f $monitorIndex)
    } else {
        Write-Output 'Captured full desktop screenshot.'
    }
    exit 0
} catch {
    $message = $_.Exception.Message
    if ([string]::IsNullOrWhiteSpace($message)) {
        $message = [string]$_
    }
    Write-Output $message.Trim()
    exit 1
}
