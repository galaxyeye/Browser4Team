## Stabilize browser4-cli E2E execution

- **Context**: The Rust `browser4-cli` E2E target was printing libtest's 60-second "has been running" warning even though the sequential suite could eventually pass, and attempts to split it into multiple libtest tests introduced Browser4 startup/session contention (`createTab` and browser launch failures).
- **Action**:
    - Converted `sdks/browser4-cli/tests/e2e.rs` into a custom `harness = false` test target via `sdks/browser4-cli/Cargo.toml`, with `autotests = false` and an explicit `[[test]]` entry for `e2e`.
    - Restored the proven single-backend sequential scenario flow in `main()`, while keeping the stronger navigation polling helper (`wait_for_eval_text`) and the less-flaky keyboard assertions.
    - Validated the exact task command `cargo test --test e2e -- --nocapture`, then ran `cargo test --quiet` in `sdks/browser4-cli` to confirm the crate-level test suite still passed.
- **Outcome**: `cargo test --test e2e -- --nocapture` now exits successfully without libtest's 60-second timeout warning, and the `browser4-cli` crate tests remain green.
- **Lessons Learned**:
    - For long-running end-to-end flows, a custom test harness can be more reliable than fighting libtest's per-test timeout reporting and scheduler behavior.
    - Browser4 E2E flows are more stable when they reuse one warmed backend sequentially instead of parallelizing browser startup across multiple test cases.
    - Preserve proven warm-up/ordering behavior before restructuring an E2E suite, because apparent "test timeout" problems may really be harness/runtime coordination issues.
