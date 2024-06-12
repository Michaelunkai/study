﻿<#
.SYNOPSIS
	Inserts the Euro sign
.DESCRIPTION
	This PowerShell script inserts the Euro sign ('€') at the current text cursor position.
.EXAMPLE
	PS> ./insert-euro-sign
.LINK
	https://github.com/fleschutz/talk2windows
.NOTES
	Author: Markus Fleschutz | License: CC0
#>

try {
	$obj = New-Object -com wscript.shell
	$obj.SendKeys("€")
	& "$PSScriptRoot/_reply.ps1" "Okay."
	exit 0 # success
} catch {
	& "$PSScriptRoot/_reply.ps1" "Sorry: $($Error[0])"
	exit 1
}
