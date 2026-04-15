### Batch Execution

Execute multiple commands in a single invocation. Commands can be passed as
quoted arguments or piped as JSON via stdin. This avoids per-command process
startup overhead when running multistep workflows.

Batch execution must be implemented in the backend to ensure performance benefits, not just as a frontend wrapper.

```bash
# Argument mode: each quoted argument is a full command
browser4-cli batch "open https://example.com" "snapshot"

# With --bail to stop on first error
browser4-cli batch --bail "open https://example.com" "click e1" "screenshot"

# Stdin mode: pipe commands as JSON
echo '[
  ["open", "https://example.com"],
  ["snapshot"],
  ["click", "e1"],
  ["screenshot", "result.png"]
]' | browser4-cli batch --json
```
