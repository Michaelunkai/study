<#
.SYNOPSIS
    getkuma - PowerShell utility script
.NOTES
    Original function: getkuma
    Extracted: 2026-02-19 20:20
#>
docker run -d --restart always -p 3001:3001 -v /var/kuma:/app/data louislam/uptime-kuma:1;
    Start-Process chrome "http://localhost:3001"
