# Close Chrome Gracefully When Closing Browser4-CLI

When the `Close Browser4-CLI` command is executed, the Browser4 backend shuts down, but the Chrome process may remain running. This can lead to resource leaks and other issues.

To fix this, the `Close Browser4-CLI` command should send a proper shutdown signal to the Chrome process so that Chrome can exit gracefully.

After sending the shutdown signal, the system should verify whether the Chrome process has exited. If Chrome is still running, the process should then be terminated forcefully to prevent orphaned processes from being left behind.
