# Improve daemon.rs

Improve ensure_server_running in daemon.rs to start the server by executing mvn + spring-boot:run in the Browser4 root directory. 
This will allow the CLI to automatically start the server if it's not already running, improving the user experience and reducing setup friction.

This should be the primary method for starting the server when using the CLI, as it ensures that the correct version of the server is running and eliminates the need for users to manually start it.
