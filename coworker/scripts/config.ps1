$configDataPath = Join-Path $PSScriptRoot 'config.psd1'
if (-not (Test-Path $configDataPath)) {
    throw "Config data file not found: $configDataPath"
}

$script:configData = Import-PowerShellDataFile -Path $configDataPath
if (-not $script:configData.ContainsKey('COPILOT')) {
    throw "COPILOT is not defined in $configDataPath"
}

function Get-CoworkerConfigValue {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Map,
        [Parameter(Mandatory = $true)]
        [string]$Key,
        $DefaultValue = $null
    )

    if ($Map -is [System.Collections.IDictionary] -and $Map.Contains($Key)) {
        return $Map[$Key]
    }

    return $DefaultValue
}

function Resolve-CoworkerConfiguredPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [string]$BaseDirectory = $PSScriptRoot
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        throw 'Configured path cannot be empty.'
    }

    if ([System.IO.Path]::IsPathRooted($Path)) {
        return [System.IO.Path]::GetFullPath($Path)
    }

    return [System.IO.Path]::GetFullPath((Join-Path $BaseDirectory $Path))
}

function Get-CoworkerConfigData {
    return $script:configData
}

function Get-WorkspaceRoot {
    $pathsConfig = Get-CoworkerConfigValue -Map $script:configData -Key 'Paths' -DefaultValue @{}
    $path = [string](Get-CoworkerConfigValue -Map $pathsConfig -Key 'WorkspaceRoot' -DefaultValue '..\..')
    return Resolve-CoworkerConfiguredPath -Path $path
}

function Get-TargetRepositoryRoot {
    $pathsConfig = Get-CoworkerConfigValue -Map $script:configData -Key 'Paths' -DefaultValue @{}
    $configuredPath = Get-CoworkerConfigValue -Map $pathsConfig -Key 'TargetRepositoryRoot' -DefaultValue $null

    if ($null -eq $configuredPath -or [string]::IsNullOrWhiteSpace([string]$configuredPath)) {
        return Get-WorkspaceRoot
    }

    $resolvedPath = Resolve-CoworkerConfiguredPath -Path ([string]$configuredPath)
    if (-not (Test-Path -LiteralPath $resolvedPath -PathType Container)) {
        throw "Configured target repository root does not exist: $resolvedPath"
    }

    return $resolvedPath
}

function Get-CoworkerRoot {
    $pathsConfig = Get-CoworkerConfigValue -Map $script:configData -Key 'Paths' -DefaultValue @{}
    $path = [string](Get-CoworkerConfigValue -Map $pathsConfig -Key 'CoworkerRoot' -DefaultValue '..')
    return Resolve-CoworkerConfiguredPath -Path $path
}

function Get-TasksRoot {
    $pathsConfig = Get-CoworkerConfigValue -Map $script:configData -Key 'Paths' -DefaultValue @{}
    $path = [string](Get-CoworkerConfigValue -Map $pathsConfig -Key 'TasksRoot' -DefaultValue '..\tasks')
    return Resolve-CoworkerConfiguredPath -Path $path
}

function Get-SchedulerWorkingDirectory {
    $schedulerConfig = Get-CoworkerConfigValue -Map $script:configData -Key 'Scheduler' -DefaultValue @{}
    $path = [string](Get-CoworkerConfigValue -Map $schedulerConfig -Key 'WorkingDirectory' -DefaultValue '..\..')
    return Resolve-CoworkerConfiguredPath -Path $path
}

function Resolve-WorkspacePath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RelativePath
    )

    return Resolve-CoworkerConfiguredPath -Path $RelativePath -BaseDirectory (Get-WorkspaceRoot)
}

function Resolve-CoworkerPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RelativePath
    )

    return Resolve-CoworkerConfiguredPath -Path $RelativePath -BaseDirectory (Get-CoworkerRoot)
}

function Resolve-TasksPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RelativePath
    )

    return Resolve-CoworkerConfiguredPath -Path $RelativePath -BaseDirectory (Get-TasksRoot)
}

