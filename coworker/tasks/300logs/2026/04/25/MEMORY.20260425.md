# MEMORY.20260425.md
## Daily Memory - 2026-04-25

- Fixed the `browser4-cli` Rust dead-code warnings reported by `cargo run open` by changing `sdks/browser4-cli/src/lib.rs` to export `state` as a public library module instead of keeping it as a private lib-only module. That preserved the existing binary behavior while making the bin-used state helpers part of the library surface so Cargo no longer warns when compiling the separate `browser4-cli` lib target.
- Confirmed the result with `cargo check` and `cargo test --bin browser4-cli --quiet` in `sdks/browser4-cli`.
- Key lesson: when a Cargo package builds both a binary and a library, helpers used only by the binary can still trigger dead-code warnings if they live in a private library module; either keep them out of the library target or export them intentionally so the crate boundary matches actual usage.
