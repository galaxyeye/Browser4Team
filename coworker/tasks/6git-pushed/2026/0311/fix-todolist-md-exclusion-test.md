2026-03-11 21:42:54.488  INFO [main] a.p.p.a.t.CustomToolRegistry - 鉁? Registered custom tool executor for domain: db
2026-03-11 21:42:54.488  INFO [outine#931] a.p.p.a.t.CustomToolRegistry - 鉁? Cleared all custom tool executors
2026-03-11 21:42:54.488  INFO [outine#931] a.p.p.a.s.SkillRegistry - 鉁? Cleared all skills
[INFO] Tests run: 19, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.027 s -- in ai.platon.pulsar.agentic.tools.ToolCallSpecificationRendererTest
[INFO]
[INFO] Results:
[INFO]
[ERROR] Failures:
[ERROR]   AgentFileSystemTest.describeExcludesTodolistMd:336 expected: <false> but was: <true>
[ERROR]   MCPAutoWiringTest.browserAgentActorAutoWiresMcpClientManagerAsTargetForMcpDomain:65 expected: <ai.platon.pulsar.agentic.mcp.MCPClientManager@4f7da3a2> but was: <null>
[ERROR]   MainSystemPromptCustomSkillInjectionTest.customSkillToolSpecsShouldAppearInSystemPromptToolList:38 # System Instructions ## Language - Default working language: **EN** - Always reply in the same language as the user request. --- ## File Handling - Prefer `fs.*` tools for file operations. - Use `... ==> expected: <true> but was: <false>
[ERROR]   MainSystemPromptCustomSkillInjectionTest.skillSummariesShouldAppearInSystemPromptWhenSkillsRegistered:64 System prompt should contain skill summaries section when skills are registered ==> expected: <true> but was: <false>
[ERROR]   MainSystemPromptCustomSkillInjectionTest.skillToolTypeDefinitionsShouldAppearInSystemPrompt:83 System prompt should contain skill tool type definitions header ==> expected: <true> but was: <false>
[INFO]
[ERROR] Tests run: 574, Failures: 5, Errors: 0, Skipped: 0
