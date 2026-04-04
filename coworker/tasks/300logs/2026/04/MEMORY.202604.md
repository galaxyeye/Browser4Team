# MEMORY.202604.md
## Monthly Memory - 2026-04

### Daily Rollup Update (through 2026-03-31)
- No April daily memories existed before 2026-04-01, so there were no prior in-month entries to roll up yet.

### Daily Rollup Update (through 2026-04-03)
- **2026-04-01**: Repaired the agent-history status coverage in `pulsar-rest` after an initial timeout-focused mitigation proved incomplete. The final fix exposed `CommandStatus.agentHistory` in REST JSON, added serialization coverage, and reworked the E2E to submit asynchronously and poll the status endpoint until agent history appears. Focused `pulsar-rest-tests` validation passed. Key lesson: for slow agent-backed flows, prefer polling async status APIs over long synchronous HTTP waits, and verify DTO serialization explicitly at the REST boundary.

### Daily Rollup Reconciliation (through 2026-04-03)
- Rechecked the available April daily memory files before the 2026-04-04 update. Only `2026-04-01/MEMORY.20260401.md` existed before today; there were no daily memory files for 2026-04-02 or 2026-04-03, so no additional pre-2026-04-04 summaries were available to append beyond the existing 2026-04-01 rollup.

