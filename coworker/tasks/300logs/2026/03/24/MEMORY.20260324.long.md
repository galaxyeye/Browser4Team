## Update History Render Strategy Prompt

- **Context**: The `DefaultHistoryRenderStrategy` did not include the path to the history log in its output, making it difficult for the AI to know where to find the full history when it was truncated.
- **Action**: 
    - Updated `ExecutionContext` to include `historyLogPath`.
    - Updated `AgentStateManager` to populate `historyLogPath` when building execution contexts.
    - Updated `HistoryRenderStrategy` interface to accept an optional `logPath` argument in the `render` method.
    - Updated `DefaultHistoryRenderStrategy` to include the `logPath` in the output when history is compressed or available.
    - Fixed a bug in `DefaultHistoryRenderStrategy` where fields were being compressed incorrectly (inverted logic).
    - Updated `PromptBuilder` to pass the `logPath` from `ExecutionContext` to the `HistoryRenderStrategy`.
    - Added unit tests in `DefaultHistoryRenderStrategyTest` to verify the log path inclusion and correct compression behavior.
- **Outcome**: The agent prompt now includes the path to the persisted history log, allowing the AI to reference the full history if needed.
- **Lessons Learned**: 
    - When modifying interfaces used in prompts, ensure all call sites are updated.
    - Unit tests are crucial for verifying logic changes, especially when dealing with string formatting and conditional inclusion.
    - Debugging test failures by adding print statements and re-running can be very effective for understanding runtime behavior of complex logic like compression algorithms.

## Implement CLI Named Sessions

- **Context**: Browser4 CLI lacked proper isolation for named sessions (`-s name`) and ignored persistence/headed flags.
- **Action**: 
    - Modified `sdks/browser4-cli/src/state.rs` to store named sessions in dedicated `sessions/<name>.json` files instead of a single `cli-state.json`.
    - Updated `sdks/browser4-cli/src/commands.rs` to add `profile` option to `open` command and pass `headed`, `persistent`, and `profile` options in tool parameters.
    - Updated `sdks/browser4-cli/src/main.rs`:
        - `handle_open` now extracts capabilities (`headed`, `persistent`, `profilePath`) and passes them to `open_session`.
        - `create_session` now accepts `capabilities` JSON object.
        - `handle_list` now scans local session files in `~/.browser4/sessions/` and correlates them with active server sessions, displaying status (Active/Stale).
        - `handle_close_all` and `handle_delete_data` now properly clean up local session files.
- **Outcome**: CLI now correctly isolates named sessions, respects session capabilities, and provides accurate session listing and cleanup.
- **Lessons Learned**: 
    - When modifying CLI state logic, ensure backward compatibility or clear migration path.
    - Check existing code thoroughly before assuming gaps (e.g., env var support was partially present but overridden).
    - Rust's `serde_json` makes it easy to work with dynamic JSON structures for tool parameters.
