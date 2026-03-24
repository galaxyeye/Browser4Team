# Improve Kill All Command

The `kill-all` command in the `browser4-cli` tool is designed to forcefully terminate all browser sessions. 

But it does not work sometimes, and the browser processes remain active. To improve the reliability of this command, we can implement a more robust process termination mechanism.

```shell
browser4-cli kill-all
```

## Suggested Improvements

Use the code in kill-browsers-short.ps1 to kill all Browser4 managed chrome processes.

## Reference

[kill-browsers-short.ps1](../../../submodules/Browser4/bin/tools/kill-browsers-short.ps1)
