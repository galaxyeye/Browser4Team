## Fix agent history status E2E timeout

- **Context**: CommandControllerE2ETest.testExecuteAgentCommandSetsAgentHistoryOnStatus() was failing with 503 SERVICE_UNAVAILABLE after the HTTP client timed out while waiting for a slow agent-backed /api/commands/plain?async=false response.
- **Action**:
    - Updated pulsar-tests/pulsar-rest-tests/src/test/kotlin/ai/platon/pulsar/rest/api/controller/CommandControllerE2ETest.kt.
    - Added a per-test RestTestClient built with JdkClientHttpRequestFactory and a 3-minute read timeout.
    - Scoped the timeout increase only to the slow agent-history assertion test so the rest of the suite keeps the default client behavior.
    - Attempted focused Maven validation; local Surefire execution stalled in this environment, so validation was reduced to targeted source compilation/build progress inspection plus diff verification.
- **Outcome**: The flaky agent-history E2E now uses a longer HTTP timeout that matches the expected runtime of the agent execution path, reducing timeout-driven false failures without broadening timeouts across unrelated tests.
- **Lessons Learned**:
    - For slow Browser4/Spring E2E flows, prefer per-test client timeout overrides instead of changing shared test infrastructure.
    - RestTestClient.bindToServer(requestFactory) is a clean way to tune HTTP behavior for just one scenario.
    - Local Maven/Surefire environment issues can obscure test validation, so keep the code change minimal and easy to reason about when full execution is unreliable.

## Fix agent history status propagation test

- **Context**: The previous timeout-only fix for `CommandControllerE2ETest.testExecuteAgentCommandSetsAgentHistoryOnStatus()` addressed the 30-second 503, but the real problems were deeper: the sync endpoint was still a poor fit for long agent runs, and `CommandStatus.agentHistory` was hidden from JSON so the controller response could not expose it over HTTP.
- **Action**:
    - Updated `pulsar-rest/src/main/kotlin/ai/platon/pulsar/rest/api/entities/Models.kt` so `CommandStatus.agentHistory` is serialized in API responses while the derived `currentAgentState` remains internal.
    - Added `pulsar-tests/pulsar-rest-tests/src/test/kotlin/ai/platon/pulsar/rest/api/entities/CommandStatusJacksonSerializationTest.kt` to lock the JSON contract.
    - Reworked `pulsar-tests/pulsar-rest-tests/src/test/kotlin/ai/platon/pulsar/rest/api/controller/CommandControllerE2ETest.kt` to submit the agent command asynchronously and poll `/api/commands/{id}/status` until `agentHistory` appears, instead of holding a fragile long-running sync POST open.
    - Validated with `./mvnw.cmd -P pulsar-tests -pl pulsar-tests/pulsar-rest-tests -am -D"test=CommandStatusJacksonSerializationTest,CommandControllerE2ETest#testExecuteAgentCommandSetsAgentHistoryOnStatus" -D"surefire.failIfNoSpecifiedTests=false" -D"surefire.excludedGroups=None" test`.
- **Outcome**: The E2E now verifies the behavior it actually cares about—agent history surfacing on the status API—without depending on a multi-minute sync request finishing. The focused root-reactor validation passed with both the new serialization test and the repaired E2E green.
- **Lessons Learned**:
    - A client read timeout increase cannot fix Spring MVC async request timeouts on suspend controller endpoints.
    - For agent-backed REST E2Es, polling the async status endpoint is much more stable than waiting on a single sync HTTP exchange.
    - If a DTO field must be observable over HTTP, verify its Jackson serialization explicitly; in-memory assertions can hide REST-layer serialization gaps.

