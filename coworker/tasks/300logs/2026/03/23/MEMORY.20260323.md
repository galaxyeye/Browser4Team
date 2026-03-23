# MEMORY.20260323.md
- **Fix Rust Bug**: Resolved "Missing manifest in toolchain" error by manually cleaning the corrupted `.rustup` directory and reinstalling the stable toolchain using the `minimal` profile (`rustup toolchain install stable --profile minimal`) to overcome slow download speeds.
- **Outcome**: The Rust toolchain is now functional and `rustc --version` reports the correct version.
- **Lesson learned**: When toolchain installation is corrupted or network is slow, use the `minimal` profile to reduce download size and clean the `.rustup` directory manually to ensure a fresh start.
