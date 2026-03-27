param(
    [Parameter(Mandatory=$true)]
    [string]$TargetPath
)

$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$logDirectory = Join-Path $PSScriptRoot "logs"
$sanitizedTargetName = Split-Path -Path $TargetPath -Leaf
if ([string]::IsNullOrWhiteSpace($sanitizedTargetName)) {
    $sanitizedTargetName = "root"
}
$sanitizedTargetName = $sanitizedTargetName -replace '[<>:"/\\|?*]', '_'
$logFile = Join-Path $logDirectory ("analysis-folder-size_{0}_{1}.log" -f $sanitizedTargetName, $timestamp)
$transcriptStarted = $false
$exitCode = 0

try {
    $null = New-Item -Path $logDirectory -ItemType Directory -Force
    Start-Transcript -Path $logFile -Append | Out-Null
    $transcriptStarted = $true
    Write-Host "日志文件: $logFile"

# 将用户输入的阈值转换为字节
function Convert-SizeToBytes {
    param([string]$size)
    
    $size = $size.Trim().ToUpper()
    $number = [double]($size -replace '[^0-9.]', '')
    $unit = $size -replace '[0-9.]', ''
    
    switch ($unit) {
        "B" { return $number }
        "KB" { return $number * 1KB }
        "MB" { return $number * 1MB }
        "GB" { return $number * 1GB }
        "TB" { return $number * 1TB }
        default {
            throw "无效的大小单位。请使用 B, KB, MB, GB, 或 TB"
        }
    }
}

# 将字节转换为可读格式
function Format-Size {
    param([long]$bytes)
    
    if ($bytes -ge 1TB) {
        return "{0:N2} TB" -f ($bytes / 1TB)
    } elseif ($bytes -ge 1GB) {
        return "{0:N2} GB" -f ($bytes / 1GB)
    } elseif ($bytes -ge 1MB) {
        return "{0:N2} MB" -f ($bytes / 1MB)
    } elseif ($bytes -ge 1KB) {
        return "{0:N2} KB" -f ($bytes / 1KB)
    } else {
        return "$bytes B"
    }
}

# 检查路径是否存在
if (-not (Test-Path -Path $TargetPath -PathType Container)) {
    throw "指定的路径不存在或不是一个文件夹: $TargetPath"
}

# 交互式输入阈值
Write-Host "`n请输入要查找的大文件夹的阈值大小"
Write-Host "支持的格式: B, KB, MB, GB, TB (例如: 1GB, 500MB, 2TB)"
Write-Host "直接回车将使用默认值 1GB"
$thresholdInput = Read-Host "阈值大小"

# 设置默认值
if ([string]::IsNullOrWhiteSpace($thresholdInput)) {
    $thresholdInput = "1GB"
    Write-Host "使用默认阈值: 1GB"
}

# 转换阈值
try {
    $thresholdBytes = Convert-SizeToBytes -size $thresholdInput
} catch {
    Write-Error "无效的阈值格式: $thresholdInput"
    Write-Host "`n支持的格式示例:"
    Write-Host "1GB  - 1千兆字节"
    Write-Host "500MB - 500兆字节"
    Write-Host "2TB   - 2太字节"
    throw
}

Write-Host "`n开始扫描目录: $TargetPath"
Write-Host "扫描时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host "大小阈值: $(Format-Size -bytes $thresholdBytes)`n"

# 添加调试信息来验证递归深度
$maxDepth = 0
$folderCount = 0

function Get-FolderSize($path) {
    $size = 0
    try {
        $size = Get-ChildItem -Path $path -Recurse -File -Force -ErrorAction SilentlyContinue |
                Measure-Object -Property Length -Sum |
                Select-Object -ExpandProperty Sum
    } catch {
        Write-Warning "无法访问: $path"
    }
    return $size
}

# 检查是否为符号链接
function Test-SymbolicLink {
    param([string]$path)
    
    try {
        $item = Get-Item -Path $path -Force
        return $item.LinkType -eq "SymbolicLink"
    } catch {
        return $false
    }
}

# 获取符号链接的目标
function Get-SymbolicLinkTarget {
    param([string]$path)
    
    try {
        $item = Get-Item -Path $path -Force
        if ($item.LinkType -eq "SymbolicLink") {
            return $item.Target
        }
        return $null
    } catch {
        return $null
    }
}

# 获取所有文件夹并计算深度
$allFolders = Get-ChildItem -Path $TargetPath -Directory -Recurse -Force -ErrorAction SilentlyContinue
$totalFolders = $allFolders.Count
$currentFolder = 0
$largeFolders = @()

$allFolders | ForEach-Object {
    $currentFolder++
    $folder = $_.FullName
    $depth = ($folder -replace [regex]::Escape($TargetPath), '').Split('\').Count - 1
    $maxDepth = [Math]::Max($maxDepth, $depth)
    
    Write-Progress -Activity "扫描文件夹" -Status "$folder" -PercentComplete (($currentFolder / $totalFolders) * 100)
    
    $size = Get-FolderSize -path $folder
    $isSymbolicLink = Test-SymbolicLink -path $folder
    $linkTarget = if ($isSymbolicLink) { Get-SymbolicLinkTarget -path $folder } else { $null }

    if ($size -gt $thresholdBytes) {
        $sizeDisplay = Format-Size -bytes $size
        
        # 立即打印发现的大文件夹
        $linkInfo = if ($isSymbolicLink) { " [符号链接 → $linkTarget]" } else { "" }
        Write-Host "发现大文件夹: $folder → $sizeDisplay (深度: $depth)$linkInfo"
        
        $largeFolders += [PSCustomObject]@{
            Path = $folder
            Size = $sizeDisplay
            Depth = $depth
            IsSymbolicLink = $isSymbolicLink
            LinkTarget = $linkTarget
        }
    }
}

Write-Host "`n扫描统计信息:"
Write-Host "总文件夹数: $totalFolders"
Write-Host "最大深度: $maxDepth"
Write-Host "`n大文件夹汇总:"
if ($largeFolders.Count -eq 0) {
    Write-Host "未发现超过阈值的文件夹。"
} else {
    $summaryTable = $largeFolders |
        Sort-Object -Property Depth -Descending |
        Format-Table -AutoSize -Property Path, Size, Depth, @{
            Name = "类型";
            Expression = {
                if ($_.IsSymbolicLink) {
                    "符号链接 → $($_.LinkTarget)"
                } else {
                    "普通文件夹"
                }
            }
        } |
        Out-String -Width 240

    Write-Host ($summaryTable.TrimEnd())
}
} catch {
    $exitCode = 1
    Write-Error $_
} finally {
    if ($transcriptStarted) {
        Write-Host "`n日志文件: $logFile"
        Stop-Transcript | Out-Null
    }

    if ($exitCode -ne 0) {
        exit $exitCode
    }
}
