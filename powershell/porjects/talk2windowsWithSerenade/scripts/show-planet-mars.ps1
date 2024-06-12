<#
.SYNOPSIS
	Shows planet Mars in Google Maps 
.DESCRIPTION
	This PowerShell script launches the Web browser and shows planet Mars in Google Maps.
.EXAMPLE
	PS> ./show-planet-mars
.NOTES
	Author: Markus Fleschutz · License: CC0
.LINK
	https://github.com/fleschutz/talk2windows
#>

& "$PSScriptRoot/open-browser.ps1" "https://www.google.com/maps/space/mars"
exit 0 # success
