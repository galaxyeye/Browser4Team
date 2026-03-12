# Remove MCP Client Feature

SKILLs + CLI is the better way to use tools. Browser4 will no longer support the MCP Client feature, which is a legacy 
method for integrating tools. 

Remove all code related to the MCP Client feature, including any references in documentation and tests.

> IMPORTANT: Keep the MCP Server feature intact, as it may still be used by some users. Only remove the client-side code and references.

## References

[MCPBootstrap.kt](../../../submodules/Browser4/pulsar-agentic/src/main/kotlin/ai/platon/pulsar/agentic/mcp/MCPBootstrap.kt)
[MCPClientManager.kt](../../../submodules/Browser4/pulsar-agentic/src/main/kotlin/ai/platon/pulsar/agentic/mcp/MCPClientManager.kt)
[MCPConfig.kt](../../../submodules/Browser4/pulsar-agentic/src/main/kotlin/ai/platon/pulsar/agentic/mcp/MCPConfig.kt)
[MCPPluginRegistry.kt](../../../submodules/Browser4/pulsar-agentic/src/main/kotlin/ai/platon/pulsar/agentic/mcp/MCPPluginRegistry.kt)
[MCPServersConfigLoader.kt](../../../submodules/Browser4/pulsar-agentic/src/main/kotlin/ai/platon/pulsar/agentic/mcp/MCPServersConfigLoader.kt)
[MCPToolExecutor.kt](../../../submodules/Browser4/pulsar-agentic/src/main/kotlin/ai/platon/pulsar/agentic/mcp/MCPToolExecutor.kt)
[README.md](../../../submodules/Browser4/pulsar-agentic/src/main/kotlin/ai/platon/pulsar/agentic/mcp/README.md)