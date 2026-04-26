# Improve e2e.rs to load HTML fixtures from file

The HTML fixtures are already in `browser4-tests/browser4-tests-common/src/main/resources/static/b4`, load them from there 
instead of hardcoding them in the test. This will make it easier to add more fixtures in the future and keep the test code cleaner.