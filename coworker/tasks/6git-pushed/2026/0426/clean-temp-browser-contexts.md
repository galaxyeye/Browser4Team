# Improve e2e.rs to clean up generated temp browser context files

The `e2e.rs` file is responsible for running end-to-end tests for our application. 
During these tests, temporary browser context files are generated to simulate user interactions. 
However, these files can accumulate over time and take up unnecessary disk space.

The temporary browser context files are created since we open browser4 sessions with `--profile-mode=TEMPORARY`, 
which generates temporary contexts in `$TMP/browser4-pereg/context/tmp/groups/rand`, the absolute path currently is:

```
C:\Users\pereg\AppData\Local\Temp\browser4-pereg\context\tmp\groups\rand
```

We should delete all the files in this directory after the tests are completed to ensure that we do not leave behind any unnecessary files.
