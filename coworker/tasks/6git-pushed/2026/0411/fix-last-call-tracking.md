# Fix Bug to retrieve lastCall in RobustBrowserAgent

When executing a step in RobustBrowserAgent, it reports an error: `lastCall is null`

```
2026-04-11 09:44:02.901  INFO [-worker-26] a.p.p.a.a.RobustBrowserAgent - ▶️ step.exec sid=2679ccd1 step=4/100 noOps=1 lastCall=null
```

Find out why `lastCall` is null and fix the bug to ensure that `lastCall` is properly set during step execution. This is important for tracking the last executed call and improving the robustness of the agent.