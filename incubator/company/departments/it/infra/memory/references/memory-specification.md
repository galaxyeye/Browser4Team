# Coworker Memory System

**Official Specification**
Version: 2.0
Status: Active
Language: English only
Size limits: daily ≤ 3000 characters; monthly/yearly ≤ 12000 characters (~2000 words at ≈6 chars/word); global ≤ 6000 characters (~1000 words); `.long.md` backups have no enforced limit but should stay under 500 KB

---

# 1. Purpose

The Coworker Memory System is a structured, layered operational memory architecture designed to:

1. Prevent repeated mistakes across sessions
2. Improve execution quality over time through reflection
3. Detect recurring structural issues before they compound
4. Track capability and process evolution
5. Supply relevant context to every new task without exceeding token budgets

This system is **not** a log viewer or activity tracker.
It is a continuous reflection and evolution framework that turns raw execution history into actionable knowledge.

---

# 2. Architectural Model

The memory system follows a four-layer abstraction hierarchy:

| Layer   | File name pattern       | Scope                  | Primary function                        | Abstraction level | Updated when              |
| ------- | ----------------------- | ---------------------- | --------------------------------------- | ----------------- | ------------------------- |
| Daily   | `MEMORY.YYYYMMDD.md`    | Single UTC day         | Operational reflection per task         | Low               | After every coworker task |
| Monthly | `MEMORY.YYYYMM.md`      | 1 calendar month       | Pattern recognition across days         | Medium            | Daily, if stale           |
| Yearly  | `MEMORY.YYYY.md`        | 1 calendar year        | Strategic review across months          | High              | Daily, if stale           |
| Global  | `MEMORY.md`             | Entire project history | Constitutional + evolutionary narrative | Highest           | Daily, if stale           |

Each higher layer must increase abstraction level.
No layer should merely repeat the content of lower layers.

---

# 3. File System Layout

All memory files live under the coworker logs base directory:

```
coworker/tasks/300logs/
├── MEMORY.md                          # Global memory
├── 2026/
│   ├── MEMORY.2026.md                 # Yearly memory
│   └── 03/
│       ├── MEMORY.202603.md           # Monthly memory
│       └── 12/
│           ├── MEMORY.20260312.md     # Daily memory (compressed, ≤ 3000 chars)
│           └── MEMORY.20260312.long.md  # Daily memory backup (full, pre-compression)
```

Rules:

* All directories are created automatically by the generator before writing.
* All files are UTF-8 encoded.
* All dates and timestamps use UTC.

---

# 4. Update Triggers

| Layer   | Trigger                                      | Generator command                                  |
| ------- | -------------------------------------------- | -------------------------------------------------- |
| Daily   | After each coworker task completes           | `coworker-memory-generator.ps1 -Type daily`        |
| Monthly | When `init` detects the monthly file is stale | `coworker-memory-generator.ps1 -Type monthly`      |
| Yearly  | When `init` detects the yearly file is stale  | `coworker-memory-generator.ps1 -Type yearly`       |
| Global  | When `init` detects the global file is stale  | `coworker-memory-generator.ps1 -Type global`       |

The `init` type is called automatically by `coworker.ps1` before each task. It:

1. Creates missing directories.
2. Detects whether the monthly, yearly, and global files have been updated for the current day.
3. Compresses the daily file if it exceeds 3000 characters (backing up the original to `.long.md`).
4. Returns a JSON object with `context` (memory content to prepend to the task prompt) and `instructions` (rules telling the agent to update memory after completion).

---

# 5. Core Principles

## 5.1 Append-Then-Compress (Daily)

* The daily file is appended to after every task in a session.
* When the file exceeds 3000 characters, the generator:
  1. Copies the full content to `MEMORY.YYYYMMDD.long.md` (permanent backup).
  2. Asks Copilot to compress the content to under 3000 characters, preserving key insights.
  3. Overwrites `MEMORY.YYYYMMDD.md` with the compressed version.
* The `.long.md` file is never modified after creation.

