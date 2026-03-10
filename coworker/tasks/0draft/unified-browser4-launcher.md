# Improve Browser4 Launcher

加一个统一入口（Launcher）
在同一个可执行 jar 里放一个主类，比如 Browser4LauncherKt

通过参数决定启动哪个：
java -jar Browser4.jar --app=agents
java -jar Browser4.jar --app=mcp

agents 模式启动 Browser4AgentsApplication.kt
mcp 模式启动 Browser4MCPServerRunner.kt

[Browser4AgentsApplication.kt](../../../../Browser4/Browser4-4.6/browser4/browser4-agents/src/main/kotlin/ai/platon/pulsar/app/Browser4AgentsApplication.kt)
[Browser4MCPServerRunner.kt](../../../../Browser4/Browser4-4.6/pulsar-agentic/src/main/kotlin/ai/platon/pulsar/agentic/mcp/server/Browser4MCPServerRunner.kt)
