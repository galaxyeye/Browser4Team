# Create a implementation plan to improve browser4-cli tests

Just create a plan and do not write code yet. The plan should include the following sections:

## Problem

When run ci.yml, nightly.yml and release.yml, the browser4-cli tests have to pass to proceed. However, the current 
implementation of the tests calls Browser4 service in a docker container and Browser4 service accesses the test pages 
served by `e2e.rs` itself. This setup can lead to networking issues.

## Solution

- The Browser4 service can be started externally, and the tests should connect to it.
- Using an external Browser4 service allows the tests to run in Docker and other environments without having to start the server during each test run.
- `e2e.rs` should be refactored to connect to the external Browser4 service and run tests against it.
- Because `e2e.rs` uses the Browser4 service to visit test pages that are served by `e2e.rs` itself, it should handle networking correctly when the Browser4 service is running in Docker and `e2e.rs` is running on the host machine.

## References

- [e2e.rs](../../../submodules/Browser4/sdks/browser4-cli/tests/e2e.rs)
