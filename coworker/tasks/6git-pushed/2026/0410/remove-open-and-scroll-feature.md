# Remove `open-and-scroll-to-bottom` functionality from the system

`open-and-scroll-to-bottom` is developed just for testing the scroll behavior of the browser, and it is not a common 
command that users will use. Therefore, we can remove this functionality from the system to simplify the codebase and 
reduce maintenance overhead.

Search for `open-and-scroll-to-bottom` in the codebase and remove all related code, including CLI, WebDriver interface, 
Rest Controller support, and any associated tests. After removing the code, make sure to test the system to ensure that 
it still functions correctly without this command.