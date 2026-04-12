# MEMORY.20260412.md
## Daily Memory - 2026-04-12

- Improved `.github/workflows/ci.yml` so the `Check Test Status` stage always runs after the reusable test action, defaults a missing test status to `failed`, parses `TEST-*.xml` reports to print the individual failing test cases, emits GitHub `::error` annotations for each failure, and appends a failed-test section to `$GITHUB_STEP_SUMMARY`. YAML validation succeeded with `python -c "import yaml, pathlib; yaml.safe_load(...)"`. Lesson: aggregate test counts are not enough for fast CI triage; surfacing per-test Surefire failures directly in the workflow makes failing runs immediately actionable.
