# Create a new CLI command to `open-and-scroll-to-bottom`

This is a new command that opens a URL and scrolls to the bottom of the page. 

```bash
browser4-cli open-and-scroll-to-bottom https://playwright.dev/
```

The implementation of this command will involve the following steps:

1. Open the specified URL in a new browser tab.
2. Wait for the page to load completely.
3. Scroll to the bottom of the page.

Main implementation steps:

- Create a new interface in WebDriver for the `open-and-scroll-to-bottom` command and implement the logic to perform the above steps.
- Create a new handler in BrowserTabToolExecutor to execute the `open-and-scroll-to-bottom` command by calling the WebDriver interface.
- Make sure MCPToolController can route the `open-and-scroll-to-bottom` command to the BrowserTabToolExecutor.
- Create a new command handler for `open-and-scroll-to-bottom` in sdks/browser4-cli/commands.go.

## Implementation Notes

- The `open-and-scroll-to-bottom` command should be implemented as a single atomic operation that performs all three steps in sequence.
- The command should handle any errors that may occur during the process, such as navigation errors or timeouts while waiting for the page to load.
- The command should return a snapshot of the final state of the page after scrolling to the bottom, including the URL, title, and any relevant accessibility information.
- The command should be added to the CLI help documentation and include examples of usage.