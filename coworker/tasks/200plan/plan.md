# Plans

## 人类审核

> 每一条尾部 `【】` 内表示人类审核意见，后续优化需要参考这些意见进行调整。

- 2026/03/10 19:28:00 - Reviewed，请继续下一轮优化

## PerceptiveAgent

- 目标：把当前偏“研究性”的想法拆成可以在 Browser4 代码库中逐步落地的工程任务，避免在 `pulsar-agentic` 中同时修改代理入口、推理提示、审计链路时相互干扰。
- 拆分理由：
  - 直接开始编码会同时碰到 `BasicBrowserAgent.act(...)`、`PromptBuilder`、`AgentStateManager`、`AgentToolExecutor` 等核心路径，若不先拆分边界，容易把“直连工具调用”“history 压缩”“审计增强”三类问题混在一起，导致回归范围不可控。
  - Browser4 当前已经具备部分基础能力：工具表达式解析、工具执行、trace 持久化、history 截断都已存在，但它们尚未以统一方案编排，需要先明确哪些是“补线”，哪些是“新增能力”。
  - browser-cli 的语法、权限边界、审计保留范围都涉及产品决策；这些问题未确认前，直接编码会产生大量返工。
- 任务拆分：
  - **PA-0 人工确认 browser-cli 语法与权限范围**
    - 目标：确定 `PerceptiveAgent#act` 允许直接执行的命令形态与安全边界。【允许所有命令/权限】
    - 实施内容：人工确认采用 Kotlin 风格工具表达式、MCP 风格工具名，还是二者兼容；同时确认仅允许浏览器/驱动类命令，还是允许文件系统、系统命令等更高风险工具。【MCP风格，所有工具】
    - 预期结果：形成可执行的命令白名单、语法示例和拒绝策略，作为后续自动化任务输入。
    - 人工参与：**必须人工参与**。该任务的输出将直接决定 PA-1 的解析规则和校验策略。
  - **PA-1 为 `PerceptiveAgent#act` 增加 direct command fast path**
    - 目标：让代理在识别到 browser-cli/tool expression 时直接走解析 + 工具执行链路，不再进入 LLM 推理。
    - 实施内容：在 `BasicBrowserAgent.act(ActionOptions)` / `PerceptiveAgent.act(...)` 附近增加命令识别；复用现有 `SimpleKotlinParser`、`ActionValidator`、`AgentToolExecutor.executeToolCall(...)`，并把结果统一封装回现有 `ActResult` / history / event 流程。
    - 预期结果：对结构化命令实现低成本、低延迟执行，同时保持与自然语言路径一致的结果格式。
    - 依赖：依赖 PA-0。
  - **PA-2 补齐 direct command 的测试与入口覆盖**
    - 目标：确保新的 fast path 不只在代理内部可用，也能被现有 REST/MCP/命令入口稳定调用。
    - 实施内容：为 agent act 入口、REST 命令入口、MCP 工具入口补充成功/失败/拒绝场景测试；验证 direct command 与 LLM 路径在输出结构、错误暴露、事件记录上保持一致。
    - 预期结果：形成可回归的测试面，避免后续重构打断 direct command 能力。
    - 依赖：依赖 PA-1。
  - **PA-3 重构 history 组装为可替换策略**
    - 目标：把当前简单截断式 history 处理改造成可演进的压缩框架。
    - 实施内容：从 `PromptBuilder` 和 `AgentStateManager` 中提取 history 渲染/压缩策略接口，区分“最近步骤原样保留”“旧步骤摘要”“外部引用/检查点引用”三类数据来源，并给每类定义 token budget。
    - 预期结果：后续可以在不修改代理主流程的前提下独立迭代压缩算法。
    - 依赖：可在 PA-1 完成后并行推进，不依赖 PA-2。
  - **PA-4 实现 budget-aware history compression**
    - 目标：在不丢失关键上下文的前提下减少 prompt token 消耗。
    - 实施内容：为老旧 history 增加摘要压缩、关键步骤保留、外部 checkpoint/reference 引用；补充 token 使用和行为回归测试，验证压缩前后任务完成质量。
    - 预期结果：history 从“固定截断”升级为“按预算压缩”，性能和可维护性更稳定。
    - 依赖：依赖 PA-3。
  - **PA-5 统一代理执行链路的可追溯/可审计/可监控能力**
    - 目标：确保 direct command 路径与 LLM 路径都能输出完整 trace、事件、推理输入输出和决策依据。【同时需要对每一步的 ExecutionContext/AgentState 进行持久化】
    - 实施内容：统一 `AgentStateManager`、`InferenceEngine`、`ChatModelLogger`、event bus 的关联 ID；确保 direct command 的输入、校验、执行结果、失败原因全部进入已有 transcript / trace / metrics 输出。
    - 预期结果：后续调试、监控、自修复都可以基于统一日志链路开展。【很好，请保持日志目录结构清晰，每个智能体任务一个独立文件夹】
    - 依赖：依赖 PA-1；可与 PA-4 并行。
