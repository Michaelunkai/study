<#
.SYNOPSIS
    cco - PowerShell utility script
.NOTES
    Original function: cco
    Extracted: 2026-02-19 20:20
#>
<#
        .SYNOPSIS
            Copy the contents of a file (like a Unix `cat` pipe) to the clipboard.
        .EXAMPLE
            cco "F:\path\to\script.ahk"
    #>
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]$Path
    )
    if (Test-Path -LiteralPath $Path) {
        try {
            Get-Content -LiteralPath $Path -Raw -ErrorAction Stop |
                CopyClip
        }
        catch {
            Write-Warning "? Failed to read file: $($_.Exception.Message)"
        }
    }
    else {
        Write-Warning "? File not found: $Path"
    }
