<#
.SYNOPSIS
    lines - PowerShell utility script
.NOTES
    Original function: lines
    Extracted: 2026-02-19 20:20
#>
param([string]$Path)
    $fullPath = (Resolve-Path $Path).Path
    $stream = [System.IO.FileStream]::new($fullPath, 'Open', 'Read', 'ReadWrite')
    $reader = [System.IO.StreamReader]::new($stream)
    $count = 0
    while ($null -ne $reader.ReadLine()) { $count++ }
    $reader.Dispose()
    $count
