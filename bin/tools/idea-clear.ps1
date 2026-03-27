# 🔍 Find the first parent directory containing the VERSION file
$AppHome=(Get-Item -Path $MyInvocation.MyCommand.Path).Directory
while ($AppHome -ne $null -and !(Test-Path "$AppHome/VERSION")) {
  $AppHome = Split-Path -Parent $AppHome
}
Set-Location $AppHome

# Find and delete all the directories and files: .idea, *.iml
function DeleteIdeaFile($targetDir) {
    $AppHome | Get-ChildItem -Recurse -Include .idea, *.iml | ForEach-Object {
         Write-Host "Deleting $($_.FullName)"
         Remove-Item -Path $_.FullName -Recurse -Force
    }
}

# Find all logs directories which contains *.log files and delete the logs directories
function DeleteLogDirectory($targetDir) {
    $AppHome | Get-ChildItem -Recurse -Include *.log | ForEach-Object {
        $logDir=$_.Directory

        # Delete the logs directory if it exists
        if ($logDir -ne $null -and $logDir.Name -eq "logs") {
             Write-Host "Deleting $logDir"
             Remove-Item -Path $logDir -Recurse -Force
        }
    }
}

# Find all target directories which contains a generated-sources directory, and then delete the directories
# whose name is target.
function DeleteTargetDirectory($targetDir) {
    $AppHome | Get-ChildItem -Recurse -Include generated-sources | ForEach-Object {
        $targetDir=$_.Parent

        # Delete the target directory if it exists
        if ($targetDir -ne $null -and $targetDir.Name -eq "target" -and $targetDir.Exists) {
            Write-Host "Deleting $($targetDir.FullName)"
            Remove-Item -Path $targetDir -Recurse -Force
        }
    }
}

# Ask the user to confirm the deletion, we will call DeleteIdeaFile, DeleteLogDirectory, and DeleteTargetDirectory
# sequentially if the user inputs 'y' or 'Y'.

Write-Host "Delete .idea, *.iml? (y/n)"
$confirmation = Read-Host "y/n"
if ($confirmation -eq "y" -or $confirmation -eq "Y") {
    DeleteIdeaFile $AppHome
}

Write-Host "Delete logs directories? (y/n)"
$confirmation = Read-Host "y/n"
if ($confirmation -eq "y" -or $confirmation -eq "Y") {
    DeleteLogDirectory $AppHome
}

Write-Host "Delete target directories? (y/n)"
$confirmation = Read-Host "y/n"
if ($confirmation -eq "y" -or $confirmation -eq "Y") {
    DeleteTargetDirectory $AppHome
}
