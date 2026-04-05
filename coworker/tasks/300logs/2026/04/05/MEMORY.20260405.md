# MEMORY.20260405.md

## Stabilize browser4-cli interaction E2E focus handling

- **Context**: `sdks/browser4-cli/tests/e2e.rs` intermittently timed out in `test_e2e_interaction_console_and_export` after selector-targeted interactions, especially around the `click` -> `keydown` / `keyup` sequence.
- **Action**:
    - Updated `sdks/browser4-cli/src/main.rs` to persist the last selector-targeted element in CLI state and restore focus to that saved selector before bare `keydown`/`keyup` commands run.
    - Cleared the saved active selector and last mouse position when sessions are created or invalidated so stale state does not leak across sessions.
    - Routed `keydown` and `keyup` through the new focus-restore handler and added unit coverage for selector tracking.
    - Reformatted the Rust CLI crate and validated the targeted interaction scenario with `cargo test --test e2e -- --scenario test_interaction_console_and_export`, plus a clean `.\mvnw.cmd -q -D"skipTests"` rebuild.
- **Outcome**: The interaction E2E no longer relies on fragile carry-over browser focus between CLI invocations; the targeted scenario now passes after the CLI restores focus from persisted state before keyboard-only commands.
- **Lessons Learned**:
    - CLI commands that span multiple invocations need explicit persisted UI context; relying on browser focus to survive snapshots or later calls is flaky.
    - When validating Browser4 CLI E2Es on Windows, avoid overlapping jar rebuilds with jar-backed E2E runs or transient file-lock/startup failures can obscure the actual code-change result.