## 5.2 Regeneration (Monthly / Yearly / Global)

* Monthly, Yearly, and Global files are **regenerated** (not appended to) by their generator.
* Regeneration reads all lower-layer files, synthesizes them into new content, and overwrites the target file.
* The Global file's `Mission & Vision` section is preserved from the previous version unless explicitly revised.

## 5.3 Reflection Over Reporting

Every memory entry must answer at least one of:

* Why did this happen?
* What pattern is this an instance of?
* What systemic improvement does this suggest?

Simply listing what was done is insufficient. Entries without analytical value must not be written.

## 5.4 Structural Thinking

All layers must prioritize:

* Recurring issue detection (same root cause appearing on multiple days)
* Root cause analysis (not just symptom description)
* Process evolution (what changed in how work is done)
* Capability development (new tools, skills, or approaches acquired)

## 5.5 Token Budget Awareness

Memory content is injected into every task prompt. Overly long context wastes tokens and degrades agent focus.

* Daily file: hard limit of 3000 characters (~600 words at ≈5 chars/word), enforced by auto-compression.
* Monthly / Yearly files: aim for under 12000 characters (~2000 words at ≈6 chars/word); never exceed that.
* Global file: aim for under 6000 characters (~1000 words); this file is loaded into every task prompt — conciseness is critical.
* Prefer dense, insight-rich bullet points over explanatory prose.

---

# 6. Daily Memory Specification

**File:** `coworker/tasks/300logs/YYYY/MM/DD/MEMORY.YYYYMMDD.md`
**Backup:** `coworker/tasks/300logs/YYYY/MM/DD/MEMORY.YYYYMMDD.long.md`

Structure:

```markdown
# MEMORY.YYYYMMDD.md
## Daily Memory - YYYY-MM-DD

### Tasks Executed
- **<Task name>**: <What was done>. **Outcome:** <Result>. **Learning:** <Concrete lesson>.
- …

### Execution Quality Review
- Worked well: <specific technique or approach that succeeded>
- Inefficient: <specific step that wasted time or caused errors>

### Issues Encountered
- <Issue>: <Brief description of the problem and how it was resolved or deferred>

### Root Cause Analysis
- <Issue ref>: <Why it happened at a structural level, not just what happened>

### Process Improvement Insight
- <At least one concrete, actionable improvement applicable to future executions>
```

Quality rules:

* Each "Tasks Executed" entry must include Outcome and Learning sub-fields.
* "Root Cause Analysis" must go one level deeper than "Issues Encountered" — it explains *why*, not just *what*.
* "Process Improvement Insight" must be actionable on the next run — not vague advice.
* Maximum 3000 characters (auto-compressed if exceeded).
* UTF-8 encoding, UTC dates.

**Good example entry:**
```
- **PowerShell arg quoting fix**: Switched from `-ArgumentList $str` to `-ArgumentList @($str)` in three scripts. **Outcome:** Resolved "too many arguments" errors in gh copilot calls. **Learning:** Always use array form for ArgumentList when passing user-generated strings to CLI tools.
```

**Bad example entry:**
```
- Fixed a bug in the script.
```

---

# 7. Monthly Memory Specification

**File:** `coworker/tasks/300logs/YYYY/MM/MEMORY.YYYYMM.md`

Structure:

```markdown
# MEMORY.YYYYMM.md
## Monthly Memory - YYYY-MM

### Work Themes
- <Theme 1>: <Description of dominant task category and why it dominated>
- <Theme 2>: …

### Recurring Issues
- **<Issue pattern>**: Appeared on <N> days. Root cause: <structural explanation>. Status: Resolved / Ongoing.
- …

### Structural Bottlenecks
- **<Bottleneck>**: <How it limits throughput or quality. Whether it is being addressed.>
- …

### Efficiency Trend
- Trend: Improving / Stable / Degrading
- Evidence: <Specific changes observed across daily memories that justify the trend>

### System Adjustments Proposed
- 1. <Concrete change to scripts, workflow, or tooling — with rationale>
- 2. …
```

