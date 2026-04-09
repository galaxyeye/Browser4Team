# MEMORY.20260408.md

## Fix MCP tool listing in pulsar-rest

- **Context**: `pulsar-rest/src/main/kotlin/ai/platon/pulsar/rest/mcp/controller/MCPToolController.kt` exposed `GET /mcp/tools` from a hard-coded list that had drifted from the actual `callTool()` execution path. The controller could resolve tools dynamically from the agent tool registry plus frontend aliases and legacy names, so the static listing could miss callable tools or advertise names that were not really backed by the current runtime registry.
- **Action**:
    - Reworked `listTools()` to discover canonical MCP tool names from the live `AgentToolExecutor` specs, reusing an existing session when possible and creating a temporary session only when discovery needs one.
    - Added filtering layers so session-management tools, controller-supported legacy names (`page_url`, `tab_list`, `keydown`, etc.), and browser4-cli-facing aliases/composite names (`browser_tabs`, `browser_keydown`, `browser_click`, etc.) are only listed when their underlying callable tools are actually available.
    - Added focused unit coverage in `pulsar-rest/src/test/kotlin/ai/platon/pulsar/rest/mcp/controller/MCPToolControllerTest.kt` for alias filtering and the temporary-session fallback path.
    - Validated with `.\mvnw.cmd -pl pulsar-rest -am -D"test=MCPToolControllerTest" -D"surefire.failIfNoSpecifiedTests=false" test` and `.\mvnw.cmd -P pulsar-tests -pl pulsar-tests/pulsar-rest-tests -am -D"test=MCPToolControllerE2ETest#testToolsEndpointCoversAllCliCommands" -D"surefire.failIfNoSpecifiedTests=false" -D"surefire.excludedGroups=None" test`.
- **Outcome**: `/mcp/tools` now reports the controller’s real callable surface instead of a stale hard-coded subset, so browser4-cli-facing MCP discovery stays aligned with the same registry and normalization rules used for actual tool execution.
- **Lessons Learned**:
    - Tool-listing endpoints should derive from the same runtime registry and normalization path as tool execution; hard-coded alias lists inevitably drift.
    - When a REST capability catalog depends on session-scoped executors, a short-lived discovery session is safer than maintaining a second static source of truth.
