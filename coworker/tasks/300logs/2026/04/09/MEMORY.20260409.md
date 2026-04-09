# MEMORY.20260409.md

## Refactor high-level agent tools

- **Context**: The high-level agent tool packages still lived directly under `ai.platon.pulsar.agentic.tools.{command,agent,crawl}` even though the target structure was `tools.high.{command,agent,crawl}`. The move needed to stay consistent across both `pulsar-agentic` and `pulsar-tools`, plus every REST/controller/test import that depends on those types.
- **Action**:
    - Moved the command, agent, and crawl Kotlin sources into `pulsar-agentic/.../tools/high/...` and moved the shared crawl models/common helpers into `pulsar-tools/.../tools/high/crawl/...`, updating package declarations and all downstream imports/typealiases.
    - Removed the empty legacy package directories after the move so the source tree now reflects the requested `tools/high/*` layout.
    - While validating, fixed `pulsar-rest` `MCPToolController.listTools()` so it again derives advertised tools from live `AgentToolExecutor` specs, including temporary-session fallback plus frontend/legacy alias filtering; this was required because the targeted MCP test slice exposed stale hard-coded listing behavior.
    - Validated with `.\mvnw.cmd -q -D"skipTests" compile`, `.\mvnw.cmd -q -pl pulsar-rest -am -D"test=MCPToolControllerTest" -D"surefire.failIfNoSpecifiedTests=false" test`, and `.\mvnw.cmd -q -P pulsar-tests -pl pulsar-tests/pulsar-rest-tests -am -D"test=CommandStatusConversionTest,CommandServiceTest,ScrapeServiceTests,ScrapeAPITests" -D"surefire.failIfNoSpecifiedTests=false" test`.
- **Outcome**: High-level tool packages now live under `tools.high`, all Kotlin consumers resolve the new namespaces, and the MCP tools endpoint stays aligned with the runtime registry instead of a stale static list.
- **Lessons Learned**:
    - Namespace refactors that cross module boundaries should be validated with both compile-time consumers and runtime discovery surfaces, because registry/listing endpoints can drift even when imports compile cleanly.
    - For MCP/CLI compatibility layers, advertise tool names from the same live registry and alias-normalization rules used for execution rather than maintaining a separate hard-coded catalog.
