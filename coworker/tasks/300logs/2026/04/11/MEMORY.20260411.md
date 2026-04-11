# MEMORY.20260411.md
## Daily Memory - 2026-04-11

- Fixed `RobustBrowserAgent` step logging so `lastCall` is resolved from the previous step's executed tool call instead of the freshly created step state, which had no action/result yet and logged `lastCall=null`. Added `RobustBrowserAgentTest` to lock in the regression by asserting the helper resolves the previous state's tool call. Maven validation succeeded with `-Dkotlin.compiler.daemon=false`; lesson: step-to-step diagnostics in the agent loop must read from inherited execution state, and when Kotlin daemon startup is flaky in this environment, disable it explicitly for reliable Maven verification.
