# Fix coworker scripts

There are two issues in current coworker scripts:

1. [ERROR] Failed to initialize memory context: The script failed due to call depth overflow.
2. Encoding issue in log file, which causes garbled characters in log.

```shell
[2026-03-10 15:36:21] [INFO] Moved to working: D:\workspace\Browser4Team\coworker\tasks\2working\improve-mcp-tool-response-test.md
[2026-03-10T15:36:21.8431741Z] [WARN] [memory-generator] Daily memory length is 3513 chars (>3000); starting compression.
[2026-03-10T15:36:21.8499550Z] [WARN] [memory-generator] Backed up original daily memory to: D:\workspace\Browser4Team\coworker\tasks\300logs\2026\03\10\MEMORY.20260310.long.md
[2026-03-10 15:38:09] [ERROR] Failed to initialize memory context: The script failed due to call depth overflow.
[2026-03-10 15:38:09] [INFO] Executing Copilot for task: improve-mcp-tool-response-test
[2026-03-10 15:38:09] [INFO] Task repositories -> control: D:\workspace\Browser4Team | target: D:\workspace\Browser4Team\Browser4 | Copilot cwd: D:\workspace\Browser4Team\Browser4
[2026-03-10 15:38:09] [INFO] === Starting Copilot execution ===
�� Todo added: Read task description
�� Read D:\workspace\Browser4Team\coworker\tasks\2working\improve-mcp-tool-response-test.md
�� 4 lines read
�� Check repo status
$ git --no-pager status --short
�� 4 lines...
```
