## PerceptiveAgent / Browser4 可执行工程拆分

在当前版本上创建新分支，并在新分支上完成以下任务。

## 任务目标

- `PerceptiveAgent#act` 支持 browser-cli 风格的工具命令，识别后直接走解析 + 工具执行链路，不进入 LLM 推理，从而降低成本和延迟。
- 优化 LLM message 中的 history 组装逻辑，用“最近步骤保留 + 老步骤压缩 + 外部引用/检查点”替代当前简单截断，减少 token 消耗并提高稳定性。
- 让 direct command 路径与 LLM 路径共用统一的 trace / transcript / state / metrics 持久化链路，做到可追溯、可审计、可监控、可回放。
- 对每一步的 `ExecutionContext` / `AgentState` 持久化，且日志目录按单个智能体任务隔离，方便排查与后续自修复。

---

## 代码落点

### 代理与执行入口

- `pulsar-agentic/src/main/kotlin/ai/platon/pulsar/agentic/PerceptiveAgent.kt`
    - 接口：`act(String)`、`act(ActionOptions)`、`run(...)`
- `pulsar-agentic/src/main/kotlin/ai/platon/pulsar/agentic/agents/BasicBrowserAgent.kt`
    - 当前 `act(String)` / `act(ActionOptions)` / `act(ObserveResult)` 的主要实现入口
- `pulsar-agentic/src/main/kotlin/ai/platon/pulsar/agentic/agents/RobustBrowserAgent.kt`
    - 更完整的代理执行、transcript 持久化与总结链路
- `pulsar-agentic/src/main/kotlin/ai/platon/pulsar/agentic/agents/TaskScopedBrowserAgent.kt`
    - 任务范围隔离，是后续“每个任务单独目录”最自然的收口点

### 命令解析、校验、执行

- `pulsar-agentic/src/main/kotlin/ai/platon/pulsar/agentic/common/SimpleKotlinParser.kt`
    - 已有工具表达式解析能力
- `pulsar-agentic/src/main/kotlin/ai/platon/pulsar/agentic/tools/util/ActionValidator.kt`
    - 已有工具调用校验能力，但当前未形成统一 fast path 接线
- `pulsar-agentic/src/main/kotlin/ai/platon/pulsar/agentic/tools/AgentToolExecutor.kt`
    - `executeToolCall(...)`、`execute(...)`
    - 当前已支持 `driver`、`browser`、`fs`、`shell`、`agent`、`system`、`skill`、`mcp` 等域

### Prompt / History / 持久化

- `pulsar-agentic/src/main/kotlin/ai/platon/pulsar/agentic/inference/PromptBuilder.kt`
    - `buildAgentStateHistoryMessage(...)` 当前是固定 head/tail 截断
- `pulsar-agentic/src/main/kotlin/ai/platon/pulsar/agentic/inference/AgentStateManager.kt`
    - `addToHistory(...)`、`addTrace(...)`、`writeExecutionContext(...)`、`writeAgentState(...)`、`writeActionResult(...)`、`writeProcessTrace(...)`
- `pulsar-agentic/src/main/kotlin/ai/platon/pulsar/agentic/inference/InferenceEngine.kt`
    - 模型交互与日志输出
- `pulsar-core/pulsar-third/pulsar-llm/src/main/kotlin/ai/platon/pulsar/external/logging/ChatModelLogger.kt`
    - LLM 请求/响应日志

### REST / MCP / CLI 入口

- `pulsar-rest/src/main/kotlin/ai/platon/pulsar/rest/api/service/CommandService.kt`
    - `executePlainCommandSync(...)`：plain command 无法规范化为 URL 命令时，走 agent path
- `pulsar-rest/src/main/kotlin/ai/platon/pulsar/rest/api/service/ConversationService.kt`
    - `normalizePlainCommand(...)`