Quality rules:

* Must be derived from all daily memories within the month.
* A "Recurring Issue" requires evidence from **at least 3 separate days** sharing the **same structural root cause** (similar surface symptoms with different root causes must be listed as separate issues).
* "System Adjustments Proposed" must be specific — name the script, config, or process to change.
* Must NOT copy daily entries verbatim; every section must synthesize, not paste.
* Maximum 12000 characters.
* May be regenerated.
* If a section has no entries (e.g., no structural bottlenecks this month), write "None this month." — do not leave bullets empty or write "N/A".

**Good example (Recurring Issues):**
```
- **Relative path failures in helper scripts**: Appeared on 6 days. Scripts called from the scheduler resolved paths relative to the scheduler working directory, not the script directory. Addressed by switching all helpers to $PSScriptRoot-based paths on 2026-03-08. Status: Resolved.
```

**Bad example (Recurring Issues):**
```
- There were some path issues.
```

---

# 8. Yearly Memory Specification

**File:** `coworker/tasks/300logs/YYYY/MEMORY.YYYY.md`

Structure:

```markdown
# MEMORY.YYYY.md
## Annual Strategic Review - YYYY

### Project State Evolution
- <How the project matured or pivoted during the year — scope changes, architectural shifts, team growth>

### Major Achievements
- <Milestone>: <Why it mattered strategically>
- …

### Major Failures
- <Failure>: <Root cause and lesson learned>
- …

### Structural Problems
- **Solved:** <Problem> — <How it was resolved>
- **Unsolved:** <Problem> — <Why it persists and planned mitigation>

### Capability Upgrades
- <Skill / tool / process>: <How it changed execution quality>
- …

### Strategic Risks
- <Risk>: <Likelihood, impact, and mitigation plan for the coming year>
- …

### Project Trajectory Forecast
- <1–2 year outlook grounded in current trends and open problems>

### Three Immediate Strategic Actions
- 1. <Highest-priority action for the start of next year>
- 2. …
- 3. …
```

Quality rules:

* Must be derived from all monthly memories of the year.
* "Structural Problems" must explicitly label each item as **Solved** or **Unsolved**:
  * **Solved** = root cause addressed and the issue has not recurred for at least one month.
  * **Unsolved** = issue still persists, or a workaround is in place but the root cause remains.
* "Three Immediate Strategic Actions" must be executable in the first month of the next year.
* Must NOT repeat monthly content verbatim; abstract to year-level strategic insight.
* Maximum 12000 characters.
* May be regenerated.
* If a section has no entries (e.g., no major failures), write "None this year." — do not leave bullets empty.

---

# 9. Global Memory Specification

**File:** `coworker/tasks/300logs/MEMORY.md`

Role: The project's Constitution and Evolution Chronicle.
This file is loaded at the start of every task as the highest-level context.
It defines who the project is, where it came from, and where it is going.

Structure:

```markdown
# MEMORY.md

## Mission & Vision
- Mission: <One sentence: what the project does and for whom>
- Vision: <One sentence: what success looks like in the long run>

## Core Principles
- <Principle>: <Why it is non-negotiable>
- …

## Evolution Phases
- Phase 1 (<date range>): <What defined this phase>
- Phase 2 (<date range>): <What defined this phase>
- …

## Major Turning Points
- <Date>: <Event and why it changed the project's direction>
- …

## Long-Term Structural Challenges
- <Challenge>: <Why it persists and its strategic implications>
- …

## Opportunity Landscape
- <Opportunity>: <Why it is strategically significant now>
- …

## Three Strategic Priorities Now
- 1. <Current most important focus>
- 2. …
- 3. …
```

Quality rules:

* Must summarize all yearly memories.
* Must identify project phases and major turning points — not just themes.
* `Mission & Vision` must be preserved from the previous version unless explicitly changed.
* Maximum 6000 characters (this file is loaded into every task prompt; conciseness is critical).
* May be regenerated but requires explicit instruction to revise `Mission & Vision`.
* If a section has no entries yet, write a single sentence explaining why (e.g., "No turning points recorded in the first quarter.") — do not leave bullets empty.

