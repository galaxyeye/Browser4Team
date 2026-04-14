# Improve WebDriver API

The primary goal of this task is to simplify `BrowserTabToolExecutor` and enhance its efficiency.

## Objectives

- **Remove Unused Tools:** Delete tools that are not used (directly or indirectly) by `browser4-cli`, such as `selectHyperlinks`.
- **Clean Up WebDriver Annotations:** Remove `@MCP` annotations from methods in `WebDriver` if those methods are not invoked by `browser4-cli` (e.g., `selectHyperlinks`).