- `pulsar-rest/src/main/kotlin/ai/platon/pulsar/rest/openapi/controller/AgentController.kt`
- `pulsar-rest/src/main/kotlin/ai/platon/pulsar/rest/openapi/controller/MCPToolController.kt`
- `pulsar-agentic/src/main/kotlin/ai/platon/pulsar/agentic/mcp/server/Browser4MCPServer.kt`
- `sdks/browser4-cli/src/program.ts`
- `sdks/browser4-cli/src/cli/daemon/command.ts`
- `sdks/browser4-cli/src/cli/daemon/commands.ts`

---

## 任务拆分

### PA-0 固化 direct command 合约、权限与拒绝策略

- 目标：
    - 把人工已经确认的决策固化为代码任务输入，避免 PA-1 实现时再反复讨论协议。
    - 人工审查意见为准：`【MCP风格，所有工具】`。
- 结论：
    - 命令语法采用 MCP 风格工具名/表达式。
    - direct command 默认允许所有已注册工具域，不额外做“仅 browser/driver”限制。
    - 失败路径不是 silent fallback 到 LLM，而是明确区分：
        - 语法无法识别：继续走原有自然语言 / LLM 路径。
        - 语法已识别但校验失败：直接拒绝并输出结构化错误。
        - 语法已识别且执行失败：按工具执行失败处理并记入 trace。
- 代码落点：
    - `pulsar-agentic/.../common/SimpleKotlinParser.kt`
    - `pulsar-agentic/.../tools/util/ActionValidator.kt`
    - `pulsar-agentic/.../tools/AgentToolExecutor.kt`
    - 如需配置开关，放到 agent 配置对象中，不要分散塞进 controller。
- 输出物：
    - 一份直接供 PA-1 使用的识别/校验矩阵：
        - 可识别示例
        - 不可识别示例
        - 校验失败示例
        - 执行失败示例
    - 明确 `fs` / `shell` / `system` 也属于允许域，但必须走统一校验和审计链路。
- 验收标准：
    - direct command 的输入分类标准清晰，PA-1 不需要再做协议猜测。
    - “识别失败”和“识别成功但拒绝”在行为上可区分。

### PA-1 为 agent `act(...)` 增加 direct command fast path

- 目标：
    - 在代理识别到 MCP 风格工具表达式时，直接走解析 + 校验 + 执行，不进入 LLM 推理。
- 主要代码落点：
    - `pulsar-agentic/src/main/kotlin/ai/platon/pulsar/agentic/agents/BasicBrowserAgent.kt`
        - `act(String)`
        - `act(ActionOptions)`
        - 如有必要新增私有 helper，例如 `tryExecuteDirectCommand(...)`
    - `pulsar-agentic/src/main/kotlin/ai/platon/pulsar/agentic/common/SimpleKotlinParser.kt`
    - `pulsar-agentic/src/main/kotlin/ai/platon/pulsar/agentic/tools/util/ActionValidator.kt`
    - `pulsar-agentic/src/main/kotlin/ai/platon/pulsar/agentic/tools/AgentToolExecutor.kt`
    - `pulsar-agentic/src/main/kotlin/ai/platon/pulsar/agentic/inference/AgentStateManager.kt`
- 实施内容：
    - 在 `BasicBrowserAgent.act(ActionOptions)` 早期增加 direct command 检测。
    - 如果 `action.action` 能被解析成工具表达式：
        - 构造 `ToolCall` / `ActionDescription`
        - 调用 `ActionValidator.validateToolCall(...)`
        - 校验成功后走 `AgentToolExecutor.executeToolCall(...)` 或统一封装后的执行入口
        - 把结果回填为现有 `ActResult` / `DetailedActResult`
        - 同步写入 `AgentStateManager` 的 history / trace / result 持久化
    - 如果不能解析成 direct command：
        - 继续保留当前 observe -> LLM -> action 的既有路径
    - 如果 direct command 解析成功但校验失败：
        - 不回退到 LLM，直接返回明确失败结果并记录 trace
- 特别要求：
    - 不要把 fast path 仅挂在 `PerceptiveAgent` 接口注释层，必须落在真实实现类中。
    - direct command 的结果格式要与现有 `ActResult` 保持兼容，避免上层入口分叉解析。
