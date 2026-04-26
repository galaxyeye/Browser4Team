#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Coworker Memory Generator
.DESCRIPTION
    Generates memory summaries (daily, monthly, yearly, global) based on logs or previous summaries.
.PARAMETER Type
    The type of memory to generate: "daily", "monthly", "yearly", "global". Defaults to "daily".
.PARAMETER Date
    The date to generate memory for (format: YYYY-MM-DD). Defaults to today.
.PARAMETER Force
    Force generation even if file exists (overwrites).
#>
param(
    [ValidateSet("daily", "monthly", "yearly", "global", "init")]
    [string]$Type = "daily",

    [string]$Date = ((Get-Date).ToUniversalTime().ToString("yyyy-MM-dd")),

    [switch]$Force
)

$ErrorActionPreference = "Stop"

$configPath = Join-Path (Split-Path -Parent $PSScriptRoot) "config.ps1"
. $configPath
$repoRoot = Get-WorkspaceRoot
$ghCopilotHelper = Join-Path $PSScriptRoot 'gh-copilot.ps1'
. $ghCopilotHelper
$copilotCommand = Get-GHCopilotCommand -RepoRoot $repoRoot
$copilotExecutable = $copilotCommand.Executable
$copilotBaseArgs = $copilotCommand.BaseArgs

$parsedDate = Get-Date $Date
$year = $parsedDate.ToString("yyyy")
$month = $parsedDate.ToString("MM")
$day = $parsedDate.ToString("dd")

$logsBaseDir = Resolve-TasksPath '300logs'

