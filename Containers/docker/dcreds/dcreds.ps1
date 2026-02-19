<#
.SYNOPSIS
    dcreds - PowerShell utility script
.NOTES
    Original function: dcreds
    Extracted: 2026-02-19 20:20
#>
Set-Location -Path "F:\\backup\windowsapps\Credentials";
    built michadockermisha/backup:creds;
    docker push michadockermisha/backup:creds
