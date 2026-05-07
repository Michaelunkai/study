param(
    [string[]]$UserIds,
    [switch]$Quiet
)

$ErrorActionPreference = "Stop"
. 'F:\study\AI_ML\AI_and_Machine_Learning\Artificial_Intelligence\openclaw\scripts\Resolve-OpenClawPaths.ps1'
$paths = Get-OpenClawPaths

$authorityCheck = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $paths.RepoRoot 'scripts\Test-OpenClawAuthority.ps1') -Json | ConvertFrom-Json
if (-not $authorityCheck.passed) {
    $failed = @($authorityCheck.checks | Where-Object { -not $_.passed } | ForEach-Object { $_.name })
    throw "OpenClaw authority drift blocks route repair: $($failed -join ', ')"
}

$agentMaps = @(
    @{ agentId = "main"; accountId = "bot1" },
    @{ agentId = "session2"; accountId = "bot2" },
    @{ agentId = "openclaw"; accountId = "openclaw" },
    @{ agentId = "openclaw4"; accountId = "openclaw4" }
)

function Save-Json {
    param(
        [Parameter(Mandatory = $true)]$Object,
        [Parameter(Mandatory = $true)][string]$Path
    )

    $parent = Split-Path -Parent $Path
    if ($parent) {
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
    }

    $json = $Object | ConvertTo-Json -Depth 100
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $json, $utf8NoBom)
}

function Read-JsonFile {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path $Path)) {
        return $null
    }

    $raw = Get-Content -Raw $Path
    if ([string]::IsNullOrWhiteSpace($raw)) {
        return $null
    }

    return $raw | ConvertFrom-Json
}

function Normalize-String {
    param([AllowNull()][string]$Value)

    if ($null -eq $Value) {
        return $null
    }

    $trimmed = $Value.Trim()
    if ([string]::IsNullOrWhiteSpace($trimmed)) {
        return $null
    }

    return $trimmed
}

function Get-LongOrDefault {
    param(
        $Value,
        [long]$Default = 0
    )

    if ($null -eq $Value) {
        return $Default
    }

    try {
        return [long]$Value
    } catch {
        return $Default
    }
}

function Set-ObjectProperty {
    param(
        [Parameter(Mandatory = $true)]$Object,
        [Parameter(Mandatory = $true)][string]$Name,
        $Value
    )

    if ($Object.PSObject.Properties.Name -contains $Name) {
        $Object.$Name = $Value
        return
    }

    $Object | Add-Member -NotePropertyName $Name -NotePropertyValue $Value
}

function Get-OptionalPropertyValue {
    param(
        [Parameter(Mandatory = $true)]$Object,
        [Parameter(Mandatory = $true)][string]$Name
    )

    if ($null -eq $Object) {
        return $null
    }

    if ($Object.PSObject.Properties.Name -contains $Name) {
        return $Object.$Name
    }

    return $null
}

function Add-RouteCandidate {
    param(
        [Parameter(Mandatory = $true)]$Table,
        [Parameter(Mandatory = $true)][string]$UserId,
        [Parameter(Mandatory = $true)]$Candidate
    )

    $normalizedUserId = Normalize-String $UserId
    if ([string]::IsNullOrWhiteSpace($normalizedUserId)) {
        return
    }

    $existing = $Table[$normalizedUserId]
    $candidateLabel = Normalize-String (Get-OptionalPropertyValue -Object $Candidate -Name 'label')
    $candidateName = Normalize-String (Get-OptionalPropertyValue -Object $Candidate -Name 'name')
    $candidateUsername = Normalize-String (Get-OptionalPropertyValue -Object $Candidate -Name 'username')
    $candidateUpdatedAt = Get-LongOrDefault -Value (Get-OptionalPropertyValue -Object $Candidate -Name 'updatedAt')
    if ($null -eq $existing) {
        $Table[$normalizedUserId] = [ordered]@{
            userId = $normalizedUserId
            label = $candidateLabel
            name = $candidateName
            username = $candidateUsername
            updatedAt = $candidateUpdatedAt
        }
        return
    }

    if (-not $existing.label -and $candidateLabel) {
        $existing.label = $candidateLabel
    }
    if (-not $existing.name -and $candidateName) {
        $existing.name = $candidateName
    }
    if (-not $existing.username -and $candidateUsername) {
        $existing.username = $candidateUsername
    }

    if ($candidateUpdatedAt -gt (Get-LongOrDefault -Value $existing.updatedAt)) {
        $existing.updatedAt = $candidateUpdatedAt
    }
}

