# Improve ci.yml

Test CLI first, and then run the rest of the tests. This way, if the CLI tests fail, we can save time by not running 
the other tests that are likely to fail as well.
