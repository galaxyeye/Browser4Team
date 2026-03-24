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
