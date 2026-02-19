<#
.SYNOPSIS
    geek - PowerShell utility script
.NOTES
    Original function: geek
    Extracted: 2026-02-19 20:20
#>
param (
        [Parameter(Mandatory = $true, ValueFromRemainingArguments = $true)]
        [string[]]$Terms
    )
    foreach ($term in $Terms) {
        $formatted = ($term -replace '[\s\-+]', '_').ToLower()
        Start-Process "firefox.exe" "https://www.majorgeeks.com/files/details/$formatted.html"
    }
