# MEMORY.20260410.md

## Add open-and-scroll-to-bottom command

- **Context**: The CLI was missing a single command that opens a URL in a new tab and scrolls that page to the bottom, even though the underlying browser stack already had the separate pieces for tab creation, navigation, scrolling, MCP routing, and CLI post-command snapshots.
- **Action**:
    - Added `WebDriver.openAndScrollToBottom(url)` as an MCP-exposed atomic helper that creates a new tab through `browser.newDriver(url)`, brings it to the front, waits for the body, and scrolls the new page to the bottom.
    - Wired the new action through `BrowserTabToolExecutor`, rebound the session to the new front tab in `AgentToolExecutor`, exposed the frontend alias `browser_open_and_scroll_to_bottom` in `MCPToolController`, and extended the Browser4 CLI Rust command list/help/docs plus the navigation E2E scenario.
    - Kept generated tool-spec mirrors in sync (`code-mirror/WebDriver.kt.txt`, `driver-tool-call-specs.json`) and added focused Kotlin/Rust coverage for command definition, help text, executor dispatch, and REST alias routing.
    - Validated with `cargo test --quiet open_and_scroll_to_bottom`, `cargo test --quiet open-and-scroll-to-bottom` (the CLI/browser E2E path reached a stale Browser4 service that did not yet have the new alias), `.\mvnw.cmd -q -pl pulsar-agentic -am -D"test=ExecutorsNamedArgsTest" -D"surefire.failIfNoSpecifiedTests=false" test`, and `.\mvnw.cmd -q -pl pulsar-rest -am -D"test=MCPToolControllerTest" -D"surefire.failIfNoSpecifiedTests=false" test`.
- **Outcome**: `browser4-cli open-and-scroll-to-bottom <url>` is now implemented end to end in source, advertised through MCP/frontend aliases, and documented alongside the rest of the CLI navigation surface.
- **Lessons Learned**:
    - For tab-opening actions invoked through the `tab` tool domain, rebinding the session to `browser.frontDriver` after the call is essential; otherwise follow-up snapshot/status calls keep targeting the old bound tab.
    - `MCPToolController` frontend alias wiring must use the normalized MCP snake_case name at the alias stage, not the original camelCase Kotlin method name, or listing/dispatch can diverge even when the underlying tool exists.
