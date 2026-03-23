# Estimate Plan to Implementation

What more information do you need to implement the plan outlined in the following document?

[1.2.md](refine/3done/1.2.md)

## Missing Information / Clarifications Needed

1.  **Backend Tool Exposure**:
    -   Verify if `agent_act`, `agent_extract`, `agent_summarize` tools are explicitly exposed via `MCPToolController`. While `AgentToolExecutor` has generic mapping, `MCPToolController.listTools` does not list them. Need to confirm if unlisted tools can be called directly or if `listTools` needs updating.

2.  **Agent Run Implementation**:
    -   Confirm if `browser4-cli agent run` should mix REST API calls (`/api/commands/plain`) with MCP calls. The plan suggests forwarding to `CommandController`, which implies using REST for async task submission and status polling, bypassing the synchronous `agent_run` MCP tool.

3.  **Collective Mode Architecture**:
    -   Clarify the persistence mechanism for `collective` mode queue. The CLI dependencies include `serde_json` but no database (SQLite). Should the queue be file-based (JSON)?
    -   Define the concurrency model for `collective` tasks. Does "distributed" imply multiple CLI instances coordination, or just one CLI instance managing multiple local threads/connections to the server?
    -   Does `co create` start a background daemon process (similar to `daemon.rs` but for task management) or just configure local state?

4.  **Collective "Submit" Semantics**:
    -   Does `co submit` add to a queue for a background worker, or does it block until completion? The presence of `-deadline` suggests a scheduler/queue system.
