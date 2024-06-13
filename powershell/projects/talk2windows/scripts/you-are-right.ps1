<#
.SYNOPSIS
	Replies to "You are right"
.DESCRIPTION
	This PowerShell script replies to "You are right" by text-to-speech (TTS).
.EXAMPLE
	PS> ./you-are-right.ps1
.LINK
	https://github.com/fleschutz/talk2windows
.NOTES
	Author: Markus Fleschutz | License: CC0
#>

$Reply = "Thanks.","I know." | Get-Random
& "$PSScriptRoot/_reply.ps1" $Reply
exit 0 # success
