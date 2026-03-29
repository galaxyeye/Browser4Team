# Fix Rust E2E Bugs

I suspect the backend server is not properly restarted between tests, causing state to leak and resulting in the failure
of `test_e2e_interaction_console_and_export`. To fix this, we can ensure that the backend server is restarted before each test case.

```shell
     Running tests\e2e.rs (target\debug\deps\e2e-5abd4edb99b52e3b.exe)
running 5 tests
test test_e2e_command_coverage ... ok
test test_e2e_session_and_navigation ... ok
test test_e2e_interaction_console_and_export ... 
thread 'main' (53164) panicked at tests\e2e.rs:498:5:
assertion `left == right` failed: Command ["drag", "#drag-source", "#drag-target"] failed (exit=1):
stdout:

stderr:
Error: HTTP request failed: error sending request for url (http://127.0.0.1:3301/mcp/call-tool)

  left: 1
 right: 0
note: run with `RUST_BACKTRACE=1` environment variable to display a backtrace
error: test failed, to rerun pass `--test e2e`
```

