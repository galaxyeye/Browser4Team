# MEMORY.20260323.md
- **Fix Rust Bug**: Resolved "Missing manifest in toolchain" error by manually cleaning the corrupted `.rustup` directory and reinstalling the stable toolchain using the `minimal` profile (`rustup toolchain install stable --profile minimal`) to overcome slow download speeds.
- **Outcome**: The Rust toolchain is now functional and `rustc --version` reports the correct version.
- **Lesson learned**: When toolchain installation is corrupted or network is slow, use the `minimal` profile to reduce download size and clean the `.rustup` directory manually to ensure a fresh start.
- **Analyze Implementation Requirements**: Reviewed 1.2.md and codebase to identify missing info for rowser4-cli enhancements.
- **Outcome**: Updated stimate-plan-implementation-requirements.md with questions about backend tool exposure, collective mode persistence/concurrency, and agent run async handling.
- **Key Findings**: 
    - BasicBrowserAgent tools (ct, xtract, summarize) are exposed via generic mapping in MCPToolController but not listed.
    - rowser4-cli collective mode requires a client-side scheduler (likely JSON-based persistence since no SQLite dependency).
    - gent run should likely use /api/commands/plain REST endpoint for async support.
- **Automated Draft Renaming**: Enhanced `refine-drafts.ps1` to automatically rename drafts based on their content using GitHub Copilot when moving them to the `2working` directory.
- **Outcome**: The script now generates concise kebab-case filenames for drafts, improving file organization and readability.
- **Lesson learned**: Using GitHub Copilot for semantic file renaming is effective but requires careful prompt engineering to ensure valid and concise filenames.

