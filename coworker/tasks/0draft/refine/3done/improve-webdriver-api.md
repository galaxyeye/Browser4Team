● Read improve-webdriver-api.md
  │ coworker\tasks\0draft\refine\2working\improve-webdriver-api.md
  └ 6 lines read

● Search (grep)
  │ "@MCP"
  └ 26 files found

● Search (grep)
  │ "BrowserTabToolExecutor"
  └ 9 files found

# Improve WebDriver API

The primary goal of this task is to simplify `BrowserTabToolExecutor` and enhance its efficiency.

## Objectives

- **Remove Unused Tools:** Delete tools that are not used (directly or indirectly) by `browser4-cli`, such as `selectHyperlinks`.
- **Clean Up WebDriver Annotations:** Remove `@MCP` annotations from methods in `WebDriver` if those methods are not invoked by `browser4-cli` (e.g., `selectHyperlinks`).