- 验收标准：
    - `agent.act("driver.click('...')")` 这类输入不触发 LLM 调用。
    - direct command 成功、拒绝、执行异常三类结果都能回写 state/trace。
    - 自然语言输入行为不变。
- 建议测试：
    - 新增 `BasicBrowserAgentDirectCommandTest.kt` 或同级测试类
    - 覆盖：
        - direct command 成功执行
        - direct command 校验失败
        - 非 direct command 继续走旧路径

### PA-2 补齐 direct command 的入口与回归测试覆盖

- 目标：
    - 确保 fast path 不只在 agent 内部可用，也能被现有 REST / MCP / CLI 入口稳定触发。
- 主要代码与测试落点：
    - `pulsar-rest/.../api/service/CommandService.kt`
    - `pulsar-rest/.../openapi/controller/AgentController.kt`
    - `pulsar-rest/.../openapi/controller/MCPToolController.kt`
    - `pulsar-agentic/.../mcp/server/Browser4MCPServer.kt`
    - `sdks/browser4-cli/src/program.ts`
    - `sdks/browser4-cli/src/cli/daemon/command.ts`
    - `sdks/browser4-cli/src/cli/daemon/commands.ts`
    - 测试优先级：
        - `pulsar-rest/.../MCPToolControllerTest.kt`
        - 新增 `CommandServiceTest.kt`
        - 如当前不存在则新增 `AgentControllerTest.kt`
        - `sdks/browser4-cli/tests/commands.test.ts`
        - `sdks/browser4-cli/tests/program.test.ts`
- 实施内容：
    - 验证 plain command 进入 agent path 时，direct command 能在 agent 内部被稳定识别。
    - 验证 MCP 入口和 CLI 入口传入的工具表达式，不会因为字符串预处理差异而失真。
    - 验证 direct command 与普通自然语言路径在输出结构、错误格式、事件记录上保持一致。
- 验收标准：
    - REST / MCP / CLI 至少各有一个 direct command happy path 测试。
    - 至少覆盖一个“校验失败”和一个“执行失败”场景。
    - 不引入新的入口层协议分叉。

### PA-3 抽离 history 渲染/压缩策略

- 目标：
    - 把当前 `PromptBuilder.buildAgentStateHistoryMessage(...)` 中固定 head/tail 截断，重构为可替换的 history rendering/compression strategy。
- 主要代码落点：
    - `pulsar-agentic/src/main/kotlin/ai/platon/pulsar/agentic/inference/PromptBuilder.kt`
    - 如有必要新增：
        - `.../inference/history/HistoryRenderStrategy.kt`
        - `.../inference/history/DefaultHistoryRenderStrategy.kt`
    - `pulsar-agentic/.../model/AgentHistory` 相关模型
    - 如需要预算参数，优先放到 agent config，而不是散落在 `PromptBuilder` 常量里
- 实施内容：
    - 抽离三类输入源：
        - 最近步骤原样保留
        - 较老步骤摘要
        - 外部引用 / checkpoint 引用
    - 让 `PromptBuilder` 只负责拼装 message，不再直接决定压缩算法。
    - 保留当前行为作为默认策略，先完成结构解耦，再进入 PA-4。
- 验收标准：
    - 不改变对外 prompt 组装入口签名，先保持兼容。
    - history 的“如何截断/压缩”从 `PromptBuilder` 主逻辑中移出。
    - 有独立单测验证 history message 渲染结果。
- 建议测试：
    - 新增 `PromptBuilderHistoryStrategyTest.kt`
    - 最少覆盖：
        - 空 history
        - 小 history 不压缩
        - 大 history 走默认策略

### PA-4 实现 budget-aware history compression

- 目标：
    - 在 PA-3 的可替换策略基础上，实现按预算压缩，而不是固定条数截断。
- 主要代码落点：
    - `pulsar-agentic/.../inference/history/*`
    - `pulsar-agentic/.../inference/PromptBuilder.kt`
    - `pulsar-agentic/.../inference/InferenceEngine.kt`
    - 如需配置：
        - agent config / inference config 中增加 history budget 相关参数