function Parse-Label {
    param([AllowNull()][string]$Label)

    $result = [ordered]@{
        name = $null
        username = $null
    }

    $normalized = Normalize-String $Label
    if (-not $normalized) {
        return [pscustomobject]$result
    }

    if ($normalized -match '^(?<name>.+?) \(@(?<username>[^)]+)\) id:\d+$') {
        $result.name = $Matches.name.Trim()
        $result.username = $Matches.username.Trim()
        return [pscustomobject]$result
    }

    if ($normalized -match '^(?<name>.+?) \(\d+\)$') {
        $result.name = $Matches.name.Trim()
        return [pscustomobject]$result
    }

    return [pscustomobject]$result
}

function Get-RegistryCandidates {
    param([Parameter(Mandatory = $true)][string]$RegistryPath)

    $table = @{}
    $registry = Read-JsonFile -Path $RegistryPath
    if ($null -eq $registry) {
        return $table
    }

    foreach ($item in @($registry.routes)) {
        $userId = Normalize-String $item.userId
        if (-not $userId) {
            continue
        }
        Add-RouteCandidate -Table $table -UserId $userId -Candidate $item
    }

    return $table
}

function Get-StoreCandidates {
    param(
        [Parameter(Mandatory = $true)]$Paths,
        [Parameter(Mandatory = $true)]$AgentMaps
    )

    $table = @{}

    foreach ($map in $AgentMaps) {
        $storePath = Join-Path $Paths.AgentsRoot "$($map.agentId)\sessions\sessions.json"
        $store = Read-JsonFile -Path $storePath
        if ($null -eq $store) {
            continue
        }

        foreach ($property in $store.PSObject.Properties) {
            if ($property.Name -notmatch "^agent:$([regex]::Escape($map.agentId)):telegram:[^:]+:direct:(?<userId>\d+)$") {
                continue
            }

            $entry = $property.Value
            $origin = Get-OptionalPropertyValue -Object $entry -Name 'origin'
            if ($null -eq $origin) {
                continue
            }
            $parsedLabel = Parse-Label -Label (Get-OptionalPropertyValue -Object $origin -Name 'label')
            $candidateName = Normalize-String (Get-OptionalPropertyValue -Object $origin -Name 'name')
            if (-not $candidateName) {
                $candidateName = Normalize-String $parsedLabel.name
            }
            $candidateUsername = Normalize-String (Get-OptionalPropertyValue -Object $origin -Name 'username')
            if (-not $candidateUsername) {
                $candidateUsername = Normalize-String $parsedLabel.username
            }
            Add-RouteCandidate -Table $table -UserId $Matches.userId -Candidate ([ordered]@{
                label = Get-OptionalPropertyValue -Object $origin -Name 'label'
                name = $candidateName
                username = $candidateUsername
                updatedAt = Get-OptionalPropertyValue -Object $entry -Name 'updatedAt'
            })
        }
    }

    return $table
}

function Merge-CandidateTables {
    param(
        [Parameter(Mandatory = $true)]$Base,
        [Parameter(Mandatory = $true)]$Incoming
    )

    foreach ($key in $Incoming.Keys) {
        Add-RouteCandidate -Table $Base -UserId $key -Candidate $Incoming[$key]
    }
}

function Get-ExplicitCandidates {
    param([string[]]$Ids)

    $table = @{}
    foreach ($userId in @($Ids)) {
        $normalizedUserId = Normalize-String $userId
        if (-not $normalizedUserId) {
            continue
        }

        Add-RouteCandidate -Table $table -UserId $normalizedUserId -Candidate ([ordered]@{
            label = $null
            name = $null
            username = $null
            updatedAt = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
        })
    }

    return $table
}

function New-TelegramDirectSessionEntry {
    param(
        [Parameter(Mandatory = $true)]$Route,
        [Parameter(Mandatory = $true)][string]$AccountId
    )

    $nowMs = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
    $label = Normalize-String $Route.label
    if (-not $label) {
        if ($Route.name -and $Route.username) {
            $label = "$($Route.name) (@$($Route.username)) id:$($Route.userId)"
        } elseif ($Route.name) {
            $label = "$($Route.name) ($($Route.userId))"
        } else {
            $label = "telegram user $($Route.userId)"
        }
    }

    $origin = [ordered]@{
        label = $label
        provider = "telegram"
        surface = "telegram"
        chatType = "direct"
        from = "telegram:$($Route.userId)"
        to = "telegram:$($Route.userId)"
        nativeDirectUserId = [string]$Route.userId
        accountId = $AccountId
    }

    [ordered]@{
        origin = $origin
        sessionId = [guid]::NewGuid().ToString()
        updatedAt = $nowMs
        deliveryContext = [ordered]@{
            channel = "telegram"
            to = "telegram:$($Route.userId)"
            accountId = $AccountId
        }
        lastChannel = "telegram"
        lastTo = "telegram:$($Route.userId)"
        lastAccountId = $AccountId
        systemSent = $true
        abortedLastRun = $false
        chatType = "direct"
    }
}