function Ensure-CoworkerDirectory {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function Write-CoworkerLog {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        [ValidateSet('DEBUG', 'INFO', 'WARN', 'ERROR')]
        [string]$Level = 'INFO',
        [string]$Component = 'coworker'
    )

    $timestamp = (Get-Date).ToUniversalTime().ToString('o')
    $formattedMessage = "[{0}] [{1}] [{2}] {3}" -f $timestamp, $Level, $Component, $Message
    $color = switch ($Level) {
        'DEBUG' { 'DarkGray' }
        'WARN' { 'Yellow' }
        'ERROR' { 'Red' }
        default { 'Gray' }
    }

    Write-Host $formattedMessage -ForegroundColor $color
}

function Remove-CoworkerEventSubscription {
    param(
        [string[]]$SourceIdentifiers = @()
    )

    foreach ($sourceIdentifier in @($SourceIdentifiers)) {
        if ([string]::IsNullOrWhiteSpace($sourceIdentifier)) {
            continue
        }

        Unregister-Event -SourceIdentifier $sourceIdentifier -ErrorAction SilentlyContinue
        Get-Event -SourceIdentifier $sourceIdentifier -ErrorAction SilentlyContinue |
            Remove-Event -ErrorAction SilentlyContinue
    }
}

function New-CoworkerFileWatcher {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [string]$SourcePrefix = 'coworker'
    )

    $resolvedPath = [System.IO.Path]::GetFullPath($Path)
    $watchContainer = $true

    if (Test-Path -LiteralPath $resolvedPath) {
        $item = Get-Item -LiteralPath $resolvedPath
        $watchContainer = $item.PSIsContainer
    }
    elseif ([System.IO.Path]::HasExtension($resolvedPath)) {
        $watchContainer = $false
    }

    if ($watchContainer) {
        Ensure-CoworkerDirectory -Path $resolvedPath
        $watchDirectory = $resolvedPath
        $filter = '*'
        $includeSubdirectories = $true
    }
    else {
        $watchDirectory = Split-Path -Parent $resolvedPath
        if ([string]::IsNullOrWhiteSpace($watchDirectory)) {
            throw "Cannot determine watcher directory for path: $resolvedPath"
        }

        Ensure-CoworkerDirectory -Path $watchDirectory
        $filter = Split-Path -Leaf $resolvedPath
        $includeSubdirectories = $false
    }

    $watcher = [System.IO.FileSystemWatcher]::new($watchDirectory, $filter)
    $watcher.IncludeSubdirectories = $includeSubdirectories
    $watcher.NotifyFilter = [System.IO.NotifyFilters]'FileName, DirectoryName, LastWrite, CreationTime'

    $sourceIdentifiers = @()
    foreach ($eventName in @('Created', 'Changed', 'Deleted', 'Renamed')) {
        $sourceIdentifier = 'coworker.{0}.{1}.{2}' -f $SourcePrefix, $eventName.ToLowerInvariant(), ([guid]::NewGuid().ToString('N'))
        Register-ObjectEvent -InputObject $watcher -EventName $eventName -SourceIdentifier $sourceIdentifier | Out-Null
        $sourceIdentifiers += $sourceIdentifier
    }

    $watcher.EnableRaisingEvents = $true

    return [pscustomobject]@{
        Path              = $resolvedPath
        Directory         = $watchDirectory
        Filter            = $filter
        Watcher           = $watcher
        SourceIdentifiers = $sourceIdentifiers
    }
}

function Remove-CoworkerFileWatcher {
    param(
        [Parameter(Mandatory = $true)]
        [psobject]$Registration
    )

    Remove-CoworkerEventSubscription -SourceIdentifiers $Registration.SourceIdentifiers
    if ($null -ne $Registration.Watcher) {
        $Registration.Watcher.EnableRaisingEvents = $false
        $Registration.Watcher.Dispose()
    }
}

$COPILOT = @($script:configData['COPILOT'])
