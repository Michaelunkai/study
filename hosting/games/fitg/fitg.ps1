<#
.SYNOPSIS
    fitg - PowerShell utility script
.NOTES
    Original function: fitg
    Extracted: 2026-02-19 20:20
#>
param (
        [Parameter(Mandatory = $true, ValueFromRemainingArguments = $true)]
        [string[]]$Terms
    )
    foreach ($term in $Terms) {
        $formatted = $term.Replace(' ', '-').ToLower()
        Start-Process "firefox.exe" "https://fitgirl-repacks.site/$formatted/"
    }
