# Fix testExecuteAgentCommandSetsAgentHistoryOnStatus

## Problem

```
2026-04-01 22:32:57.709  INFO [ommander#3] a.p.p.a.a.RobustBrowserAgent - 📝✅ Summary generated successfully | event:summary, step:2, responseLength:787, responseState:STOP
2026-04-01 22:32:57.721  INFO [ommander#3] a.p.p.a.a.RobustBrowserAgent - 🧾💾 Persisting execution transcript | event:step, step:1
2026-04-01 22:32:57.728  INFO [ommander#3] a.p.p.a.a.RobustBrowserAgent - 🧾✅ Transcript persisted successfully | event:step, step:1, lines:11, path:file:///D:/workspace/Browser4Team/submodules/Browser4/pulsar-tests/pulsar-rest-tests/./logs/agent/20260401.223226/3ae30e41-3f03-4ea7-bf4c-aa1a20a0b6a1/task-d89dd2c8-c00c-4970-a1d9-31372bf461a2/session-1775053977721.log
2026-04-01 22:32:57.739  INFO [ommander#4] a.p.p.a.t.a.StatefulAgentRunner - Collected event PerceptiveAgent.onDidRun for agent task 3b4f9c62-4245-4a99-ba15-56d5da1ef4a9
{"id":"2f3a1c2b-4a08-421d-8ef7-f5d545932c0a","statusCode":200,"event":"PerceptiveAgent.onDidRun","processState":"done","pageStatusCode":201,"pageContentBytes":0,"message":"The browser has been successfully opened and is currently displaying the Microsoft Bing (Chinese version) homepage at https://cn.bing.com/.","commandResult":{"summary":"The browser has been successfully opened and is currently displaying the Microsoft Bing (Chinese version) homepage at https://cn.bing.com/."},"lastModifiedTime":"2026-04-01T14:32:57.739487Z","finishTime":"2026-04-01T14:32:57.739487Z","isDone":true,"status":"OK"}

org.opentest4j.AssertionFailedError: actual value is null ==> expected: not <null>

```
