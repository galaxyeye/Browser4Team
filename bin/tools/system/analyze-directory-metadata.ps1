[CmdletBinding()]
param(
    [string]$InputFilePath = (Join-Path $PSScriptRoot 'move-folder-to-d.txt'),
    [string]$TextReportPath,
    [string]$JsonReportPath,
    [switch]$IncludeSubdirectories
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Format-ByteSize {
    param([Nullable[double]]$Bytes)

    if ($null -eq $Bytes) {
        return 'n/a'
    }

    $value = [double]$Bytes
    $units = @('B', 'KB', 'MB', 'GB', 'TB', 'PB')
    $index = 0
    while ($value -ge 1024 -and $index -lt ($units.Count - 1)) {
        $value /= 1024
        $index++
    }

    if ($index -eq 0) {
        return ('{0:N0} {1}' -f $value, $units[$index])
    }

    return ('{0:N2} {1}' -f $value, $units[$index])
}

function Format-DateValue {
    param($Value)

    if ($null -eq $Value) {
        return 'n/a'
    }

    return (Get-Date $Value -Format 'yyyy-MM-dd HH:mm:ss')
}

function Get-ListedDirectoryPaths {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Input file not found: $Path"
    }

    $seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    $results = [System.Collections.Generic.List[string]]::new()

    foreach ($rawLine in Get-Content -LiteralPath $Path) {
        $line = $rawLine.Trim()
        if ([string]::IsNullOrWhiteSpace($line)) {
            continue
        }

        $match = [regex]::Match($line, '^(?<path>[A-Za-z]:\\.*?)(?=\s{2,}|$)')
        if (-not $match.Success) {
            continue
        }

        $candidate = $match.Groups['path'].Value.Trim()
        if ($seen.Add($candidate)) {
            $results.Add($candidate)
        }
    }

    return $results
}

function Get-VolumeInfoForPath {
    param(
        [string]$DirectoryPath,
        [hashtable]$Cache
    )

    $root = [System.IO.Path]::GetPathRoot($DirectoryPath)
    if ([string]::IsNullOrWhiteSpace($root)) {
        return $null
    }

    $driveLetter = $root.TrimEnd('\\')
    if (-not $Cache.ContainsKey($driveLetter)) {
        $escapedDrive = $driveLetter.Replace("'", "''")
        $volume = Get-CimInstance -ClassName Win32_Volume -Filter "DriveLetter = '$escapedDrive'" | Select-Object -First 1
        $Cache[$driveLetter] = $volume
    }

    return $Cache[$driveLetter]
}

function Convert-AclRules {
    param([System.Security.AccessControl.DirectorySecurity]$Acl)

    $readMask = [System.Security.AccessControl.FileSystemRights]::ReadData -bor
        [System.Security.AccessControl.FileSystemRights]::ListDirectory -bor
        [System.Security.AccessControl.FileSystemRights]::ReadAttributes -bor
        [System.Security.AccessControl.FileSystemRights]::ReadExtendedAttributes -bor
        [System.Security.AccessControl.FileSystemRights]::ReadPermissions
    $writeMask = [System.Security.AccessControl.FileSystemRights]::WriteData -bor
        [System.Security.AccessControl.FileSystemRights]::CreateDirectories -bor
        [System.Security.AccessControl.FileSystemRights]::CreateFiles -bor
        [System.Security.AccessControl.FileSystemRights]::AppendData -bor
        [System.Security.AccessControl.FileSystemRights]::WriteAttributes -bor
        [System.Security.AccessControl.FileSystemRights]::WriteExtendedAttributes
    $executeMask = [System.Security.AccessControl.FileSystemRights]::ExecuteFile -bor
        [System.Security.AccessControl.FileSystemRights]::Traverse

    $rules = foreach ($rule in $Acl.Access) {
        [pscustomobject]@{
            IdentityReference = $rule.IdentityReference.Value
            AccessType = $rule.AccessControlType.ToString()
            Rights = $rule.FileSystemRights.ToString()
            IsInherited = [bool]$rule.IsInherited
            InheritanceFlags = $rule.InheritanceFlags.ToString()
            PropagationFlags = $rule.PropagationFlags.ToString()
            Read = [bool](($rule.FileSystemRights -band $readMask) -ne 0)
            Write = [bool](($rule.FileSystemRights -band $writeMask) -ne 0)
            Execute = [bool](($rule.FileSystemRights -band $executeMask) -ne 0)
        }
    }

    return @($rules)
}