---

# 10. Abstraction Rules

Each higher layer must:

1. **Compress** lower-layer content — remove per-task noise, retain structural insights.
2. **Synthesize** — identify patterns across multiple lower-layer entries; never copy-paste.
3. **Escalate** — surface only issues and insights with strategic significance at the current layer.
4. **Drop** operational detail — specific file names, line numbers, and one-off incidents belong in daily memory only.

Violation: any higher-layer entry that could have come directly from a lower-layer entry without synthesis.

---

# 11. Prohibited Behaviors

The system must never:

* Write a daily entry that contains no Outcome or Learning field.
* Write a monthly/yearly recurring issue with evidence from fewer than 2 days.
* Exceed the character/word limits for any layer.
* Rewrite or delete the `.long.md` backup file.
* Modify a daily file for a past date (the append-then-compress flow is for the current day only).
* Produce `Mission & Vision` that contradicts the previous version without explicit revision instruction.
* Fill any section with empty placeholder bullets. If a section has no content, write a concise sentence explaining why (e.g., "None this month." or "No major failures in the first quarter.") rather than leaving bullets blank.

---

# 12. Context Injection Workflow

Before each task, `coworker.ps1` calls `coworker-memory-generator.ps1 -Type init`, which:

1. Ensures the daily/monthly/yearly directory structure exists.
2. Reads the current day's daily memory (if it exists) and the current month's monthly memory.
3. Compresses the daily file if it exceeds 3000 characters.
4. Returns a JSON payload:

```json
{
  "context": "<monthly memory content>\n<daily memory content>",
  "instructions": "*** MEMORY UPDATE INSTRUCTIONS ***\n..."
}
```

5. The context and instructions are appended to every task prompt.

The agent must:

* Read the injected context before starting the task.
* Append a new entry to the daily memory file after the task completes.
* Check whether the monthly memory covers the previous day; if not, regenerate it.

---

# 13. Bootstrap / First Run

When no memory files exist:

* Skip context injection (nothing to inject).
* After the first task, create the daily memory file with the standard structure.
* Do not create a monthly file until **at least 3 daily files** exist for the month (pattern detection requires multiple data points).
* Do not create a yearly file until at least 1 monthly file exists.
* Do not create a global file until at least 1 yearly file exists.

When memory files exist but are stale (today's daily is missing):

* Proceed with the last available daily and monthly memory as context.
* Create a new daily file for today after the task completes.

---

# 14. Generator Scripts

| Script                                    | Purpose                                      |
| ----------------------------------------- | -------------------------------------------- |
| `coworker-memory-generator.ps1 -Type init`    | Initialize context before a task             |
| `coworker-memory-generator.ps1 -Type daily`   | Delegate to daily generator (post-task)      |
| `coworker-memory-generator.ps1 -Type monthly` | Regenerate monthly from all daily files      |
| `coworker-memory-generator.ps1 -Type yearly`  | Regenerate yearly from all monthly files     |
| `coworker-memory-generator.ps1 -Type global`  | Regenerate global from yearly + existing global |
| `coworker-daily-memory-generator.ps1`         | Batch-process daily logs and write daily file |

All scripts live in `coworker/scripts/workers/`.

---

# 15. Evolution Philosophy

The Coworker Memory System is designed to produce a virtuous cycle:

```
Execution → Reflection → Pattern Detection → Structural Adjustment → Strategic Evolution
```

If used consistently and correctly, the system enables:

* Reduced repetition of mistakes across sessions
* Measurable efficiency improvement over months
* Capability and process tracking over years
* Strategic continuity despite agent statelessness

The system fails when entries are superficial, sections are skipped, or higher layers merely repeat lower-layer content.
The system succeeds when reading any memory file immediately surfaces a decision-relevant insight.

---
