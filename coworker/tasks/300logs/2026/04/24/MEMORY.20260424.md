# MEMORY.20260424.md
## Daily Memory - 2026-04-24

- Rebuilt `browser4-tests/browser4-tests-common/src/main/resources/static/generated/form-filling.html` into a richer Browser4 form playground that preserves the stable registration selectors from the CLI E2E fixture (`#first-name`, `#last-name`, `#email`, `#country`, `#agree-terms`, `#comments`, `#submit-btn`, `#reset-btn`) while adding radio buttons, checkbox groups, dynamic contact fields, live summary cards, realtime validation, an event log, and serialized state output for browser interaction testing.
- Added focused regression coverage in `browser4-tests/browser4-tests-common/src/test/kotlin/ai/platon/pulsar/test/self/InteractivePagesTest.kt` to assert that `form-filling.html` keeps its key selectors, debug outputs, and richer control surface.
- Key lesson: for test fixture pages, keep the canonical selectors and state log stable first, then layer richer UX and dynamic behavior around them; also remember that `TestInfraCheck` tests are excluded by default in this repo, so targeted verification must override Surefire exclusions (for example with `-Dsurefire.excludedGroups=None`) to avoid zero-test false positives.
