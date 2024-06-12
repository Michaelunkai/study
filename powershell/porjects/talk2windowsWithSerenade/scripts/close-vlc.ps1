<#
.SYNOPSIS
	Closes the VLC media player application
.DESCRIPTION
	This PowerShell script closes the VLC media player application gracefully.
.EXAMPLE
	PS> ./close-vlc
.NOTES
	Author: Markus Fleschutz / License: CC0
.LINK
	https://github.com/fleschutz/talk2windows
#>

& "$PSScriptRoot/close-program.ps1" "VLC media player" "vlc" "vlc"
exit 0 # success
