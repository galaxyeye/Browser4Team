# Fix e2e.rs testing bug

```shell
    Running tests\e2e.rs (target\debug\deps\e2e-5abd4edb99b52e3b.exe)
running 6 tests
test test_e2e_command_coverage ... ok
test test_e2e_session_and_navigation ... ok
test test_e2e_interaction_console_and_export ... 
thread 'main' (41032) panicked at tests\e2e.rs:877:5:
assertion `left == right` failed: Command ["goto", "http://127.0.0.1:31663/interactive"] failed (exit=1):
stdout:

stderr:
Error: HTTP request failed: error sending request for url (http://127.0.0.1:50654/mcp/call-tool)

  left: 1
 right: 0
note: run with `RUST_BACKTRACE=1` environment variable to display a backtrace
error: test failed, to rerun pass `--test e2e`
```