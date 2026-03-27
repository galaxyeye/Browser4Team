 # 磁盘空间管理工具

本文档详细记录了磁盘空间管理相关的PowerShell脚本的实现过程和思考。

## 1. 大文件夹扫描脚本 (analysis-user-home.ps1)

### 1.1 设计思路

这个脚本的主要目的是扫描用户目录，找出超过1GB的大文件夹。设计时考虑了以下关键点：

1. **完整性**：
   - 需要扫描所有子文件夹，包括隐藏文件夹
   - 需要计算每个文件夹的总大小
   - 需要显示文件夹的深度信息

2. **性能考虑**：
   - 使用递归遍历时要注意性能
   - 添加进度显示，让用户知道扫描进度
   - 使用异步处理避免阻塞

3. **用户体验**：
   - 实时显示发现的大文件夹
   - 提供清晰的统计信息
   - 使用友好的大小显示格式

### 1.2 关键实现

```powershell
# 使用-Force参数确保包含隐藏文件夹
$allFolders = Get-ChildItem -Path $targetPath -Directory -Recurse -Force -ErrorAction SilentlyContinue

# 计算文件夹大小
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

# 实时显示发现的大文件夹
if ($size -gt $threshold) {
    $sizeDisplay = if ($size -gt 1GB) {
        "{0:N2} GB" -f ($size / 1GB)
    } else {
        "{0:N2} MB" -f ($size / 1MB)
    }
    Write-Host "发现大文件夹: $folder → $sizeDisplay (深度: $depth)"
}
```

### 1.3 输出示例

```
开始扫描用户目录: C:\Users\username
扫描时间: 2024-01-01 12:00:00
大小阈值: 1GB

发现大文件夹: C:\Users\username\Downloads → 2.5 GB (深度: 1)
发现大文件夹: C:\Users\username\AppData\Local\Temp → 1.2 GB (深度: 2)

扫描统计信息:
总文件夹数: 150
最大深度: 5

大文件夹汇总:
Path                                    Size     Depth
----                                    ----     -----
C:\Users\username\Downloads             2.5 GB   1
C:\Users\username\AppData\Local\Temp    1.2 GB   2
```

## 2. 文件夹迁移脚本 (move-folder-to-d.ps1)

### 2.1 设计思路

这个脚本的目的是将大文件夹安全地迁移到D盘，并在原位置创建符号链接。设计时特别注重安全性：

1. **数据安全**：
   - 在移动前进行完整性检查
   - 使用robocopy确保文件属性完整复制
   - 创建备份以防操作失败
   - 提供回滚机制

2. **错误处理**：
   - 检查源文件夹是否存在
   - 检查目标磁盘空间
   - 验证复制结果
   - 详细的错误日志

3. **用户友好**：
   - 提供详细的操作日志
   - 显示进度信息
   - 清晰的成功/失败提示

### 2.2 关键实现

```powershell
# 检查空间
$sourceSize = (Get-ChildItem -Path $SourceFolderPath -Recurse -Force -File | Measure-Object -Property Length -Sum).Sum
$dDriveFreeSpace = $dDrive.Free
if ($sourceSize -gt $dDriveFreeSpace) {
    Write-Error "D盘空间不足。需要: $([math]::Round($sourceSize/1GB,2))GB, 可用: $([math]::Round($dDriveFreeSpace/1GB,2))GB"
    exit 1
}

# 安全复制
robocopy $SourceFolderPath $targetPath /E /COPYALL /R:1 /W:1 /LOG+:$logFile /TEE

# 创建备份和符号链接
$backupPath = "$SourceFolderPath.backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
Rename-Item -Path $SourceFolderPath -NewName (Split-Path -Path $backupPath -Leaf)
New-Item -ItemType SymbolicLink -Path $SourceFolderPath -Target $targetPath
```

### 2.3 使用说明

1. **运行要求**：
   - 需要管理员权限
   - D盘需要有足够空间
   - 源文件夹必须存在

2. **使用方法**：
```powershell
.\move-folder-to-d.ps1 -SourceFolderPath "C:\path\to\large\folder"
```

3. **输出示例**：
```
开始时间: 2024-01-01 12:00:00
源文件夹: C:\Users\username\Downloads
目标文件夹: D:\MovedFolders\Downloads
文件夹大小: 2.5 GB

正在复制文件到D盘...
...
复制完成，正在创建符号链接...
符号链接创建成功！
源文件夹已备份到: C:\Users\username\Downloads.backup_20240101_120000
新的符号链接指向: D:\MovedFolders\Downloads

操作完成！
日志文件: D:\MovedFolders\move_log_20240101_120000.txt
```

## 3. 注意事项

1. **权限要求**：
   - 两个脚本都需要管理员权限
   - 特别是创建符号链接需要提升的权限

2. **数据安全**：
   - 建议先在小文件夹上测试
   - 确保有足够的备份空间
   - 操作过程中不要中断脚本

3. **性能考虑**：
   - 大文件夹扫描可能需要较长时间
   - 文件迁移时建议在系统空闲时进行
   - 注意磁盘I/O对系统性能的影响

4. **错误处理**：
   - 脚本包含完整的错误处理机制
   - 如果操作失败会自动回滚
   - 所有操作都有日志记录

## 4. 后续改进方向

1. **功能增强**：
   - 添加并行处理提高性能
   - 支持更多文件系统特性
   - 添加图形界面

2. **安全性提升**：
   - 添加文件校验机制
   - 支持加密传输
   - 更详细的审计日志

3. **用户体验**：
   - 添加进度条
   - 支持暂停/恢复
   - 更友好的错误提示