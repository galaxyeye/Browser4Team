# Clean up any lingering browser processes after the test run

When run browser4-cli test, the test cases will open browser instances to perform end-to-end testing.
To ensure that no browser processes are left running after the tests complete, we will implement a cleanup step that
closes all tabs and kills any remaining browser4 instances.

Give me a good implementation of this cleanup step in Rust, which can be added to the end of the test suite in `e2e.rs`.

## References

- [e2e.rs](../../../submodules/Browser4/sdks/browser4-cli/tests/e2e.rs)
