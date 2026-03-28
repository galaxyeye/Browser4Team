# CLI E2E Test Failure

(base) PS D:\workspace\Browser4Team\submodules\Browser4\sdks\browser4-cli> cargo test --test e2e -- --nocapture
Finished `test` profile [unoptimized + debuginfo] target(s) in 0.11s
Running tests\e2e.rs (target\debug\deps\e2e-c1a9dd787a6e7d22.exe)

running 1 test

thread 'test_e2e_full_suite' (46004) panicked at tests\e2e.rs:506:5:
assertion `left == right` failed: Command ["close"] failed (exit=1):
stdout:

stderr:
Error: No active session. Run "browser4-cli open" first.

left: 1
right: 0
note: run with `RUST_BACKTRACE=1` environment variable to display a backtrace
test test_e2e_full_suite ... FAILED

failures:

failures:
test_e2e_full_suite

test result: FAILED. 0 passed; 1 failed; 0 ignored; 0 measured; 0 filtered out; finished in 15.12s

error: test failed, to rerun pass `--test e2e`
(base) PS D:\workspace\Browser4Team\submodules\Browser4\sdks\browser4-cli> echo $env:BROWSER4_CLI_E2E          
true