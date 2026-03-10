#!/usr/bin/env pwsh

param(
    [string]$ConfigPath,
    [switch]$Once
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$configScriptPath = Join-Path $PSScriptRoot 'config.ps1'
. $configScriptPath

# Import common utility script
$utilScriptPath = Join-Path $PSScriptRoot 'Util.ps1'
. $configScriptPath

Fix-Encoding-UTF8

function Resolve-SchedulerPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [string]$WorkspaceRoot,
        [Parameter(Mandatory = $true)]
        [string]$ConfigDirectory
    )

    if ([System.IO.Path]::IsPathRooted($Path)) {
        return [System.IO.Path]::GetFullPath($Path)
    }

    $configRelativePath = Join-Path $ConfigDirectory $Path
    if (Test-Path -LiteralPath $configRelativePath) {
        return (Resolve-Path -LiteralPath $configRelativePath).Path
    }

    return [System.IO.Path]::GetFullPath((Join-Path $WorkspaceRoot $Path))
}

function Test-PathHasPendingFiles {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return $false
    }

    $item = Get-Item -LiteralPath $Path -ErrorAction SilentlyContinue
    if ($null -eq $item) {
        return $false
    }

    if (-not $item.PSIsContainer) {
        return $true
    }

    $pendingFile = Get-ChildItem -LiteralPath $item.FullName -File -Recurse -ErrorAction SilentlyContinue |
        Select-Object -First 1
    return $null -ne $pendingFile
}

function Get-TaskSnapshot {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$TaskState
    )

    return [pscustomobject]@{
        Name                = $TaskState.Name
        Description         = $TaskState.Description
        Enabled             = $TaskState.Enabled
        IntervalSeconds     = $TaskState.IntervalSeconds
        DependsOn           = @($TaskState.DependsOn)
        PendingPaths        = @($TaskState.PendingPaths)
        ScriptPath          = $TaskState.ScriptPath
        Arguments           = @($TaskState.Arguments)
        Status              = $TaskState.Status
        LastStartedUtc      = $TaskState.LastStartedUtc
        LastFinishedUtc     = $TaskState.LastFinishedUtc
        LastExitCode        = $TaskState.LastExitCode
        LastDurationSeconds = $TaskState.LastDurationSeconds
        CurrentPid          = $TaskState.CurrentPid
        NextRunUtc          = $TaskState.NextRunUtc
        StdOutLogPath       = $TaskState.StdOutLogPath
        StdErrLogPath       = $TaskState.StdErrLogPath
        RunCount            = $TaskState.RunCount
    }
}

function Write-SchedulerStatus {
    param(
        [Parameter(Mandatory = $true)]
        [string]$StatusFile,
        [Parameter(Mandatory = $true)]
        [string]$ConfigPath,
        [Parameter(Mandatory = $true)]
        [int]$TickSeconds,
        [Parameter(Mandatory = $true)]
        [hashtable]$TaskStates
    )

    $statusDocument = [pscustomobject]@{
        GeneratedAtUtc = (Get-Date).ToUniversalTime().ToString('o')
        ConfigPath     = $ConfigPath
        TickSeconds    = $TickSeconds
        Tasks          = @($TaskStates.Values | Sort-Object Name | ForEach-Object { Get-TaskSnapshot -TaskState $_ })
    }

    $statusDocument | ConvertTo-Json -Depth 8 | Set-Content -Path $StatusFile -Encoding UTF8
}

function Register-ScheduledTaskProcessExitEvent {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$TaskState,
        [Parameter(Mandatory = $true)]
        [System.Diagnostics.Process]$Process
    )

    if (-not $Process.EnableRaisingEvents) {
        $Process.EnableRaisingEvents = $true
    }

    if (-not [string]::IsNullOrWhiteSpace($TaskState.ProcessExitSourceIdentifier)) {
        Remove-CoworkerEventSubscription -SourceIdentifiers @($TaskState.ProcessExitSourceIdentifier)
    }

    $sourceIdentifier = 'coworker.scheduler.process.{0}.{1}' -f $TaskState.Name, $Process.Id
    Register-ObjectEvent -InputObject $Process -EventName Exited -SourceIdentifier $sourceIdentifier | Out-Null
    $TaskState.ProcessExitSourceIdentifier = $sourceIdentifier
}

