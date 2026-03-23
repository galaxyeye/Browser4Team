# Improve coworker-daily-memory-generator

Generate two versions of the daily memory output: a longer version and a shorter version.

The longer version should follow the template defined in the memory specification and retain full detail for in-depth review.

The shorter version should distill the same content into concise bullet points that highlight the most important outcomes and learnings without unnecessary detail.

Both versions should be generated and maintained as part of the daily memory output. The longer version supports detailed review, while the shorter version provides a quick reference for use throughout the coworker workflow.

The longer version has no length limit. The shorter version must always remain under 3000 characters so it can be loaded at every step of the workflow without exceeding token limits. If the shorter version exceeds this limit, it should be compressed further to preserve only the most critical information.

This dual-format approach supports both comprehensive documentation and efficient day-to-day access for the team.

## References

[coworker-daily-memory-generator.ps1](../../../scripts/workers/coworker-daily-memory-generator.ps1)
[Longer Memory Example](../../../300logs/2026/03/10/MEMORY.20260310.long.md)
[Shorter Memory Example](../../../300logs/2026/03/10/MEMORY.20260310.md)
