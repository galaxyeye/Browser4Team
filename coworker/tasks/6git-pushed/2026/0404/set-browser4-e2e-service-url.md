# Improve ci.yml

When run browser4-cli E2E Tests in ci.yml, set BROWSER4_E2E_SERVICE_URL to http://localhost:8182, so that the tests can 
run against the Browser4 server started in docker instead of the default one. This will help ensure that the tests are 
running in a consistent environment.

## References

- [e2e.rs](../../../submodules/Browser4/sdks/browser4-cli/tests/e2e.rs)
- [ci.yml](../../../submodules/Browser4/.github/workflows/ci.yml)