# Fix refine-drafts script

When refine-drafts.ps1 refine a draft, it writes logs to the draft file which is not expected. 
This task is to fix the script so that it only writes the final refined draft to the file, without any logs.

- [refine-drafts.ps1](../../scripts/workers/refine-drafts.ps1)
- [browser4-cli-external-service-tests.md](plan/2026/04/browser4-cli-external-service-tests.md)