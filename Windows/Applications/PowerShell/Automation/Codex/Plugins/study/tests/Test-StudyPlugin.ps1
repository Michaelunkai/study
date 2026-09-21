$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$manifestPath = Join-Path $root '.codex-plugin\plugin.json'
$skillPath = Join-Path $root 'skills\study\SKILL.md'
$helperPath = Join-Path $root 'scripts\Invoke-StudyProject.ps1'
foreach ($path in @($manifestPath,$skillPath,$helperPath)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Missing required file: $path" }
}
$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
if ($manifest.name -ne 'study') { throw 'Manifest name is not study.' }
if ($manifest.version -ne '1.0.0') { throw 'Unexpected manifest version.' }
$skill = Get-Content -LiteralPath $skillPath -Raw
if ($skill -notmatch 'at least six path levels|six-plus-level') { throw 'Deep-placement rule missing.' }
if ($skill -notmatch 'public repository|public GitHub') { throw 'Public GitHub rule missing.' }
if ($skill -match '\[TODO:') { throw 'Placeholder remains in skill.' }
$tokens = $null
$errors = $null
$null = [Management.Automation.Language.Parser]::ParseFile($helperPath,[ref]$tokens,[ref]$errors)
if ($errors.Count) { throw ($errors | Out-String) }
'PASS: study manifest, workflow rules, and Windows PowerShell 5.1 helper parse.'
