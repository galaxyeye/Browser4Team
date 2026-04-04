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
