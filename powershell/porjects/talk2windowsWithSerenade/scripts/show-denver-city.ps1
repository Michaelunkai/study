<#
.SYNOPSIS
	Show Denver city in Google Maps 
.DESCRIPTION
	This PowerShell script launches the Web browser with Google Maps at Denver city (USA).
.EXAMPLE
	PS> ./show-denver-city
.NOTES
	Author: Markus Fleschutz / License: CC0
.LINK
	https://github.com/fleschutz/talk2windows
#>

& "$PSScriptRoot/open-browser.ps1" "https://www.google.com/maps/place/Denver"
exit 0 # success
