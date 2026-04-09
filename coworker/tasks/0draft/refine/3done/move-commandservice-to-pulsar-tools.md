# Implement CommandToolExecutor for Agent Tools

Introduce `CommandToolExecutor`, extending `ToolExecutor` in `pulsar-agentic`, and have it delegate 
command execution to `CommandService`.

Update `MCPToolController` to support command tools and keep the behavior be consistent with the existing `CommandController`.

Update the CLI to use the `MCPToolController` API as its backend for command execution, and revise the related documentation.
