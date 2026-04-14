# MEMORY.20260414.md
## Daily Memory - 2026-04-14

- Added a Unix `sdks/browser4-cli/install.sh` installer that detects supported package managers, installs missing Java 17+, Google Chrome, Rust, and native build dependencies, downloads the latest released `Browser4.jar`, and installs `browser4-cli` from the latest tagged Browser4 source into `~/.local/bin`. Updated the CLI and root README docs to advertise the installer and the Windows release-asset fallback. Lesson: when a product ships only part of its release surface as binaries, the installer should pin all downloaded artifacts to the same release tag and make the source-build fallback explicit so users still get a consistent end-to-end install experience.
