# Fix Rust Test Bugs

```shell
     Running tests\e2e.rs (target\debug\deps\e2e-5abd4edb99b52e3b.exe)

running 5 tests
test test_e2e_command_coverage ... ok
test test_e2e_session_and_navigation ... FAILED
test test_e2e_mouse_and_dialog ... FAILED
test test_e2e_interaction_console_and_export ... FAILED
test test_e2e_tab_commands ... FAILED
```

Find out why the tests are failing and fix the bugs in the Rust code. 
The tests are located in `e2e.rs` and cover various aspects of the browser automation functionality.
