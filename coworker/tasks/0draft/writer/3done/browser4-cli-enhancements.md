# Plan: Browser4 CLI Enhancements

Create a comprehensive plan to upgrade `browser4-cli` by integrating features from `BasicBrowserAgent` and implementing 
the `browser4-cli-agent` and `browser4-cli-collective` requirements.

## Objectives

1.  **Align CLI with Agent Capabilities**: Update existing commands to leverage `BasicBrowserAgent` logic.
2.  **Introduce Advanced Modes**: Implement Agent and Collective modes.
3.  **Ensure Usability**: Provide robust documentation, help text, and examples.

## Planned Features

### 1. Enhance Existing Commands
Improve the following CLI commands based on `BasicBrowserAgent` implementation to ensure consistency and capability:
-   **`extract`**: Optimize for structured data extraction.
-   **`summarize`**: Enhance content summarization capabilities.

### 2. Implement Advanced Features

#### Agent Mode (`browser4-cli-agent`)
Implement the `browser4-cli agent` suite.

**Implementation Notes for `run` command:**
-   **Execution Delegation**: Forward requests to `ai.platon.pulsar.rest.api.controller.CommandController.submitPlainCommand` or implement behavior consistent with it.
-   **Async Handling**: Long-running operations must return immediately with a task identifier and provide a corresponding status query interface.

#### Collective Mode (`browser4-cli-collective`)
Implement the `browser4-cli collective` (or `co`) suite for parallel and distributed browser tasks.

### 3. Quality Assurance & Documentation
-   **Help Text**: Create standard Unix-style help (`--help`) for all features.
-   **Testing**: Develop tests for all new and updated features.
-   **Examples**: Create usage examples for documentation.
-   **Documentation**: Update `browser4-cli-agent.md` and `browser4-cli-collective.md`.

## References

- [browser4-cli-agent.md](../../200plan/features/browser4-cli/browser4-cli-agent.md)
- [browser4-cli-collective.md](../../../200plan/features/browser4-cli/browser4-cli-collective.md)
- [BasicBrowserAgent.kt](../../../../submodules/Browser4/pulsar-agentic/src/main/kotlin/ai/platon/pulsar/agentic/agents/BasicBrowserAgent.kt)
