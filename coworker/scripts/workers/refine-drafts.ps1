#!/usr/bin/env pwsh

param(
    [string]$Path
)

$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'gh-copilot.ps1')

$repoRoot = Get-WorkspaceRoot
$copilotCommand = Get-GHCopilotCommand -RepoRoot $repoRoot

$refineRoot = Resolve-TasksPath '0draft\refine'
$readyDir = Join-Path $refineRoot '1ready'
$workingDir = Join-Path $refineRoot '2working'
$doneDir = Join-Path $refineRoot '3done'

foreach ($directory in @($readyDir, $workingDir, $doneDir)) {
    if (-not (Test-Path $directory)) {
        New-Item -ItemType Directory -Path $directory | Out-Null
    }
}

if ([string]::IsNullOrWhiteSpace($Path)) {
    $Path = $readyDir
}

function Resolve-UniquePath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Directory,
        [Parameter(Mandatory = $true)]
        [string]$BaseName,
        [Parameter(Mandatory = $true)]
        [string]$Extension
    )

    $candidatePath = Join-Path $Directory "$BaseName$Extension"
    if (-not (Test-Path $candidatePath)) {
        return $candidatePath
    }

    $counter = 2
    while ($true) {
        $nextPath = Join-Path $Directory "$BaseName.$counter$Extension"
        if (-not (Test-Path $nextPath)) {
            return $nextPath
        }
        $counter++
    }
}

function Get-RefineTargets {
    param(
        [Parameter(Mandatory = $true)]
        [string]$InputPath
    )

    if (-not (Test-Path $InputPath)) {
        throw "Refine path not found: $InputPath"
    }

    $item = Get-Item $InputPath
    if ($item.PSIsContainer) {
        return @(Get-ChildItem -Path $item.FullName -File | Sort-Object Name)
    }

    return @($item)
}

function Get-RefinedFileName {
    param(
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo]$DraftFile
    )

    $draftContent = Get-Content -Path $DraftFile.FullName -Raw -Encoding UTF8
    $prompt = @"
Generate a concise, kebab-case filename (without extension) that accurately reflects the content of the following text.
Do not return any other text, just the filename.
Ensure the filename is valid for Windows file systems (no special characters).

--- BEGIN CONTENT ---
$draftContent
--- END CONTENT ---
"@

    try {
        $refinedName = Invoke-GHCopilot -Prompt $prompt -AdditionalArguments @('--allow-all-tools', '--allow-all-paths') -RepoRoot $repoRoot -WorkingDirectory $repoRoot -CaptureOutput
        
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "GitHub Copilot exited with code $LASTEXITCODE while generating filename for $($DraftFile.Name). Using original name."
            return $DraftFile.BaseName
        }

        $refinedName = $refinedName.Trim().Trim('"').Trim("'")
        
        # Basic validation
        if ([string]::IsNullOrWhiteSpace($refinedName) -or $refinedName -match '[<>:"/\\|?*]') {
            Write-Warning "Generated filename '$refinedName' is invalid or empty. Using original name."
            return $DraftFile.BaseName
        }

        return $refinedName
    }
    catch {
        Write-Warning "Failed to generate filename for $($DraftFile.Name): $_. Using original name."
        return $DraftFile.BaseName
    }
}

function Invoke-DraftRefinement {
    param(
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo]$WorkingFile
    )

    $draftContent = Get-Content -Path $WorkingFile.FullName -Raw -Encoding UTF8
    $prompt = @"
Refine the following draft for clarity, coherence, and relevance to the intended audience.
Preserve the original intent and useful structure unless a change materially improves the draft.
Return only the complete refined document content with no surrounding code fences or commentary.

Source file: $($WorkingFile.FullName)

--- BEGIN DRAFT ---
$draftContent
--- END DRAFT ---
"@

    $refinedContent = Invoke-GHCopilot -Prompt $prompt -AdditionalArguments @('--allow-all-tools', '--allow-all-paths') -RepoRoot $repoRoot -WorkingDirectory $repoRoot -CaptureOutput
    if ($LASTEXITCODE -ne 0) {
        throw "GitHub Copilot exited with code $LASTEXITCODE while refining $($WorkingFile.Name)"
    }

    $refinedContent = $refinedContent.Trim("`r", "`n")
    if ([string]::IsNullOrWhiteSpace($refinedContent)) {
        throw "GitHub Copilot returned empty output for $($WorkingFile.Name)"
    }

    return $refinedContent
}

$targets = Get-RefineTargets -InputPath $Path
if ($targets.Count -eq 0) {
    Write-Host "No draft files found in $Path"
    exit 0
}

$failureCount = 0

foreach ($target in $targets) {
    $newBaseName = Get-RefinedFileName -DraftFile $target
    $workingPath = Resolve-UniquePath -Directory $workingDir -BaseName $newBaseName -Extension $target.Extension
    Move-Item -Path $target.FullName -Destination $workingPath -Force
    $workingFile = Get-Item $workingPath
    Write-Host "Moved draft to working: $($workingFile.FullName) (renamed from $($target.Name))"

    try {
        $refinedContent = Invoke-DraftRefinement -WorkingFile $workingFile
        Set-Content -Path $workingFile.FullName -Value $refinedContent -Encoding UTF8

        $donePath = Resolve-UniquePath -Directory $doneDir -BaseName $workingFile.BaseName -Extension $workingFile.Extension
        Move-Item -Path $workingFile.FullName -Destination $donePath -Force
        Write-Host "Refined draft moved to done: $donePath"
    }
    catch {
        $failureCount++
        Write-Host "Failed to refine $($workingFile.Name): $_" -ForegroundColor Red
    }
}

if ($failureCount -gt 0) {
    exit 1
}