function Clear-ScheduledTaskProcessExitEvent {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$TaskState
    )

    if (-not [string]::IsNullOrWhiteSpace($TaskState.ProcessExitSourceIdentifier)) {
        Remove-CoworkerEventSubscription -SourceIdentifiers @($TaskState.ProcessExitSourceIdentifier)
        $TaskState.ProcessExitSourceIdentifier = $null
    }
}

function Start-ScheduledTaskRun {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$TaskState,
        [Parameter(Mandatory = $true)]
        [string]$PowerShellExecutable,
        [Parameter(Mandatory = $true)]
        [string]$WorkingDirectory,
        [Parameter(Mandatory = $true)]
        [string]$LogDirectory
    )

    $startTime = (Get-Date).ToUniversalTime()
    $dateFolder = Join-Path $LogDirectory $startTime.ToString('yyyy\\MM\\dd')
    Ensure-CoworkerDirectory -Path $dateFolder

    $timestamp = $startTime.ToString('HHmmss')
    $stdOutPath = Join-Path $dateFolder "$timestamp-$($TaskState.Name).stdout.log"
    $stdErrPath = Join-Path $dateFolder "$timestamp-$($TaskState.Name).stderr.log"
    $argumentList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $TaskState.ScriptPath) + @($TaskState.Arguments)

    $process = Start-Process -FilePath $PowerShellExecutable `
        -ArgumentList $argumentList `
        -WorkingDirectory $WorkingDirectory `
        -RedirectStandardOutput $stdOutPath `
        -RedirectStandardError $stdErrPath `
        -PassThru

    Register-ScheduledTaskProcessExitEvent -TaskState $TaskState -Process $process

    $TaskState.Process = $process
    $TaskState.Status = 'Running'
    $TaskState.CurrentPid = $process.Id
    $TaskState.LastStartedUtc = $startTime.ToString('o')
    $TaskState.NextRunUtc = $startTime.AddSeconds($TaskState.IntervalSeconds).ToString('o')
    $TaskState.StdOutLogPath = $stdOutPath
    $TaskState.StdErrLogPath = $stdErrPath
    $TaskState.RunCount = $TaskState.RunCount + 1

    Write-CoworkerLog -Component 'scheduler' -Message ("Started {0} (PID {1})" -f $TaskState.Name, $process.Id)
}

function Update-ScheduledTaskRun {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$TaskState
    )

    if ($null -eq $TaskState.Process) {
        return
    }

    $TaskState.Process.Refresh()
    if (-not $TaskState.Process.HasExited) {
        return
    }

    $finishedAt = (Get-Date).ToUniversalTime()
    $startedAt = [DateTimeOffset]::Parse($TaskState.LastStartedUtc)
    $TaskState.LastFinishedUtc = $finishedAt.ToString('o')
    $TaskState.LastExitCode = $TaskState.Process.ExitCode
    $TaskState.LastDurationSeconds = [Math]::Round(($finishedAt - $startedAt.UtcDateTime).TotalSeconds, 2)
    $TaskState.Status = if ($TaskState.Process.ExitCode -eq 0) { 'Idle' } else { 'Failed' }
    $TaskState.CurrentPid = $null
    $TaskState.Process = $null
    Clear-ScheduledTaskProcessExitEvent -TaskState $TaskState

    $level = if ($TaskState.LastExitCode -eq 0) { 'INFO' } else { 'ERROR' }
    Write-CoworkerLog -Component 'scheduler' -Level $level -Message ("Finished {0} with exit code {1}" -f $TaskState.Name, $TaskState.LastExitCode)
}

function Test-ScheduledTaskHasPendingInputs {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$TaskState
    )

    $pendingPaths = @($TaskState.PendingPaths)
    if ($pendingPaths.Count -eq 0) {
        return $true
    }

    foreach ($pendingPath in $pendingPaths) {
        if (Test-PathHasPendingFiles -Path $pendingPath) {
            return $true
        }
    }

    return $false
}

function Set-ScheduledTaskWaitingForWork {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$TaskState,
        [Parameter(Mandatory = $true)]
        [datetime]$Now
    )

    $TaskState.Status = 'WaitingForWork'
    $TaskState.NextRunUtc = $Now.AddSeconds($TaskState.IntervalSeconds).ToString('o')
}

function Test-ScheduledTaskCanStart {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$TaskState,
        [Parameter(Mandatory = $true)]
        [hashtable]$TaskStates,
        [Parameter(Mandatory = $true)]
        [datetime]$Now,
        [switch]$OnceMode
    )

    if (-not $TaskState.Enabled -or $null -ne $TaskState.Process) {
        return $false
    }

    if ($OnceMode -and $TaskState.RunCount -gt 0) {
        return $false
    }

    $nextRunUtc = $TaskState.NextRunUtc
    if (-not [string]::IsNullOrWhiteSpace($nextRunUtc)) {
        $nextRunAt = [DateTimeOffset]::Parse($nextRunUtc)
        if ($Now -lt $nextRunAt.UtcDateTime) {
            return $false
        }
    }

    foreach ($dependencyName in @($TaskState.DependsOn)) {
        if (-not $TaskStates.ContainsKey($dependencyName)) {
            throw "Scheduled task '$($TaskState.Name)' depends on unknown task '$dependencyName'."
        }

        $dependencyState = $TaskStates[$dependencyName]
        if ($dependencyState.Enabled -and $null -ne $dependencyState.Process) {
            return $false
        }

        $dependencyNextRunUtc = $dependencyState.NextRunUtc
        if (-not [string]::IsNullOrWhiteSpace($dependencyNextRunUtc)) {
            $dependencyNextRunAt = [DateTimeOffset]::Parse($dependencyNextRunUtc)
            if ($dependencyState.Enabled -and $Now -ge $dependencyNextRunAt.UtcDateTime) {
                return $false
            }
        }

        if ($OnceMode -and $dependencyState.Enabled -and $dependencyState.RunCount -eq 0) {
            return $false
        }
    }

    return $true
}

function Register-SchedulerPendingPathWatchers {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$TaskStates
    )

    $registrations = @()
    $uniquePaths = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)

    foreach ($taskState in $TaskStates.Values) {
        foreach ($pendingPath in @($taskState.PendingPaths)) {
            if ([string]::IsNullOrWhiteSpace($pendingPath)) {
                continue
            }

            if ($uniquePaths.Add($pendingPath)) {
                $registrations += New-CoworkerFileWatcher -Path $pendingPath -SourcePrefix ("scheduler.$($taskState.Name)")
            }
        }
    }

    return @($registrations)
}

function Clear-SchedulerQueuedEvents {
    while ($true) {
        $queuedEvent = Wait-Event -Timeout 0
        if ($null -eq $queuedEvent) {
            break
        }

        Remove-Event -EventIdentifier $queuedEvent.EventIdentifier -ErrorAction SilentlyContinue
    }
}

function Invoke-SchedulerPass {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$TaskStates,
        [Parameter(Mandatory = $true)]
        [string]$PowerShellExecutable,
        [Parameter(Mandatory = $true)]
        [string]$WorkingDirectory,
        [Parameter(Mandatory = $true)]
        [string]$LogDirectory,
        [Parameter(Mandatory = $true)]
        [string]$StatusFile,
        [Parameter(Mandatory = $true)]
        [string]$ResolvedConfigPath,
        [Parameter(Mandatory = $true)]
        [int]$TickSeconds,
        [switch]$OnceMode
    )

    $now = (Get-Date).ToUniversalTime()
    $runningCount = 0

    foreach ($taskState in $TaskStates.Values) {
        if (-not $taskState.Enabled) {
            $taskState.Status = 'Disabled'
            continue
        }

        Update-ScheduledTaskRun -TaskState $taskState
        if ($null -ne $taskState.Process) {
            $runningCount++
        }
    }

    foreach ($taskState in $TaskStates.Values | Sort-Object Name) {
        if (-not $taskState.Enabled -or $null -ne $taskState.Process) {
            continue
        }

        if (Test-ScheduledTaskCanStart -TaskState $taskState -TaskStates $TaskStates -Now $now -OnceMode:$OnceMode) {
            if (Test-ScheduledTaskHasPendingInputs -TaskState $taskState) {
                Start-ScheduledTaskRun -TaskState $taskState -PowerShellExecutable $PowerShellExecutable -WorkingDirectory $WorkingDirectory -LogDirectory $LogDirectory
                $runningCount++
            }
            else {
                Set-ScheduledTaskWaitingForWork -TaskState $taskState -Now $now
            }
        }
    }

    Write-SchedulerStatus -StatusFile $StatusFile -ConfigPath $ResolvedConfigPath -TickSeconds $TickSeconds -TaskStates $TaskStates

    return [pscustomobject]@{
        RunningCount = $runningCount
    }
}

$workspaceRoot = Get-WorkspaceRoot
if ([string]::IsNullOrWhiteSpace($ConfigPath)) {
    $ConfigPath = Join-Path $PSScriptRoot 'coworker-scheduler.config.psd1'
}

$resolvedConfigPath = Resolve-SchedulerPath -Path $ConfigPath -WorkspaceRoot $workspaceRoot -ConfigDirectory $PSScriptRoot
if (-not (Test-Path -LiteralPath $resolvedConfigPath)) {
    throw "Scheduler config not found: $resolvedConfigPath"
}

$config = Import-PowerShellDataFile -Path $resolvedConfigPath
if (-not $config.Tasks) {
    throw "Scheduler config must define a Tasks array: $resolvedConfigPath"
}

$schedulerConfig = Get-CoworkerConfigValue -Map $config -Key 'Scheduler' -DefaultValue @{}
$tickSeconds = [int](Get-CoworkerConfigValue -Map $schedulerConfig -Key 'TickSeconds' -DefaultValue 5)
$powerShellExecutable = [string](Get-CoworkerConfigValue -Map $schedulerConfig -Key 'PowerShellExecutable' -DefaultValue 'pwsh')
$workingDirectory = Resolve-SchedulerPath -Path ([string](Get-CoworkerConfigValue -Map $schedulerConfig -Key 'WorkingDirectory' -DefaultValue (Get-SchedulerWorkingDirectory))) -WorkspaceRoot $workspaceRoot -ConfigDirectory (Split-Path -Parent $resolvedConfigPath)
$logDirectory = Resolve-SchedulerPath -Path ([string](Get-CoworkerConfigValue -Map $schedulerConfig -Key 'LogDirectory' -DefaultValue 'coworker\tasks\300logs\scheduler')) -WorkspaceRoot $workspaceRoot -ConfigDirectory (Split-Path -Parent $resolvedConfigPath)
$statusFile = Resolve-SchedulerPath -Path ([string](Get-CoworkerConfigValue -Map $schedulerConfig -Key 'StatusFile' -DefaultValue 'logs\scheduled-tasks.status.json')) -WorkspaceRoot $workspaceRoot -ConfigDirectory (Split-Path -Parent $resolvedConfigPath)

Ensure-CoworkerDirectory -Path $logDirectory
Ensure-CoworkerDirectory -Path (Split-Path -Parent $statusFile)
Ensure-CoworkerDirectory -Path $workingDirectory

$taskStates = @{}
foreach ($task in $config.Tasks) {
    $taskName = [string](Get-CoworkerConfigValue -Map $task -Key 'Name' -DefaultValue '')
    if ([string]::IsNullOrWhiteSpace($taskName)) {
        throw 'Each scheduled task must define Name.'
    }

    $intervalSeconds = [int](Get-CoworkerConfigValue -Map $task -Key 'IntervalSeconds' -DefaultValue 0)
    if ($intervalSeconds -le 0) {
        throw "Scheduled task '$taskName' must define IntervalSeconds."
    }

    $scriptPath = [string](Get-CoworkerConfigValue -Map $task -Key 'ScriptPath' -DefaultValue '')
    if ([string]::IsNullOrWhiteSpace($scriptPath)) {
        throw "Scheduled task '$taskName' must define ScriptPath."
    }

    $resolvedScriptPath = Resolve-SchedulerPath -Path $scriptPath -WorkspaceRoot $workspaceRoot -ConfigDirectory (Split-Path -Parent $resolvedConfigPath)
    if (-not (Test-Path -LiteralPath $resolvedScriptPath)) {
        throw "Scheduled task '$taskName' script not found: $resolvedScriptPath"
    }

    $enabled = [bool](Get-CoworkerConfigValue -Map $task -Key 'Enabled' -DefaultValue $true)
    $dependsOn = @()
    $rawDependsOn = Get-CoworkerConfigValue -Map $task -Key 'DependsOn' -DefaultValue @()
    if ($null -ne $rawDependsOn) {
        $dependsOn = @($rawDependsOn | ForEach-Object { [string]$_ } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    }

    $pendingPaths = @()
    $rawPendingPaths = Get-CoworkerConfigValue -Map $task -Key 'PendingPaths' -DefaultValue @()
    if ($null -ne $rawPendingPaths) {
        $pendingPaths = @(
            $rawPendingPaths |
                ForEach-Object { [string]$_ } |
                Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
                ForEach-Object { Resolve-SchedulerPath -Path $_ -WorkspaceRoot $workspaceRoot -ConfigDirectory (Split-Path -Parent $resolvedConfigPath) }
        )
    }

    $taskStates[$taskName] = @{
        Name                        = $taskName
        Description                 = [string](Get-CoworkerConfigValue -Map $task -Key 'Description' -DefaultValue '')
        Enabled                     = $enabled
        IntervalSeconds             = $intervalSeconds
        DependsOn                   = $dependsOn
        PendingPaths                = $pendingPaths
        ScriptPath                  = $resolvedScriptPath
        Arguments                   = @((Get-CoworkerConfigValue -Map $task -Key 'Arguments' -DefaultValue @()))
        Status                      = if ($enabled) { 'Idle' } else { 'Disabled' }
        LastStartedUtc              = $null
        LastFinishedUtc             = $null
        LastExitCode                = $null
        LastDurationSeconds         = $null
        CurrentPid                  = $null
        NextRunUtc                  = (Get-Date).ToUniversalTime().ToString('o')
        StdOutLogPath               = $null
        StdErrLogPath               = $null
        RunCount                    = 0
        Process                     = $null
        ProcessExitSourceIdentifier = $null
    }
}

Write-CoworkerLog -Component 'scheduler' -Message "Loaded scheduler config: $resolvedConfigPath"
Write-CoworkerLog -Component 'scheduler' -Message "Task status file: $statusFile"

if ($Once) {
    do {
        $passResult = Invoke-SchedulerPass -TaskStates $taskStates -PowerShellExecutable $powerShellExecutable -WorkingDirectory $workingDirectory -LogDirectory $logDirectory -StatusFile $statusFile -ResolvedConfigPath $resolvedConfigPath -TickSeconds $tickSeconds -OnceMode
        if ($passResult.RunningCount -gt 0) {
            $eventRecord = Wait-Event -Timeout 1
            if ($null -ne $eventRecord) {
                Remove-Event -EventIdentifier $eventRecord.EventIdentifier -ErrorAction SilentlyContinue
            }

            Clear-SchedulerQueuedEvents
        }
    } while ($passResult.RunningCount -gt 0)

    $failed = $taskStates.Values | Where-Object { $_.Enabled -and $null -ne $_.LastExitCode -and $_.LastExitCode -ne 0 }
    exit $(if ($failed) { 1 } else { 0 })
}

$watcherRegistrations = @()
try {
    $watcherRegistrations = @(Register-SchedulerPendingPathWatchers -TaskStates $taskStates)
    foreach ($registration in $watcherRegistrations) {
        Write-CoworkerLog -Component 'scheduler' -Level 'DEBUG' -Message ("Watching {0}" -f $registration.Path)
    }

    while ($true) {
        [void](Invoke-SchedulerPass -TaskStates $taskStates -PowerShellExecutable $powerShellExecutable -WorkingDirectory $workingDirectory -LogDirectory $logDirectory -StatusFile $statusFile -ResolvedConfigPath $resolvedConfigPath -TickSeconds $tickSeconds)

        $eventRecord = Wait-Event -Timeout $tickSeconds
        if ($null -ne $eventRecord) {
            Remove-Event -EventIdentifier $eventRecord.EventIdentifier -ErrorAction SilentlyContinue
            Clear-SchedulerQueuedEvents
        }
    }
}
finally {
    foreach ($taskState in $taskStates.Values) {
        Clear-ScheduledTaskProcessExitEvent -TaskState $taskState
    }

    foreach ($registration in @($watcherRegistrations)) {
        Remove-CoworkerFileWatcher -Registration $registration
    }

    Clear-SchedulerQueuedEvents
}
