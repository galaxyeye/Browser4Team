# MEMORY.20260423.md
## Daily Memory - 2026-04-23

- Added a dedicated `browser4-cli` Rust E2E scenario for batch-driven form submission from a JSON file in `sdks/browser4-cli/tests/e2e.rs`. 
- The test now writes a JSON fixture file, reads it back into the harness, builds a `batch --json` request from that payload, and verifies the form state plus submitted data after the batch completes. Key lesson: when batch E2Es need structured fixture data, keep the input as a JSON file and translate it into `batch --json` commands inside the test so the harness exercises both file loading and the real backend batch path without brittle command-string quoting. Validation note: the existing `test_batch_form_submission` scenario and the new `test_batch_form_submission_from_json_file` scenario both passed locally.
