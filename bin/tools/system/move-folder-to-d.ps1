#!/usr/bin/env pwsh

param(
    [Parameter(Mandatory=$true)]
    [string]$SourceFolderPath
)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "请以管理员身份运行此脚本。"
    exit 1
}

# 检查源文件夹是否存在
if (-not (Test-Path -Path $SourceFolderPath -PathType Container)) {
    Write-Error "源文件夹不存在: $SourceFolderPath"
    exit 1
}

# 检查D盘是否存在且有足够空间
$dDrive = Get-PSDrive -Name D -ErrorAction SilentlyContinue
if (-not $dDrive) {
    Write-Error "D盘不存在"
    exit 1
}

# 计算源文件夹大小
$sourceSize = (Get-ChildItem -Path $SourceFolderPath -Recurse -Force -File | Measure-Object -Property Length -Sum).Sum
$dDriveFreeSpace = $dDrive.Free
if ($sourceSize -gt $dDriveFreeSpace) {
    Write-Error "D盘空间不足。需要: $([math]::Round($sourceSize/1GB,2))GB, 可用: $([math]::Round($dDriveFreeSpace/1GB,2))GB"
    exit 1
}

# 生成目标路径（在D盘创建相同的目录结构）
$sourceFolderName = Split-Path -Path $SourceFolderPath -Leaf
$targetPath = Join-Path "D:\" "MovedFolders\$sourceFolderName"

# 创建日志文件
$logFile = "D:\MovedFolders\move_log_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
$null = New-Item -Path (Split-Path -Path $logFile -Parent) -ItemType Directory -Force

# 记录开始信息
$startTime = Get-Date
"开始时间: $startTime" | Out-File -FilePath $logFile -Append
"源文件夹: $SourceFolderPath" | Out-File -FilePath $logFile -Append
"目标文件夹: $targetPath" | Out-File -FilePath $logFile -Append
"文件夹大小: $([math]::Round($sourceSize/1GB,2))GB" | Out-File -FilePath $logFile -Append

# 创建目标目录
try {
    New-Item -Path $targetPath -ItemType Directory -Force | Out-Null
} catch {
    Write-Error "无法创建目标目录: $_"
    exit 1
}

# 使用robocopy进行安全复制（保留所有属性和权限）
Write-Host "正在复制文件到D盘..."
robocopy $SourceFolderPath $targetPath /E /COPYALL /R:1 /W:1 /LOG+:$logFile /TEE

# 验证复制是否成功
$sourceFileCount = (Get-ChildItem -Path $SourceFolderPath -Recurse -Force -File).Count
$targetFileCount = (Get-ChildItem -Path $targetPath -Recurse -Force -File).Count

if ($sourceFileCount -ne $targetFileCount) {
    Write-Error "文件数量不匹配！源文件夹: $sourceFileCount, 目标文件夹: $targetFileCount"
    exit 1
}

# 如果复制成功，删除源文件夹并创建符号链接
Write-Host "复制完成，正在创建符号链接..."
try {
    # 备份源文件夹（重命名）
    $backupPath = "$SourceFolderPath.backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    Rename-Item -Path $SourceFolderPath -NewName (Split-Path -Path $backupPath -Leaf)
    
    # 创建符号链接
    New-Item -ItemType SymbolicLink -Path $SourceFolderPath -Target $targetPath | Out-Null
    
    # 验证符号链接
    if (Test-Path -Path $SourceFolderPath -PathType Container) {
        Write-Host "符号链接创建成功！"
        Write-Host "源文件夹已备份到: $backupPath"
        Write-Host "新的符号链接指向: $targetPath"
    } else {
        Write-Error "符号链接创建失败"
        # 恢复备份
        Rename-Item -Path $backupPath -NewName (Split-Path -Path $SourceFolderPath -Leaf)
        exit 1
    }
} catch {
    Write-Error "创建符号链接时出错: $_"
    # 恢复备份
    Rename-Item -Path $backupPath -NewName (Split-Path -Path $SourceFolderPath -Leaf)
    exit 1
}

# 记录完成信息
$endTime = Get-Date
$duration = $endTime - $startTime
"完成时间: $endTime" | Out-File -FilePath $logFile -Append
"总耗时: $($duration.TotalMinutes) 分钟" | Out-File -FilePath $logFile -Append
"操作状态: 成功" | Out-File -FilePath $logFile -Append

Write-Host "`n操作完成！"
Write-Host "日志文件: $logFile"
Write-Host "源文件夹已备份到: $backupPath"
Write-Host "新的符号链接指向: $targetPath"