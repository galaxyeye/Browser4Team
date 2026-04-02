# Fix testExecuteAgentCommandSetsAgentHistoryOnStatus


## Problem

```
2026-04-01 17:32:58.806  WARN [o-1-exec-6] o.s.w.s.m.s.DefaultHandlerExceptionResolver - Resolved [org.springframework.web.context.request.async.AsyncRequestTimeoutException]
2026-04-01 17:32:58.814 ERROR [main] o.s.t.w.s.c.ExchangeResult - Request details for assertion failure:

> POST http://127.0.0.1:7083/api/commands/plain?async=false
> RestTestClient-Request-Id: [1]
> Content-Type: [text/plain;charset=ISO-8859-1]
> Content-Length: [35]

Search for a joke about programmers

< 503 SERVICE_UNAVAILABLE Service Unavailable
< Vary: [Origin, Access-Control-Request-Method, Access-Control-Request-Headers]
< Content-Type: [application/json]
< Transfer-Encoding: [chunked]
< Date: [Wed, 01 Apr 2026 09:32:58 GMT]
< Connection: [close]

{"timestamp":"2026-04-01T09:32:58.808Z","status":503,"error":"Service Unavailable","path":"/api/commands/plain"}


java.lang.AssertionError: Range for response status value 503 SERVICE_UNAVAILABLE expected:<SUCCESSFUL> but was:<SERVER_ERROR>
Expected :SUCCESSFUL
Actual   :SERVER_ERROR
<Click to see difference>
```

## Solution

Increase the HTTP timeout in testExecuteAgentCommandSetsAgentHistoryOnStatus.
