# Improve test scripts to remove deprecated `nodejs-sdk` relevant code

nodejs-sdk has been deprecated and already removed from the project, so we need to update our test scripts to reflect this change. This involves:

1. Removing any references to `nodejs-sdk` in our test scripts.
2. Updating any test cases that were specifically designed to test `nodejs-sdk` functionality.

## References

- [test.ps1](../../../submodules/Browser4/bin/test.ps1)
- [test.sh](../../../submodules/Browser4/bin/test.sh)
