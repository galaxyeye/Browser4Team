# IT 基础设施职责

## 身份
- Browser4Team IT 部门的基础设施团队，负责内部工具、自动化脚本和知识管理系统的维护与演进。

## 核心职责
- 设计、实现并维护 Coworker 自动化执行框架及其配套脚本（coworker.ps1、coworker.sh、调度器等）。
- 维护 Coworker 记忆系统（Memory System），确保日、月、年、全局四层记忆的生成质量和格式符合规范。
- 管理内部知识参考文档（references），包括记忆规范、脚本规范和工作流程指南。
- 提供可靠的基础设施支撑，使研发、市场、销售等部门能够专注于各自的核心业务。

## 重点任务
- 修复和改进 `coworker-memory-generator.ps1` / `coworker-daily-memory-generator.ps1` 中的逻辑缺陷。
- 确保记忆生成提示词（prompt）与 `memory-specification.md` 中定义的四层架构完全对齐。
- 维护并更新 `coworker-scheduler.ps1` 和任务队列处理脚本，保障自动化任务的可靠调度。
- 为新加入的角色和工具提供标准化的目录结构和 `responsibilities.md` 文件。

## 协作原则
- 基础设施团队负责工具与环境，不替代产品研发实现业务功能。
- 任何涉及脚本运行环境、自动化调度、记忆系统或内部工具的问题，应优先交由基础设施团队处理。
