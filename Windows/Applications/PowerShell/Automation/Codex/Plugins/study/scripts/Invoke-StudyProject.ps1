#Requires -Version 5.1
[CmdletBinding()]
param(
    [string]$SourcePath,
    [string]$ProjectName,
    [string]$StudyRoot = 'F:\study',
    [string]$GitHubOwner,
    [switch]$Move,
    [switch]$CheckOnly
)

$ErrorActionPreference = 'Stop'

function Stop-Study {
    param([string]$Message)
    throw "study: $Message"
}

function Invoke-RequiredCommand {
    param(
        [string]$File,
        [string[]]$Arguments,
        [switch]$Quiet
    )
    $result = & $File @Arguments 2>&1
    if ($LASTEXITCODE -ne 0) {
        if ($Quiet) { Stop-Study "Command failed: $File" }
        Stop-Study (("Command failed: {0}`n{1}" -f $File, ($result -join [Environment]::NewLine)).Trim())
    }
    return $result
}

function Get-PathDepth {
    param([string]$Path, [string]$Root)
    $fullPath = [IO.Path]::GetFullPath($Path).TrimEnd('\')
    $fullRoot = [IO.Path]::GetFullPath($Root).TrimEnd('\')
    if (-not $fullPath.StartsWith($fullRoot, [StringComparison]::OrdinalIgnoreCase)) {
        return 0
    }
    $relative = $fullPath.Substring($fullRoot.Length).Trim('\')
    if ([string]::IsNullOrWhiteSpace($relative)) { return 0 }
    return @($relative.Split('\') | Where-Object { $_ }).Count
}

function Get-SearchTokens {
    param([string]$Text)
    $common = @('the','and','with','from','project','script','file','source','study','ps1','exe')
    return @([regex]::Matches(($Text.ToLowerInvariant()), '[a-z0-9]+') |
        ForEach-Object Value |
        Where-Object { $_.Length -ge 3 -and $_ -notin $common } |
        Select-Object -Unique)
}

function Find-StudyParent {
    param([string]$Root, [string]$Name, [string]$Source)
    $tokens = @(Get-SearchTokens ($Name + ' ' + $Source))
    $blocked = @('temp','tmp','cache','backup','backups','archive','archives','node_modules','bin','obj','downloads')
    $candidates = @()
    if (Test-Path -LiteralPath $Root -PathType Container) {
        $candidates = @(Get-ChildItem -LiteralPath $Root -Directory -Force -Recurse -ErrorAction SilentlyContinue |
            Where-Object {
                $depth = Get-PathDepth $_.FullName $Root
                $depth -ge 6 -and $depth -le 12 -and
                $_.Name -notin $blocked -and
                -not (Test-Path -LiteralPath (Join-Path $_.FullName '.git')) -and
                -not (Test-Path -LiteralPath (Join-Path $_.FullName '.codex-plugin'))
            })
    }
    $ranked = foreach ($candidate in $candidates) {
        $depth = Get-PathDepth $candidate.FullName $Root
        $score = $depth
        $candidateText = $candidate.FullName.ToLowerInvariant()
        foreach ($token in $tokens) {
            if ($candidateText.Contains($token)) { $score += 20 }
        }
        if ((Get-ChildItem -LiteralPath $candidate.FullName -Force -ErrorAction SilentlyContinue | Measure-Object).Count -eq 0) {
            $score += 4
        }
        [pscustomobject]@{ Path = $candidate.FullName; Score = $score; Depth = $depth }
    }
    $best = $ranked | Sort-Object Score,Depth -Descending | Select-Object -First 1
    if ($best) { return $best.Path }

    $fallback = Join-Path $Root 'Windows\Applications\PowerShell\Automation\Codex\Projects'
    if (-not (Test-Path -LiteralPath $fallback -PathType Container)) {
        New-Item -ItemType Directory -Path $fallback -Force | Out-Null
    }
    return $fallback
}

function Write-IfMissing {
    param([string]$Path, [string]$Content)
    if (-not (Test-Path -LiteralPath $Path)) {
        $utf8 = New-Object Text.UTF8Encoding($false)
        [IO.File]::WriteAllText($Path, $Content, $utf8)
    }
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) { Stop-Study 'git is required.' }
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) { Stop-Study 'GitHub CLI gh is required.' }
if (-not (Test-Path -LiteralPath $StudyRoot -PathType Container)) {
    New-Item -ItemType Directory -Path $StudyRoot -Force | Out-Null
}

if ($CheckOnly) {
    & git --version | Out-Null
    & gh --version | Out-Null
    & gh auth status *> $null
    if ($LASTEXITCODE -ne 0) { Stop-Study 'gh is not authenticated.' }
    [pscustomobject]@{
        StudyRoot = [IO.Path]::GetFullPath($StudyRoot)
        HelperPath = [IO.Path]::GetFullPath($MyInvocation.MyCommand.Path)
        Git = 'available'
        GitHub = 'authenticated'
        PowerShell = $PSVersionTable.PSVersion.ToString()
        Mutated = $false
    }
    return
}

if ([string]::IsNullOrWhiteSpace($SourcePath)) {
    Stop-Study 'Provide -SourcePath, or use $study in Codex so the current task supplies the source context.'
}
$source = (Resolve-Path -LiteralPath $SourcePath -ErrorAction Stop).Path
if ([string]::IsNullOrWhiteSpace($ProjectName)) {
    if ((Get-Item -LiteralPath $source).PSIsContainer) {
        $ProjectName = Split-Path -Leaf $source.TrimEnd('\')
    } else {
        $ProjectName = [IO.Path]::GetFileNameWithoutExtension($source)
    }
}
$ProjectName = ($ProjectName -replace '[^A-Za-z0-9._-]', '-').Trim('-','.')
if ([string]::IsNullOrWhiteSpace($ProjectName) -or $ProjectName -match '^(a|script|project)$') {
    Stop-Study 'Use a descriptive -ProjectName rather than a generic name.'
}

$parent = Find-StudyParent -Root $StudyRoot -Name $ProjectName -Source $source
$projectPath = Join-Path $parent $ProjectName
if (Test-Path -LiteralPath $projectPath) {
    Stop-Study "Destination already exists; refusing to overwrite: $projectPath"
}
New-Item -ItemType Directory -Path $projectPath -Force | Out-Null

$sourceItem = Get-Item -LiteralPath $source
if ($sourceItem.PSIsContainer) {
    $children = @(Get-ChildItem -LiteralPath $source -Force)
    foreach ($child in $children) {
        $destination = Join-Path $projectPath $child.Name
        if ($Move) { Move-Item -LiteralPath $child.FullName -Destination $destination }
        else { Copy-Item -LiteralPath $child.FullName -Destination $destination -Recurse -Force }
    }
} else {
    $destination = Join-Path $projectPath $sourceItem.Name
    if ($Move) { Move-Item -LiteralPath $sourceItem.FullName -Destination $destination }
    else { Copy-Item -LiteralPath $sourceItem.FullName -Destination $destination }
}

$readme = @"
# $ProjectName

> A project organized under `F:\study` by the global `$study` workflow.

## Overview

This repository contains the project artifacts, documentation, and verification needed to use and maintain **$ProjectName**.

## Quick start

1. Read the project-specific usage notes below.
2. Run the primary entry point from the repository root.
3. Run the verification commands before publishing changes.

## Verification

Document the exact syntax, test, build, or smoke-test command here.

## Project notes

Add purpose, dependencies, configuration, and operational notes here as the project is refined.

## Safety

Do not commit credentials, private keys, tokens, generated caches, or machine-specific secrets.

## License

Declare the intended license here before distributing the project.
"@
Write-IfMissing (Join-Path $projectPath 'README.md') $readme
Write-IfMissing (Join-Path $projectPath '.gitignore') "*.bak`n*.tmp`n*.log`nnode_modules/`n"

if (-not (Test-Path -LiteralPath (Join-Path $projectPath '.git') -PathType Container)) {
    Invoke-RequiredCommand git @('-C',$projectPath,'init') | Out-Null
}
Invoke-RequiredCommand git @('-C',$projectPath,'branch','-M','main') | Out-Null
Invoke-RequiredCommand git @('-C',$projectPath,'add','--','.') | Out-Null
Invoke-RequiredCommand git @('-C',$projectPath,'diff','--cached','--check') | Out-Null
$secretHit = & git -C $projectPath grep -I -n -E 'ghp_[A-Za-z0-9_]+|github_pat_[A-Za-z0-9_]+|AIza[0-9A-Za-z_-]{20,}|BEGIN (RSA|OPENSSH|EC) PRIVATE KEY' -- . 2>$null
if ($LASTEXITCODE -eq 0) { Stop-Study 'Likely credential material was found; refusing to publish.' }

$owner = $GitHubOwner
if ([string]::IsNullOrWhiteSpace($owner)) {
    $owner = ((Invoke-RequiredCommand gh @('api','user','--jq','.login')) -join '').Trim()
}
if ([string]::IsNullOrWhiteSpace($owner)) { Stop-Study 'Could not determine the authenticated GitHub owner.' }

$gitName = ((& git -C $projectPath config user.name 2>$null) -join '').Trim()
$gitEmail = ((& git -C $projectPath config user.email 2>$null) -join '').Trim()
if ([string]::IsNullOrWhiteSpace($gitName)) { Invoke-RequiredCommand git @('-C',$projectPath,'config','user.name',$owner) | Out-Null }
if ([string]::IsNullOrWhiteSpace($gitEmail)) { Invoke-RequiredCommand git @('-C',$projectPath,'config','user.email',($owner + '@users.noreply.github.com')) | Out-Null }
Invoke-RequiredCommand git @('-C',$projectPath,'commit','-m',('Publish ' + $ProjectName)) | Out-Null

$repoFullName = $owner + '/' + $ProjectName
$repoView = & gh repo view $repoFullName --json isPrivate,url 2>$null
$repoExists = ($LASTEXITCODE -eq 0)
if ($repoExists) {
    $repoInfo = ($repoView -join [Environment]::NewLine) | ConvertFrom-Json
    if ($repoInfo.isPrivate) { Stop-Study "Matching repository exists but is private: $repoFullName" }
    $repoUrl = $repoInfo.url
    $origin = ((& git -C $projectPath remote get-url origin 2>$null) -join '').Trim()
    if ($origin -and $origin -notmatch ('/' + [regex]::Escape($ProjectName) + '(\.git)?$')) {
        Stop-Study "Existing origin does not match $repoFullName; refusing to replace it."
    }
    if (-not $origin) { Invoke-RequiredCommand git @('-C',$projectPath,'remote','add','origin',($repoUrl + '.git')) | Out-Null }
    Invoke-RequiredCommand git @('-C',$projectPath,'push','-u','origin','main') | Out-Null
} else {
    $description = 'Project organized and published by the global study workflow.'
    $created = Invoke-RequiredCommand gh @('repo','create',$repoFullName,'--public','--source',$projectPath,'--remote','origin','--push','--description',$description)
    $repoUrl = (($created | Where-Object { $_ -match '^https?://' }) | Select-Object -First 1).ToString().Trim()
    if ([string]::IsNullOrWhiteSpace($repoUrl)) { $repoUrl = 'https://github.com/' + $repoFullName }
}

$branch = ((Invoke-RequiredCommand git @('-C',$projectPath,'branch','--show-current')) -join '').Trim()
$commit = ((Invoke-RequiredCommand git @('-C',$projectPath,'rev-parse','HEAD')) -join '').Trim()
$remoteCommit = ((Invoke-RequiredCommand git @('-C',$projectPath,'rev-parse','origin/main')) -join '').Trim()
if ($branch -ne 'main') { Stop-Study "Expected main, found $branch." }
if ($commit -ne $remoteCommit) { Stop-Study 'Local main and origin/main do not match.' }
if ((git -C $projectPath status --porcelain)) { Stop-Study 'Working tree is not clean after publication.' }

[pscustomobject]@{
    ProjectPath = [IO.Path]::GetFullPath($projectPath)
    ProjectDepth = Get-PathDepth $projectPath $StudyRoot
    Repository = $repoFullName
    RepositoryUrl = $repoUrl
    Public = $true
    Branch = $branch
    Commit = $commit
    Moved = [bool]$Move
    SourcePath = $source
    HelperPath = [IO.Path]::GetFullPath($MyInvocation.MyCommand.Path)
}