function Get-DirectoryTreeMetrics {
    param(
        [string]$RootPath,
        [UInt64]$ClusterSize,
        [switch]$IncludeSubdirectories
    )

    $stack = [System.Collections.Generic.Stack[object]]::new()
    $stack.Push([pscustomobject]@{ Path = $RootPath; Depth = 0 })

    $fileTypeCounts = [ordered]@{}
    $errors = [System.Collections.Generic.List[string]]::new()
    $fileCount = 0L
    $subdirectoryCount = 0L
    $totalSizeBytes = 0L
    $sizeOnDiskBytes = 0L
    $maxDepth = 0
    $maxBreadth = 0
    $maxSubdirectoryBreadth = 0
    $visitedDirectoryCount = 0L
    $breadthTotal = 0L

    while ($stack.Count -gt 0) {
        $frame = $stack.Pop()
        $visitedDirectoryCount++

        try {
            $children = @(Get-ChildItem -LiteralPath $frame.Path -Force -ErrorAction Stop)
        } catch {
            $errors.Add("Failed to enumerate $($frame.Path): $($_.Exception.Message)")
            continue
        }

        $childCount = $children.Count
        $breadthTotal += $childCount
        if ($childCount -gt $maxBreadth) {
            $maxBreadth = $childCount
        }

        $directoryChildCount = @($children | Where-Object { $_.PSIsContainer }).Count
        if ($directoryChildCount -gt $maxSubdirectoryBreadth) {
            $maxSubdirectoryBreadth = $directoryChildCount
        }

        foreach ($child in $children) {
            $childDepth = $frame.Depth + 1
            if ($childDepth -gt $maxDepth) {
                $maxDepth = $childDepth
            }

            if ($child.PSIsContainer) {
                $subdirectoryCount++
                $isReparsePoint = (($child.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0)
                if ($IncludeSubdirectories -and -not $isReparsePoint) {
                    $stack.Push([pscustomobject]@{ Path = $child.FullName; Depth = $childDepth })
                }
                continue
            }

            $fileCount++
            $fileLength = [int64]$child.Length
            $totalSizeBytes += $fileLength

            if ($ClusterSize -gt 0) {
                $sizeOnDiskBytes += [int64]([math]::Ceiling($fileLength / [double]$ClusterSize) * $ClusterSize)
            } else {
                $sizeOnDiskBytes += $fileLength
            }

            $extension = [System.IO.Path]::GetExtension($child.Name)
            if ([string]::IsNullOrWhiteSpace($extension)) {
                $extension = '[no extension]'
            } else {
                $extension = $extension.ToLowerInvariant()
            }

            if (-not $fileTypeCounts.Contains($extension)) {
                $fileTypeCounts[$extension] = 0
            }
            $fileTypeCounts[$extension]++
        }
    }

    $topFileTypes = @(
        $fileTypeCounts.GetEnumerator() |
            Sort-Object -Property @(
                @{ Expression = { $_.Value }; Descending = $true },
                @{ Expression = { $_.Key }; Descending = $false }
            ) |
            ForEach-Object {
                [pscustomobject]@{
                    Extension = $_.Key
                    Count = $_.Value
                }
            }
    )

    $averageBreadth = if ($visitedDirectoryCount -gt 0) {
        [math]::Round($breadthTotal / [double]$visitedDirectoryCount, 2)
    } else {
        0
    }

    return [pscustomobject]@{
        FileCount = $fileCount
        SubdirectoryCount = $subdirectoryCount
        TotalSizeBytes = $totalSizeBytes
        SizeOnDiskBytes = $sizeOnDiskBytes
        MaxDepth = $maxDepth
        MaxBreadth = $maxBreadth
        MaxSubdirectoryBreadth = $maxSubdirectoryBreadth
        AverageBreadth = $averageBreadth
        VisitedDirectoryCount = $visitedDirectoryCount
        FileTypeCounts = $topFileTypes
        DistinctFileTypeCount = $fileTypeCounts.Count
        Errors = @($errors)
    }
}

function New-MissingDirectoryReport {
    param(
        [string]$DirectoryPath,
        [string]$ScanMode
    )

    return [pscustomobject]@{
        Path = $DirectoryPath
        Exists = $false
        Status = 'Missing'
        ScanMode = $ScanMode
        ItemType = 'Missing'
        LinkType = 'n/a'
        Target = $null
        CreationTime = $null
        LastWriteTime = $null
        LastAccessTime = $null
        Owner = $null
        Group = $null
        AccessRules = @()
        Attributes = [pscustomobject]@{
            Hidden = $false
            ReadOnly = $false
            System = $false
            Archive = $false
            Compressed = $false
            Encrypted = $false
            ReparsePoint = $false
        }
        SizeBytes = $null
        SizeOnDiskBytes = $null
        FileCount = $null
        SubdirectoryCount = $null
        Structure = $null
        DistinctFileTypeCount = $null
        FileTypes = @()
        FileSystem = $null
        Volume = $null
        DiskUsagePercentOfVolume = $null
        AnalysisErrors = @("Directory not found: $DirectoryPath")
    }
}

function New-DirectoryReport {
    param(
        [string]$DirectoryPath,
        [hashtable]$VolumeCache,
        [switch]$IncludeSubdirectories
    )

    $scanMode = if ($IncludeSubdirectories) { 'Recursive' } else { 'TopLevelOnly' }

    if (-not (Test-Path -LiteralPath $DirectoryPath -PathType Container)) {
        return New-MissingDirectoryReport -DirectoryPath $DirectoryPath -ScanMode $scanMode
    }

    $item = Get-Item -LiteralPath $DirectoryPath -Force
    $attributes = $item.Attributes
    $isReparsePoint = (($attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0)
    $linkType = if ($item.LinkType) { $item.LinkType } elseif ($isReparsePoint) { 'ReparsePoint' } else { 'Directory' }
    $target = if ($item.Target) { @($item.Target) -join '; ' } else { $null }

    $volume = Get-VolumeInfoForPath -DirectoryPath $DirectoryPath -Cache $VolumeCache
    $clusterSize = if ($null -ne $volume -and $null -ne $volume.BlockSize) { [UInt64]$volume.BlockSize } else { [UInt64]0 }
    $metrics = Get-DirectoryTreeMetrics -RootPath $DirectoryPath -ClusterSize $clusterSize -IncludeSubdirectories:$IncludeSubdirectories
    $acl = Get-Acl -LiteralPath $DirectoryPath
    $accessRules = Convert-AclRules -Acl $acl
    $diskUsagePercent = if ($null -ne $volume -and $volume.Capacity) {
        [math]::Round(($metrics.SizeOnDiskBytes / [double]$volume.Capacity) * 100, 4)
    } else {
        $null
    }

    return [pscustomobject]@{
        Path = $DirectoryPath
        Exists = $true
        Status = 'Analyzed'
        ScanMode = $scanMode
        ItemType = if ($item.PSIsContainer) { 'Directory' } else { $item.PSObject.TypeNames[0] }
        LinkType = $linkType
        Target = $target
        CreationTime = $item.CreationTime
        LastWriteTime = $item.LastWriteTime
        LastAccessTime = $item.LastAccessTime
        Owner = $acl.Owner
        Group = $acl.Group
        AccessRules = $accessRules
        Attributes = [pscustomobject]@{
            Hidden = $attributes.HasFlag([System.IO.FileAttributes]::Hidden)
            ReadOnly = $attributes.HasFlag([System.IO.FileAttributes]::ReadOnly)
            System = $attributes.HasFlag([System.IO.FileAttributes]::System)
            Archive = $attributes.HasFlag([System.IO.FileAttributes]::Archive)
            Compressed = $attributes.HasFlag([System.IO.FileAttributes]::Compressed)
            Encrypted = $attributes.HasFlag([System.IO.FileAttributes]::Encrypted)
            ReparsePoint = $isReparsePoint
        }
        SizeBytes = $metrics.TotalSizeBytes
        SizeOnDiskBytes = $metrics.SizeOnDiskBytes
        FileCount = $metrics.FileCount
        SubdirectoryCount = $metrics.SubdirectoryCount
        Structure = [pscustomobject]@{
            MaxDepth = $metrics.MaxDepth
            MaxBreadth = $metrics.MaxBreadth
            MaxSubdirectoryBreadth = $metrics.MaxSubdirectoryBreadth
            AverageBreadth = $metrics.AverageBreadth
            VisitedDirectoryCount = $metrics.VisitedDirectoryCount
        }
        DistinctFileTypeCount = $metrics.DistinctFileTypeCount
        FileTypes = $metrics.FileTypeCounts
        FileSystem = if ($null -ne $volume) { $volume.FileSystem } else { $null }
        Volume = if ($null -ne $volume) {
            [pscustomobject]@{
                DriveLetter = $volume.DriveLetter
                Label = $volume.Label
                TotalSpaceBytes = [int64]$volume.Capacity
                FreeSpaceBytes = [int64]$volume.FreeSpace
                AllocationUnitBytes = [int64]$volume.BlockSize
            }
        } else {
            $null
        }
        DiskUsagePercentOfVolume = $diskUsagePercent
        AnalysisErrors = @($metrics.Errors)
    }
}

function Convert-DirectoryReportToLines {
    param([pscustomobject]$Report)

    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add(("Path: {0}" -f $Report.Path))
    $lines.Add(("Status: {0}" -f $Report.Status))
    $lines.Add(("Scan mode: {0}" -f $Report.ScanMode))

    if (-not $Report.Exists) {
        foreach ($errorMessage in $Report.AnalysisErrors) {
            $lines.Add(("  Error: {0}" -f $errorMessage))
        }
        return $lines
    }

    $lines.Add(("Type: {0}" -f $Report.ItemType))
    $lines.Add(("Link/Reparse Type: {0}" -f $Report.LinkType))
    $lines.Add(("Target: {0}" -f $(if ($Report.Target) { $Report.Target } else { 'n/a' })))
    $lines.Add(("Size: {0} ({1} bytes)" -f (Format-ByteSize $Report.SizeBytes), $Report.SizeBytes))
    $lines.Add(("Size on disk: {0} ({1} bytes)" -f (Format-ByteSize $Report.SizeOnDiskBytes), $Report.SizeOnDiskBytes))
    $lines.Add(("Creation time: {0}" -f (Format-DateValue $Report.CreationTime)))
    $lines.Add(("Last modified: {0}" -f (Format-DateValue $Report.LastWriteTime)))
    $lines.Add(("Last accessed: {0}" -f (Format-DateValue $Report.LastAccessTime)))
    $lines.Add(("Owner: {0}" -f $Report.Owner))
    $lines.Add(("Group: {0}" -f $Report.Group))
    $lines.Add(("Files: {0}" -f $Report.FileCount))
    $lines.Add(("Subdirectories: {0}" -f $Report.SubdirectoryCount))
    $lines.Add(("Distinct file types: {0}" -f $Report.DistinctFileTypeCount))
    $lines.Add(("Structure metrics: max depth={0}, max breadth={1}, max subdirectory breadth={2}, average breadth={3}, visited directories={4}" -f $Report.Structure.MaxDepth, $Report.Structure.MaxBreadth, $Report.Structure.MaxSubdirectoryBreadth, $Report.Structure.AverageBreadth, $Report.Structure.VisitedDirectoryCount))
    $lines.Add(("File system: {0}" -f $Report.FileSystem))

    if ($null -ne $Report.Volume) {
        $lines.Add(("Volume: drive={0}, label={1}, total={2}, free={3}, allocation unit={4}" -f $Report.Volume.DriveLetter, $(if ($Report.Volume.Label) { $Report.Volume.Label } else { '<no label>' }), (Format-ByteSize $Report.Volume.TotalSpaceBytes), (Format-ByteSize $Report.Volume.FreeSpaceBytes), (Format-ByteSize $Report.Volume.AllocationUnitBytes)))
    } else {
        $lines.Add('Volume: n/a')
    }

    $lines.Add(("Disk usage on volume: {0}%" -f $(if ($null -ne $Report.DiskUsagePercentOfVolume) { $Report.DiskUsagePercentOfVolume } else { 'n/a' })))
    $lines.Add(("Attributes: hidden={0}, readOnly={1}, system={2}, archive={3}, compressed={4}, encrypted={5}, reparsePoint={6}" -f $Report.Attributes.Hidden, $Report.Attributes.ReadOnly, $Report.Attributes.System, $Report.Attributes.Archive, $Report.Attributes.Compressed, $Report.Attributes.Encrypted, $Report.Attributes.ReparsePoint))
    $lines.Add('Access rules:')
    if ($Report.AccessRules.Count -eq 0) {
        $lines.Add('  <none>')
    } else {
        foreach ($rule in $Report.AccessRules) {
            $lines.Add(("  - {0} | {1} | rights={2} | inherited={3} | read={4} write={5} execute={6} | inheritance={7} | propagation={8}" -f $rule.IdentityReference, $rule.AccessType, $rule.Rights, $rule.IsInherited, $rule.Read, $rule.Write, $rule.Execute, $rule.InheritanceFlags, $rule.PropagationFlags))
        }
    }

    $lines.Add('File types:')
    if ($Report.FileTypes.Count -eq 0) {
        $lines.Add('  <none>')
    } else {
        foreach ($fileType in $Report.FileTypes) {
            $lines.Add(("  - {0}: {1}" -f $fileType.Extension, $fileType.Count))
        }
    }

    if ($Report.AnalysisErrors.Count -gt 0) {
        $lines.Add('Analysis warnings:')
        foreach ($errorMessage in $Report.AnalysisErrors) {
            $lines.Add(("  - {0}" -f $errorMessage))
        }
    }

    return $lines
}

$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$defaultOutputRoot = Join-Path $PSScriptRoot 'logs'
$null = New-Item -Path $defaultOutputRoot -ItemType Directory -Force

if ([string]::IsNullOrWhiteSpace($TextReportPath)) {
    $TextReportPath = Join-Path $defaultOutputRoot ("directory-metadata_{0}.txt" -f $timestamp)
}
if ([string]::IsNullOrWhiteSpace($JsonReportPath)) {
    $JsonReportPath = Join-Path $defaultOutputRoot ("directory-metadata_{0}.json" -f $timestamp)
}

$inputDirectories = @(Get-ListedDirectoryPaths -Path $InputFilePath)
if ($inputDirectories.Count -eq 0) {
    throw "No directory paths were found in: $InputFilePath"
}

$volumeCache = @{}
$reports = foreach ($directoryPath in $inputDirectories) {
    Write-Host ("Analyzing {0} [{1}]" -f $directoryPath, $(if ($IncludeSubdirectories) { 'recursive' } else { 'top-level only' }))
    New-DirectoryReport -DirectoryPath $directoryPath -VolumeCache $volumeCache -IncludeSubdirectories:$IncludeSubdirectories
}

$summaryTable = $reports |
    Select-Object @{
            Name = 'Path'
            Expression = { $_.Path }
        }, @{
            Name = 'ScanMode'
            Expression = { $_.ScanMode }
        }, @{
            Name = 'Status'
            Expression = { $_.Status }
        }, @{
            Name = 'LinkType'
            Expression = { $_.LinkType }
        }, @{
            Name = 'Size'
            Expression = { if ($_.Exists) { Format-ByteSize $_.SizeBytes } else { 'n/a' } }
        }, @{
            Name = 'SizeOnDisk'
            Expression = { if ($_.Exists) { Format-ByteSize $_.SizeOnDiskBytes } else { 'n/a' } }
        }, @{
            Name = 'Files'
            Expression = { $_.FileCount }
        }, @{
            Name = 'Subdirs'
            Expression = { $_.SubdirectoryCount }
        }, @{
            Name = 'Depth'
            Expression = { if ($_.Structure) { $_.Structure.MaxDepth } else { $null } }
        }, @{
            Name = 'Breadth'
            Expression = { if ($_.Structure) { $_.Structure.MaxBreadth } else { $null } }
        }, @{
            Name = 'FileSystem'
            Expression = { $_.FileSystem }
        }, @{
            Name = 'DiskUsage%'
            Expression = { if ($null -ne $_.DiskUsagePercentOfVolume) { $_.DiskUsagePercentOfVolume } else { $null } }
        } |
    Format-Table -AutoSize | Out-String -Width 260

$detailedLines = [System.Collections.Generic.List[string]]::new()
$detailedLines.Add(("Directory metadata report"))
$detailedLines.Add(("Generated: {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')))
$detailedLines.Add(("Input file: {0}" -f $InputFilePath))
$detailedLines.Add(("Include subdirectories: {0}" -f $IncludeSubdirectories.IsPresent))
$detailedLines.Add('')
$detailedLines.Add('Summary')
$detailedLines.Add('-------')
foreach ($summaryLine in ($summaryTable.TrimEnd() -split "`r?`n")) {
    $detailedLines.Add($summaryLine)
}

foreach ($report in $reports) {
    $detailedLines.Add('')
    $detailedLines.Add(('='.PadLeft(80, '=')))
    foreach ($line in (Convert-DirectoryReportToLines -Report $report)) {
        $detailedLines.Add($line)
    }
}

$detailedLines | Set-Content -LiteralPath $TextReportPath -Encoding UTF8
$reports | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $JsonReportPath -Encoding UTF8

Write-Host ''
Write-Host 'Summary'
Write-Host '-------'
Write-Host ($summaryTable.TrimEnd())
Write-Host ''
Write-Host ("Detailed report: {0}" -f $TextReportPath)
Write-Host ("JSON report: {0}" -f $JsonReportPath)


