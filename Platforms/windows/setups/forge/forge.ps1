<#
.SYNOPSIS
    forge - PowerShell utility script
.NOTES
    Original function: forge
    Extracted: 2026-02-19 20:20
#>
param (
        [Parameter(Mandatory = $true, ValueFromRemainingArguments = $true)]
        [string[]]$Terms
    )
    foreach ($term in $Terms) {
        $formatted = $term.Replace(' ', '-').ToLower()
        firefox "https://sourceforge.net/projects/$formatted/files/latest/download"
    }
