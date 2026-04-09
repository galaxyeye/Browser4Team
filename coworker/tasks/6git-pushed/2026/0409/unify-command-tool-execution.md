# Refactor commandToolExecutor functionality

Add CommandToolExecutor functionality in AgentToolExecutor so we can use the unified interface to call command tools by
calling `agent.toolExtractor.execute(toolCall)`.

Note:

The key point is to add a branch in `ai.platon.pulsar.agentic.tools.AgentToolExecutor.execute` to call CommandToolExecutor
when the toolCall is a command tool call.

Also improve MCPToolController to remove the dependency on CommandToolExecutor and use AgentToolExecutor instead. 
This will allow us to have a more unified interface for executing tools in the MCPToolController and make it easier to 
maintain and extend in the future.
