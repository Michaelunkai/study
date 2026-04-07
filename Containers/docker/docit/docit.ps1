# docit - Docker interactive container launcher
param([string]$Image = "ubuntu:latest", [string]$Shell = "/bin/bash")
Write-Host "Launching $Image interactively..." -ForegroundColor Cyan
docker run -it --rm $Image $Shell