# Function to run gh copilot
function Invoke-GhCopilot {
    param(
        [string]$Prompt,
        [switch]$CaptureOutput
    )

    # Truncate if too long (approx check, limit depends on OS/shell but 20k is safeish)
    if ($Prompt.Length -gt 25000) {
        Write-CoworkerLog -Component 'memory-generator' -Level 'WARN' -NoColor -Message "Prompt length ($($Prompt.Length)) exceeds 25000 chars; truncating input."
        $Prompt = $Prompt.Substring(0, 25000) + " ... [Truncated]"
    }

    if ($CaptureOutput) {
        return Invoke-GHCopilot -Prompt $Prompt -AdditionalArguments @('--allow-all-tools') -RepoRoot $repoRoot -WorkingDirectory $repoRoot -CaptureOutput
    } else {
        # Arguments for Start-Process (might need quotes for complex strings depending on PS version/OS)
        # But generally, Start-Process ArgumentList array is safe.
        # The original code added quotes, let's keep it for safety in the Start-Process path.
        $safePrompt = $Prompt.Replace('"', '\"')
        $processArgs = @($copilotBaseArgs + @(
            '--',
            '-p',
            "`"$safePrompt`"",
            '--allow-all-tools'
        ))

        # Use Start-Process to handle arguments safely and stream to console
        Start-Process -FilePath $copilotExecutable -ArgumentList $processArgs -WorkingDirectory $repoRoot -NoNewWindow -Wait
    }
}

if ($Type -eq "daily") {
    # Reuse existing logic or call the existing script?
    # Better to keep logic self-contained if we want this to be the main entry point.
    # For now, let's call the existing script to avoid duplication if it exists, or reimplement.
    # The existing script is specific to daily. Let's call it.

    $dailyScript = Join-Path $repoRoot "coworker\scripts\workers\coworker-daily-memory-generator.ps1"
    if (Test-Path $dailyScript) {
        & $dailyScript -Date $Date
    } else {
        Write-Error "Daily memory generator script not found at $dailyScript"
    }
}
elseif ($Type -eq "monthly") {
    $targetDir = "$logsBaseDir\$year\$month"
    $targetFile = "$targetDir\MEMORY.$year$month.md"

    if (-not (Test-Path $targetDir)) {
        Write-Error "Directory $targetDir does not exist. No daily memories to summarize."
        exit 1
    }

    # Gather all daily memories for the month (stored under day subdirectories)
    $dailyMemories = Get-ChildItem -Path "$targetDir\*\MEMORY.*.md" | Where-Object { $_.Name -match "MEMORY\.\d{8}\.md$" }

    if ($dailyMemories.Count -eq 0) {
        Write-CoworkerLog -Component 'memory-generator' -Level 'WARN' -NoColor -Message "No daily memory files found for $year-$month."
        exit 0
    }

    $combinedContent = ""
    foreach ($file in ($dailyMemories | Sort-Object Name)) {
        $content = Get-Content $file.FullName -Raw
        $combinedContent += "`n`n=== DAILY MEMORY: $($file.Name) ===`n$content"
    }

    $prompt = @"
You are an AI assistant helping to generate a MONTHLY memory summary for a developer coworker.
Based on the following DAILY memories, generate the content for the MONTHLY memory file and save it to the ABSOLUTE path: $targetFile

SPECIFICATION (follow this structure exactly):
# MEMORY.$year$month.md
## Monthly Memory - $year-$month

### Work Themes
- Dominant task categories this month

### Recurring Issues
- Pattern A (appeared in multiple days)
- Pattern B

### Structural Bottlenecks
- Persistent constraints affecting efficiency

### Efficiency Trend
- Improving / Stable / Degrading
- Brief justification based on daily evidence

### System Adjustments Proposed
- 1. Concrete change to improve next month
- 2.

CONSTRAINTS:
- Use English only.
- Identify patterns across days, do NOT just list per-day summaries.
- Each section must reflect synthesis, not raw log repetition.
- Must include at least one recurring issue and one structural bottleneck.
- Maximum 2000 words.
- Use the `create` tool to write the file directly using the ABSOLUTE path: $targetFile (overwrite if exists).

DAILY MEMORIES:
$combinedContent
"@

    Invoke-GhCopilot -Prompt $prompt
}
elseif ($Type -eq "yearly") {
    $targetDir = "$logsBaseDir\$year"
    $targetFile = "$targetDir\MEMORY.$year.md"

    # Gather all monthly memories for the year (stored under month subdirectories)
    $monthlyMemories = Get-ChildItem -Path "$logsBaseDir\$year\*\MEMORY.$year*.md" | Where-Object { $_.Name -match "MEMORY\.\d{6}\.md$" }

    if ($monthlyMemories.Count -eq 0) {
        Write-CoworkerLog -Component 'memory-generator' -Level 'WARN' -NoColor -Message "No monthly memory files found for $year."
        exit 0
    }

    $combinedContent = ""
    foreach ($file in ($monthlyMemories | Sort-Object Name)) {
        $content = Get-Content $file.FullName -Raw
        $combinedContent += "`n`n=== MONTHLY MEMORY: $($file.Name) ===`n$content"
    }

    $prompt = @"
You are an AI assistant helping to generate a YEARLY memory summary for a developer coworker.
Based on the following MONTHLY memories, generate the content for the YEARLY memory file and save it to the ABSOLUTE path: $targetFile

SPECIFICATION (follow this structure exactly):
# MEMORY.$year.md
## Annual Strategic Review - $year

### Project State Evolution
- How the project changed during the year

### Major Achievements
- Key milestones reached this year

### Major Failures
- Significant setbacks and lessons learned

### Structural Problems (Solved / Unsolved)
- Solved: problems resolved during the year
- Unsolved: persistent issues entering the next year

### Capability Upgrades
- Skills or operational improvements gained

### Strategic Risks
- Risks entering the next year

### Project Trajectory Forecast
- 1-2 year outlook based on current trends

### Three Immediate Strategic Actions
- 1.
- 2.
- 3.

CONSTRAINTS:
- Use English only.
- Must differentiate solved vs unsolved structural problems.
- Synthesize monthly patterns into yearly-level strategic insights; do NOT merely repeat monthly content.
- Maximum 2000 words.
- Use the `create` tool to write the file directly using the ABSOLUTE path: $targetFile (overwrite if exists).

MONTHLY MEMORIES:
$combinedContent
"@

    Invoke-GhCopilot -Prompt $prompt
}
elseif ($Type -eq "global") {
    $targetFile = "$logsBaseDir\MEMORY.md"

    # Gather all yearly memories (stored under year subdirectories)
    $yearlyMemories = Get-ChildItem -Path "$logsBaseDir\*\MEMORY.*.md" | Where-Object { $_.Name -match "MEMORY\.\d{4}\.md" }

    if ($yearlyMemories.Count -eq 0) {
        # Fallback to monthly memories if no yearly summaries exist yet
        Write-CoworkerLog -Component 'memory-generator' -Level 'WARN' -NoColor -Message 'No yearly memory files found; falling back to monthly memories.'
        $yearlyMemories = Get-ChildItem -Path "$logsBaseDir\*\*\MEMORY.*.md" | Where-Object { $_.Name -match "MEMORY\.\d{6}\.md$" }
    }

    if ($yearlyMemories.Count -eq 0) {
        Write-CoworkerLog -Component 'memory-generator' -Level 'WARN' -NoColor -Message 'No memory files available for global summary generation.'
        exit 0
    }

    $combinedContent = ""
    foreach ($file in ($yearlyMemories | Sort-Object Name)) {
        $content = Get-Content $file.FullName -Raw
        $combinedContent += "`n`n=== MEMORY: $($file.Name) ===`n$content"
    }

    # Also read existing MEMORY.md to preserve Mission & Vision if it exists
    $existingGlobal = ""
    if (Test-Path $targetFile) {
        $existingGlobal = "`n`n=== EXISTING GLOBAL MEMORY (preserve Mission & Vision) ===`n" + (Get-Content $targetFile -Raw)
    }

    $prompt = @"
You are an AI assistant helping to generate or update the GLOBAL memory for a developer coworker project.
Based on the accumulated memory files, generate the content for the global memory file and save it to the ABSOLUTE path: $targetFile

SPECIFICATION (follow this structure exactly):
# MEMORY.md

## Mission & Vision
- Why the project exists (preserve from existing if already defined)

## Core Principles
- Non-negotiable operational rules

## Evolution Phases
- Phase 1:
- Phase 2:
- (add more as needed)

## Major Turning Points
- Key moments that changed project direction

## Long-Term Structural Challenges
- Ongoing issues that span multiple years

## Opportunity Landscape
- Strategic opportunity areas

## Three Strategic Priorities Now
- 1.
- 2.
- 3.

CONSTRAINTS:
- Use English only.
- Must summarize all provided yearly/monthly memories.
- Must identify project phases and turning points.
- Preserve Mission & Vision from the existing MEMORY.md unless the content clearly indicates it should change.
- Maximum 2000 words.
- Use the `create` tool to write the file directly using the ABSOLUTE path: $targetFile (overwrite if exists).

MEMORY FILES:
$combinedContent
$existingGlobal
"@

    Invoke-GhCopilot -Prompt $prompt
}
elseif ($Type -eq "init") {
    $year = $parsedDate.ToString("yyyy")
    $month = $parsedDate.ToString("MM")
    $day = $parsedDate.ToString("dd")

    # 1. Define paths
    $memoryDir = $logsBaseDir
    $memoryYearDir = Join-Path $memoryDir $year
    $memoryMonthDir = Join-Path $memoryYearDir $month
    $memoryDayDir = Join-Path $memoryMonthDir $day

    # 2. Ensure directories exist
    if (-not (Test-Path $memoryYearDir)) { New-Item -ItemType Directory -Path $memoryYearDir -Force | Out-Null }
    if (-not (Test-Path $memoryMonthDir)) { New-Item -ItemType Directory -Path $memoryMonthDir -Force | Out-Null }
    if (-not (Test-Path $memoryDayDir)) { New-Item -ItemType Directory -Path $memoryDayDir -Force | Out-Null }

    $memoryYearPath = Join-Path $memoryYearDir "MEMORY.$year.md"
    $memoryMonthPath = Join-Path $memoryMonthDir "MEMORY.$year$month.md"
    $memoryDayPath = Join-Path $memoryDayDir "MEMORY.$year$month$day.md"
    $memoryDayLongPath = Join-Path $memoryDayDir "MEMORY.$year$month$day.long.md"

    # 3. Check Daily Memory Size and Compress if needed
    if (Test-Path $memoryDayPath) {
        $dailyContent = Get-Content $memoryDayPath -Raw -Encoding UTF8
        if ($dailyContent.Length -gt 3000) {
            Write-CoworkerLog -Component 'memory-generator' -Level 'WARN' -NoColor -Message "Daily memory length is $($dailyContent.Length) chars (>3000); starting compression."

            # Backup
            Copy-Item -Path $memoryDayPath -Destination $memoryDayLongPath -Force
            Write-CoworkerLog -Component 'memory-generator' -Level 'WARN' -NoColor -Message "Backed up original daily memory to: $memoryDayLongPath"

            # Compress
            $compressPrompt = "Compress the following daily memory content to under 3000 characters. Preserve key insights and structural learnings. content:`n$dailyContent"

            # Compress using gh copilot
            # We need to capture the output here.
            # But wait, Invoke-GhCopilot prints to host by default unless I use -CaptureOutput
            $compressedContent = Invoke-GhCopilot -Prompt $compressPrompt -CaptureOutput

            if (-not [string]::IsNullOrWhiteSpace($compressedContent)) {
                 # The output might contain explanation text. Copilot CLI usually just answers if prompted correctly.
                 # But sometimes it chats.
                 # Assuming it returns markdown.
                 $compressedContent | Out-File -FilePath $memoryDayPath -Encoding UTF8 -Force
                 Write-CoworkerLog -Component 'memory-generator' -Level 'WARN' -NoColor -Message "Compression complete: daily memory now $($compressedContent.Length) chars."
            }
        }
    } else {
        # Create empty daily memory if not exists?
        # Maybe unnecessary, Agent will create it.
        # But for context string, it's good to know.
    }

    # 4. Construct Context String
    $memoryContext = ""
    if (Test-Path $memoryMonthPath) {
        $monthContent = Get-Content $memoryMonthPath -Raw -Encoding UTF8
        $memoryContext += "`n[Monthly Memory ($year-$month)]:`n$monthContent`n"
    }

    if (Test-Path $memoryDayPath) {
        $dayContent = Get-Content $memoryDayPath -Raw -Encoding UTF8
        $memoryContext += "`n[Daily Memory ($year-$month-$day)]:`n$dayContent`n"
    }

    # 5. Construct Instructions String
    $memoryInstructions = @"
*** MEMORY UPDATE INSTRUCTIONS ***
You have a memory system to help you learn and improve.
Your memory files are located in: $logsBaseDir

After completing the task, you MUST update your daily memory file: $memoryDayPath
1. Append a summary of this task, its outcome, and any lessons learned to $memoryDayPath.
2. Check if the Monthly Memory file ($memoryMonthPath) has been updated with the previous day's summary. If not, summarize all daily memories from this month (excluding today) into the Monthly Memory.
3. Ensure you do not overwrite existing content, always append.
"@

    # 6. Output JSON
    $result = @{
        context = $memoryContext
        instructions = $memoryInstructions
    }

    $json = $result | ConvertTo-Json -Depth 2
    Write-Output $json
}
