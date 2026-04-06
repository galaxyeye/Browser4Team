● Read browser4-cli-external-service-tests.md
  │ coworker\tasks\0draft\refine\2working\browser4-cli-external-service-tests.md
  └ 10 lines read

I’ve got the draft context; next I’m tightening the language while keeping the same structure and intent.

● Edit
  └ Edit coworker\tasks\0draft\refine\2working\browser4-cli-external-service-tests.md

● Read browser4-cli-external-service-tests.md
  │ coworker\tasks\0draft\refine\2working\browser4-cli-external-service-tests.md
  └ 10 lines read

# Improved browser4-cli tests

- The Browser4 service should be started externally, and the tests should connect to it.
- Using an external Browser4 service allows the tests to run in Docker and other environments without having to start the server during each test run.
- `e2e.rs` should be refactored to connect to the external Browser4 service and run tests against it.
- Because `e2e.rs` uses the Browser4 service to visit test pages that are served by `e2e.rs` itself, it should handle networking correctly when the Browser4 service is running in Docker and `e2e.rs` is running on the host machine.

## References

- [e2e.rs](../../../../submodules/Browser4/sdks/browser4-cli/tests/e2e.rs)