function Repair-AgentRoutes {
    param(
        [Parameter(Mandatory = $true)]$Paths,
        [Parameter(Mandatory = $true)]$AgentMap,
        [Parameter(Mandatory = $true)]$Routes
    )

    $storePath = Join-Path $Paths.AgentsRoot "$($AgentMap.agentId)\sessions\sessions.json"
    $store = Read-JsonFile -Path $storePath
    if ($null -eq $store) {
        $store = [pscustomobject]@{}
    }

    $created = New-Object System.Collections.ArrayList
    $patched = New-Object System.Collections.ArrayList
    $mainEntry = Get-OptionalPropertyValue -Object $store -Name ("agent:{0}:main" -f $AgentMap.agentId)

    foreach ($route in $Routes) {
        $directKey = "agent:$($AgentMap.agentId):telegram:$($AgentMap.accountId):direct:$($route.userId)"
        $existing = Get-OptionalPropertyValue -Object $store -Name $directKey
        if ($null -eq $existing) {
            $store | Add-Member -NotePropertyName $directKey -NotePropertyValue (New-TelegramDirectSessionEntry -Route $route -AccountId $AgentMap.accountId)
            [void]$created.Add($directKey)
            continue
        }

        $needsPatch = $false
        $existingDeliveryContext = Get-OptionalPropertyValue -Object $existing -Name 'deliveryContext'
        if (-not $existingDeliveryContext -or -not (Get-OptionalPropertyValue -Object $existingDeliveryContext -Name 'channel') -or -not (Get-OptionalPropertyValue -Object $existingDeliveryContext -Name 'to')) {
            Set-ObjectProperty -Object $existing -Name "deliveryContext" -Value ([ordered]@{
                channel = "telegram"
                to = "telegram:$($route.userId)"
                accountId = $AgentMap.accountId
            })
            $needsPatch = $true
        }
        if (-not (Get-OptionalPropertyValue -Object $existing -Name 'lastChannel')) {
            Set-ObjectProperty -Object $existing -Name "lastChannel" -Value "telegram"
            $needsPatch = $true
        }
        if (-not (Get-OptionalPropertyValue -Object $existing -Name 'lastTo')) {
            Set-ObjectProperty -Object $existing -Name "lastTo" -Value "telegram:$($route.userId)"
            $needsPatch = $true
        }
        if (-not (Get-OptionalPropertyValue -Object $existing -Name 'lastAccountId')) {
            Set-ObjectProperty -Object $existing -Name "lastAccountId" -Value $AgentMap.accountId
            $needsPatch = $true
        }
        if (-not (Get-OptionalPropertyValue -Object $existing -Name 'chatType')) {
            Set-ObjectProperty -Object $existing -Name "chatType" -Value "direct"
            $needsPatch = $true
        }
        $existingOrigin = Get-OptionalPropertyValue -Object $existing -Name 'origin'
        if (-not $existingOrigin) {
            Set-ObjectProperty -Object $existing -Name "origin" -Value ([ordered]@{
                provider = "telegram"
                surface = "telegram"
                chatType = "direct"
                from = "telegram:$($route.userId)"
                to = "telegram:$($route.userId)"
                nativeDirectUserId = [string]$route.userId
                accountId = $AgentMap.accountId
            })
            $needsPatch = $true
        } else {
            if (-not (Get-OptionalPropertyValue -Object $existingOrigin -Name 'provider')) {
                Set-ObjectProperty -Object $existingOrigin -Name "provider" -Value "telegram"
                $needsPatch = $true
            }
            if (-not (Get-OptionalPropertyValue -Object $existingOrigin -Name 'surface')) {
                Set-ObjectProperty -Object $existingOrigin -Name "surface" -Value "telegram"
                $needsPatch = $true
            }
            if (-not (Get-OptionalPropertyValue -Object $existingOrigin -Name 'chatType')) {
                Set-ObjectProperty -Object $existingOrigin -Name "chatType" -Value "direct"
                $needsPatch = $true
            }
            if (-not (Get-OptionalPropertyValue -Object $existingOrigin -Name 'from')) {
                Set-ObjectProperty -Object $existingOrigin -Name "from" -Value "telegram:$($route.userId)"
                $needsPatch = $true
            }
            if (-not (Get-OptionalPropertyValue -Object $existingOrigin -Name 'to')) {
                Set-ObjectProperty -Object $existingOrigin -Name "to" -Value "telegram:$($route.userId)"
                $needsPatch = $true
            }
            if (-not (Get-OptionalPropertyValue -Object $existingOrigin -Name 'nativeDirectUserId')) {
                Set-ObjectProperty -Object $existingOrigin -Name "nativeDirectUserId" -Value ([string]$route.userId)
                $needsPatch = $true
            }
            if (-not (Get-OptionalPropertyValue -Object $existingOrigin -Name 'accountId')) {
                Set-ObjectProperty -Object $existingOrigin -Name "accountId" -Value $AgentMap.accountId
                $needsPatch = $true
            }
            if (-not (Get-OptionalPropertyValue -Object $existingOrigin -Name 'label') -and $route.label) {
                Set-ObjectProperty -Object $existingOrigin -Name "label" -Value $route.label
                $needsPatch = $true
            }
        }
        if (-not (Get-OptionalPropertyValue -Object $existing -Name 'updatedAt')) {
            Set-ObjectProperty -Object $existing -Name "updatedAt" -Value ([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds())
            $needsPatch = $true
        }
        if (-not (Get-OptionalPropertyValue -Object $existing -Name 'sessionId')) {
            Set-ObjectProperty -Object $existing -Name "sessionId" -Value ([guid]::NewGuid().ToString())
            $needsPatch = $true
        }
        if ($needsPatch) {
            [void]$patched.Add($directKey)
        }
    }

    Save-Json -Object $store -Path $storePath
    Register-OpenClawManagedFile -Path $storePath -Kind 'telegram-session-store' -Source $AgentMap.agentId -GeneratedBy 'Repair-OpenClawTelegramRoutes.ps1'

    [pscustomobject]@{
        agentId = $AgentMap.agentId
        accountId = $AgentMap.accountId
        storePath = $storePath
        mainSessionKey = "agent:$($AgentMap.agentId):main"
        mainHasRoute = [bool]($mainEntry -and (((Get-OptionalPropertyValue -Object (Get-OptionalPropertyValue -Object $mainEntry -Name 'deliveryContext') -Name 'channel') -and (Get-OptionalPropertyValue -Object (Get-OptionalPropertyValue -Object $mainEntry -Name 'deliveryContext') -Name 'to')) -or ((Get-OptionalPropertyValue -Object $mainEntry -Name 'lastChannel') -and (Get-OptionalPropertyValue -Object $mainEntry -Name 'lastTo'))))
        created = @($created)
        patched = @($patched)
    }
}

$routeTable = @{}
Merge-CandidateTables -Base $routeTable -Incoming (Get-RegistryCandidates -RegistryPath $paths.RouteRegistryPath)
Merge-CandidateTables -Base $routeTable -Incoming (Get-StoreCandidates -Paths $paths -AgentMaps $agentMaps)
Merge-CandidateTables -Base $routeTable -Incoming (Get-ExplicitCandidates -Ids $UserIds)

$routes = @($routeTable.Values | Sort-Object updatedAt, userId -Descending)
$results = @()

if ($routes.Count -gt 0) {
    foreach ($map in $agentMaps) {
        $results += Repair-AgentRoutes -Paths $paths -AgentMap $map -Routes $routes
    }
}

$registryPayload = [pscustomobject]@{
    generatedAt = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
    routes = @(
        foreach ($route in $routes) {
            foreach ($map in $agentMaps) {
                [pscustomobject]@{
                    channel = 'telegram'
                    accountId = $map.accountId
                    agentId = $map.agentId
                    userId = $route.userId
                    label = $route.label
                    name = $route.name
                    username = $route.username
                    updatedAt = $route.updatedAt
                }
            }
        }
    )
}
Save-OpenClawManagedJsonFile -Object $registryPayload -Path $paths.RouteRegistryPath -Kind 'route-registry' -Source 'Repair-OpenClawTelegramRoutes.ps1'

$summary = [pscustomobject]@{
    routeCount = $routes.Count
    registryPath = $paths.RouteRegistryPath
    results = $results
}

if (-not $Quiet) {
    $summary | ConvertTo-Json -Depth 12
}