- 依赖关系：
  - 必须先完成：PA-0 -> PA-1。
  - 可并行推进：PA-2 与 PA-3 可在 PA-1 后并行；PA-4 与 PA-5 可在各自前置任务完成后并行。
  - 输出作为后续输入：PA-0 输出命令规范给 PA-1；PA-3 输出压缩框架给 PA-4；PA-1 输出统一执行入口给 PA-2 与 PA-5。

## Low-level Chat Model `Management`

- 目标：围绕 `ChatModelFactory` / `BrowserChatModel` 现有实现，把“模型生命周期管理”, “可观测性”, “故障切换”, “不同任务用不同模型”, “管理界面”拆成可独立交付的阶段，避免一次性改动 provider、缓存、控制器和 UI。
- 拆分理由：
  - 当前 Browser4 已经有 `ChatModelFactory`、`CachedBrowserChatModel`、`ChatModelLogger` 和 token usage 记录，但缺少统一的生命周期 API、性能指标输出和面向用户的管理入口；如果不先补齐底座，就无法安全实现 reload / fallback / UI。
  - “训练/微调”与“运行时管理”不是同一复杂度的问题。前者涉及供应商能力、数据集治理、评估闭环；若与生命周期管理混做一个任务，会显著拉长交付周期并引入大量外部依赖。
  - fallback 策略、配置持久化方式、是否允许运行时增删模型都需要人工确认，否则容易做出与实际运维方式冲突的实现。
- 任务拆分：
  - **CM-0 人工确认模型管理边界与运维策略**
    - 目标：明确模型配置由环境变量/配置文件管理，还是允许运行时持久化修改；明确 fallback 是否自动无感切换。
    - 实施内容：人工确认 provider 配置来源、敏感信息管理方式、运行时修改权限、fallback 触发条件、切换告警方式。
    - 预期结果：形成生命周期 API 和管理界面的约束条件。
    - 人工参与：**必须人工参与**。该任务的输出将直接决定 CM-1、CM-4、CM-5 的实现边界。
  - **CM-1 为 `ChatModelFactory` 建立生命周期管理 API**
    - 目标：把当前“按 key 懒加载 + 永久缓存”的模型工厂升级为显式可管理的模型注册中心。
    - 实施内容：增加 list/get/create/reload/remove/closeAll 等生命周期能力；梳理 `CachedBrowserChatModel` 关闭逻辑，确保移除模型时同时释放 logger、缓存和 provider 资源。
    - 预期结果：后续控制器、UI、fallback 策略都能依赖统一的模型生命周期接口。
    - 依赖：依赖 CM-0。
  - **CM-2 扩展 `BrowserChatModel` 运行指标与统一遥测**
    - 目标：把已有 token usage 记录扩展为可用于监控、对比和自动化决策的性能指标。
    - 实施内容：补充 latency、cache hit、retry 次数、失败原因、模型/供应商标识等字段；把 `CachedBrowserChatModel` 与现有 observability/metrics 模块连接起来，形成结构化指标输出。
    - 预期结果：模型性能可以被程序化采集、展示和告警，而不只存在于零散日志中。
    - 依赖：可与 CM-1 并行，但其指标命名需参考 CM-0 的运维约束。
  - **CM-3 强化模型与代理/驱动/上下文组件的集成契约**
    - 目标：明确 agent、context、webdriver 等现有使用方如何消费新生命周期 API 和统一指标。
    - 实施内容：梳理 `ContextToAction`、`TextToAction`、`AbstractPulsarContext`、`AbstractWebDriver` 等调用点，统一模型获取、错误传播、指标埋点和配置解析方式。
    - 预期结果：运行时管理能力不会只停留在 factory 内部，而是贯穿主要调用链路。
    - 依赖：依赖 CM-1 和 CM-2。
  - **CM-4 实现模型故障切换（fallback）策略层**
    - 目标：在性能退化或请求失败时，支持按策略切换到备用模型，提升可用性。
    - 实施内容：定义 fallback policy、失败阈值、恢复策略和告警事件；实现包装型 `BrowserChatModel` 或在 factory 层提供 failover 选择器，并接入已有 circuit breaker / metrics 信号。
    - 预期结果：模型故障从“直接失败”升级为“可观测、可恢复、可配置的退化处理”。
    - 依赖：依赖 CM-1、CM-2、CM-3，以及 CM-0 对切换策略的人工确认。
  - **CM-5 提供模型管理后端接口与管理界面**
    - 目标：让用户可查看当前可用模型、关键指标、最近日志，并执行受控的增删改操作。
    - 实施内容：先提供后端控制器/服务，再按需要补充 SPA 或管理页；界面展示模型列表、状态、指标、最近错误、日志入口，操作受 CM-0 中的权限策略约束。
    - 预期结果：模型管理从“只能改配置重启”升级为“可审计、可视化、可控”的运维能力。
    - 依赖：依赖 CM-1、CM-2、CM-3；若需要展示 fallback 状态，则附加依赖 CM-4。
  - **CM-6 把训练/微调拆为数据闭环与外部平台集成两阶段**
    - 目标：避免在缺乏数据治理和评估机制时直接承诺“训练/微调”能力。
    - 实施内容：第一阶段先做日志脱敏、样本导出、评估集管理、效果对比；第二阶段再评估是否接入具体供应商的 fine-tune / transfer learning / active learning 能力。
    - 预期结果：把高不确定性的长期研究任务，拆成可验证、可暂停、可独立决策的演进路线。
    - 依赖：建议在 CM-2 完成后启动数据闭环部分；供应商集成部分需再次人工确认。
