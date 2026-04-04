# MEMORY.20260404.md

## Support external Browser4 service in browser4-cli e2e

- **Context**: `sdks/browser4-cli/tests/e2e.rs` always resolved a local Browser4 jar and started a local server, which prevented the suite from targeting an already running external Browser4 service.
- **Action**:
    - Updated `sdks/browser4-cli/tests/e2e.rs` to resolve the Browser4 backend from `BROWSER4_E2E_SERVICE_URL` or `BROWSER4_E2E_SERVER_URL` before falling back to the existing jar-based startup path.
    - Added URL normalization so whitespace and trailing slashes do not break health checks or `--server` wiring.
    - Added an external-service health check and kept the existing local-jar startup path unchanged when no external service URL is configured.
    - Updated the file-level running notes to document the new backend resolution order.
    - Validated with `cargo test --quiet` from `sdks/browser4-cli`.
- **Outcome**: The Rust CLI E2E harness now supports running against a dedicated external Browser4 service without requiring a local jar launch, while preserving the previous local fallback behavior.
- **Lessons Learned**:
    - For test harness infrastructure, an env-driven override is the safest way to support remote services without changing production CLI behavior.
    - Normalizing configured base URLs up front avoids subtle trailing-slash and whitespace mismatches in health checks and command invocation.
    - Preserving the local default path keeps E2E workflows backward compatible for contributors who still run everything on one machine.

## Point CI browser4-cli e2e at dockerized Browser4 service

- **Context**: `.github/workflows/ci.yml` still made the `browser4-cli` E2E step look up a local Browser4 jar and prepare for a self-started backend, even after the Rust harness learned how to prefer `BROWSER4_E2E_SERVICE_URL`.
- **Action**:
    - Updated the `Run browser4-cli E2E Tests` step in `.github/workflows/ci.yml` to export `BROWSER4_E2E_SERVICE_URL=http://localhost:8182`.
    - Removed the local jar discovery/check and the host-side Chrome installation logic from that step because CI already starts the Browser4 server in Docker before the E2E run.
    - Re-ran `cargo test --quiet` from `sdks/browser4-cli` after the workflow edit to confirm the Rust CLI test suite still passes.
- **Outcome**: CI now runs the `browser4-cli` E2E suite against the Browser4 instance started earlier in the workflow, keeping the environment consistent with the Dockerized service under test and avoiding an unnecessary fallback to local jar startup logic.
- **Lessons Learned**:
    - Once the test harness supports a service URL override, the workflow should stop carrying stale local-startup assumptions or they can still fail the job before tests begin.
    - Removing obsolete setup from CI is as important as adding the new env var; otherwise the pipeline can remain coupled to an older execution path.
