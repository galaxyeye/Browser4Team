# MEMORY.20260406.md

## Fix refine-drafts logging contamination

- **Context**: `coworker\scripts\workers\refine-drafts.ps1` writes the captured Copilot response back into the refined draft file, but the shared `Invoke-GHCopilot -CaptureOutput` path was also returning Copilot CLI policy/status/footer text. That caused refined drafts to include logging noise instead of only the final rewritten document.
- **Action**:
    - Updated `coworker\scripts\workers\gh-copilot.ps1` so capture-output invocations automatically include `--silent` unless the caller already passed it.
    - Kept the change scoped to capture mode, so interactive/non-captured Copilot runs still preserve their normal console behavior.
    - Validated the helper by invoking a prompt that should return exactly `SAMPLE_RESPONSE` and confirming the captured result contains only that text.
- **Outcome**: Draft refinement now receives only the model response when it saves the refined document, so `refine-drafts.ps1` stops writing Copilot CLI logs and usage summaries into the draft file.
- **Lessons Learned**:
    - For script-driven Copilot flows that persist stdout to disk, `--silent` is required to keep CLI metadata out of the captured content.
    - Fixing the shared capture helper is safer than post-processing individual script outputs because it protects every caller that expects clean generated text.

## Create browser4-cli external-service E2E plan

- **Context**: The planning task for `browser4-cli` test stabilization asked for an implementation-only plan, not code, covering how to run the Rust E2E suite against an externally started Browser4 service in CI and other Dockerized environments.
- **Action**:
    - Reviewed the current `sdks\browser4-cli\tests\e2e.rs` harness, `sdks\browser4-cli\src\daemon.rs`, and the `ci.yml`, `nightly.yml`, `release.yml`, and `start-application` workflow wiring.
    - Confirmed the current harness still self-starts a local Browser4 jar, binds its fixture server to `127.0.0.1`, and that the workflows still place the CLI E2E step before the Dockerized Browser4 service is started.
    - Wrote `docs-dev\copilot\tasks\daily\plan-browser4-cli-tests.md` with a concrete implementation plan covering external-service env vars, host/container fixture networking, workflow reordering, and Docker host alias support.
- **Outcome**: The repository now contains a task-ready implementation plan that reflects the current codebase rather than the older task assumptions. The monthly memory already contained the 2026-04-05 rollup, so no monthly append was needed for this task.
- **Lessons Learned**:
    - For host-run test harnesses that drive a browser service inside Docker, loopback fixture URLs are the hidden failure mode; the bind address and the Browser4-facing hostname must be configured separately.
    - CI workflow order is part of the test architecture: if the external service is started after the tests, harness refactors alone will not validate the real deployment path.