- 实施内容：
    - 基于 token budget 或近似字符预算，区分：
        - 最近 N 步完整保留
        - 更老步骤压缩成摘要
        - 超长上下文用 checkpoint/reference 占位
    - 记录压缩前后统计信息，便于回归对比。
    - 第一版优先做确定性策略，不要一开始就引入依赖 LLM 的二次总结链。
- 验收标准：
    - 长 history 下生成的 message 明显短于当前实现。
    - 最近关键步骤仍被保留。
    - 压缩行为可测试、可配置、可追踪。
- 建议测试：
    - 新增 `HistoryCompressionStrategyTest.kt`
    - 覆盖：
        - 预算充足不压缩
        - 预算受限时老步骤被摘要/引用替代
        - 关键步骤不被错误丢弃

### PA-5 统一 direct command 与 LLM 路径的可追溯 / 可审计 / 可监控能力

- 目标：
    - direct command 路径与 LLM 路径共享统一的 trace / transcript / metrics / state 持久化规范。
    - 人工审查意见为准：`【同时需要对每一步的 ExecutionContext/AgentState 进行持久化】`、`【很好，请保持日志目录结构清晰，每个智能体任务一个独立文件夹】`。
- 主要代码落点：
    - `pulsar-agentic/src/main/kotlin/ai/platon/pulsar/agentic/inference/AgentStateManager.kt`
    - `pulsar-agentic/src/main/kotlin/ai/platon/pulsar/agentic/inference/InferenceEngine.kt`
    - `pulsar-agentic/src/main/kotlin/ai/platon/pulsar/agentic/agents/RobustBrowserAgent.kt`
    - `pulsar-agentic/src/main/kotlin/ai/platon/pulsar/agentic/agents/TaskScopedBrowserAgent.kt`
    - `pulsar-core/.../logging/ChatModelLogger.kt`
    - 如存在任务运行器耦合，再检查：
        - `pulsar-tools/.../agent/StatefulAgentRunner.kt`
- 实施内容：
    - 统一关联 ID：
        - task id
        - agent/session id
        - step id
        - trace id
    - 保证以下内容在 direct command 和 LLM 路径都可落盘：
        - `ExecutionContext`
        - `AgentState`
        - action result
        - process trace
        - LLM request / response（若本步骤有 LLM）
        - direct command 输入、校验结果、执行结果、失败原因
    - 明确目录结构：
        - 每个 agent task 一个独立目录
        - 目录下再放 `context.jsonl`、`state.jsonl`、`result.jsonl`、`agent-trace.jsonl`、chat logs 等
    - 避免把 direct command 的日志散落到与任务无关的共享目录。
- 验收标准：
    - direct command 与 LLM 路径产出的核心审计文件类型一致。
    - 每个 agent task 都有单独目录，单任务排查不需要人工拼日志。
    - 任一步失败都能从日志中反查输入、校验、执行和结果。
- 建议测试：
    - 新增 `AgentStatePersistenceTest.kt` 或 `AgentAuditPersistenceTest.kt`
    - 覆盖：
        - 每步 `ExecutionContext` / `AgentState` 落盘
        - 目录隔离
        - direct command 失败日志完整性

---

## 依赖关系

- 执行顺序：
    - `PA-0 -> PA-1`
    - `PA-1 -> PA-2`
    - `PA-1 -> PA-5`
    - `PA-3 -> PA-4`
- 并行关系：
    - `PA-2` 与 `PA-3` 可在 `PA-1` 后并行推进
    - `PA-4` 与 `PA-5` 可在各自前置完成后并行推进

---

## 建议实施顺序

1. 先做 `PA-0`，把 direct command 识别/拒绝语义定清楚。
2. 立即做 `PA-1`，只打通 agent 内部 fast path，不顺手改 history 和 audit 设计。
3. 接着做 `PA-2`，把入口和回归测试补齐，先把 direct command 主链路守住。
4. 然后做 `PA-3` + `PA-4`，独立推进 history 架构和压缩策略。
5. 最后做 `PA-5`，把 direct command 与 LLM 路径统一到同一套可观测性规范上。