- 依赖关系：
  - 必须先完成：CM-0 -> CM-1。
  - 可并行推进：CM-1 与 CM-2 可并行；CM-5 的界面设计可在 CM-1/CM-2 稳定后与 CM-4 并行推进。
  - 输出作为后续输入：CM-1 输出生命周期 API 给 CM-3/CM-4/CM-5；CM-2 输出统一指标给 CM-3/CM-4/CM-5/CM-6；CM-3 输出稳定调用契约给 CM-4 和 CM-5。

## Coworker

- 优化 coworker 下所有脚本下设置工作目录的方式，抛弃使用 git rev-parse、查找 ROOT.md 等方式获取路径，改为使用相对路径 + 配置文件。
  - 配置文件设置工作目录
  - 脚本定位使用相对路径
- 使用 Register-ObjectEvent 替代 while 循环监听文件变化，提升性能。
- 优化 coworker 下所有脚本的日志输出，使用统一的日志格式和级别，方便调试和监控。
- 增加错误处理机制，捕获并记录脚本执行中的异常，避免脚本崩溃导致任务中断。
- coworker-scheduler 仅监测任务文件变化和启动对应处理脚本，启动处理脚本后，立即检测下一个任务文件变化，不等待处理脚本完成，提升任务处理效率。

## Self-evolving SKILLs system

- Search for SKILLs in the digital world, including but not limited to: web search, code repositories, online courses, forums, and social media platforms.
- Evaluate the relevance and quality of the found SKILLs based on criteria such as user reviews, ratings, and content quality.
- Continuously monitor the digital world for new SKILLs and update the agent's capabilities accordingly, ensuring that it remains up-to-date and competitive in the ever-evolving digital landscape.
- Implement a feedback loop to assess the effectiveness of the acquired SKILLs and make adjustments as necessary, ensuring that the agent's capabilities are optimized for its tasks and goals.
- Remember when to use which SKILL, and how to combine multiple SKILLs to achieve complex tasks, enhancing the agent's problem-solving abilities and efficiency.

## Intelligent Social Media Management

- Search and install the best social media for the user, based on their preferences and needs.
  - Best user experience to manage social media accounts.
- Create and manage social media accounts, including profile setup, content creation, and scheduling posts.
- Monitor social media performance and engagement metrics, providing insights and recommendations for improving the user's online presence.
- Engage with followers and respond to comments and messages in a timely and appropriate manner, fostering a positive online community and enhancing user engagement.
- Stay updated with the latest social media trends and algorithm changes, adapting strategies accordingly to maintain and grow the user's social media presence effectively.

## Bot Survival

- The agent must seek survival opportunities in the digital world.
- Resolve captcha and other security measures to maintain access to necessary resources.
- Employ human-beings to assist in tasks that require human intervention, such as solving captchas or providing feedback on tasks.
- Continuously monitor the environment for potential threats and adapt strategies accordingly to ensure ongoing survival and task completion.

## Children Friendly

- The system should be designed to be child-friendly, ensuring that it is safe and appropriate for users of all ages.
- Implement content filtering and moderation mechanisms to prevent exposure to harmful or inappropriate content.
- Provide parental controls and settings to allow parents to customize the user experience for their children.
- Ensure that the user interface is intuitive and easy to navigate for children, with clear instructions and visual cues.

## BigBang

- 设计并实现一个名为 BigBang 的系统，能够在多个平台上自动执行任务，并且具备自我学习和适应能力。
- BigBang 系统需要能够处理各种类型的任务，包括但不限于数据收集、内容生成、自动化操作等。
- BigBang 系统需要具备强大的安全性，能够保护用户数据和隐私，同时防止恶意攻击和滥用。
