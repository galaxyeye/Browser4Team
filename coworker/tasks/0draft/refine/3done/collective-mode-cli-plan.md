# Collective Mode & Task Submission

## Collective Mode

Use collective mode to run multiple browser instances in parallel for faster and more efficient task execution.

### Usage

**1. Create a Collective Session**

Initialize a session with multiple browser contexts and tabs to handle parallel tasks.

```shell
# Create a session with 8 tabs and 2 contexts in GUI mode
browser4-cli co create --profile-mode=temporary --max-open-tabs=8 --max-browser-contexts=2 --display-mode=GUI
```

**2. Submit Tasks**

Submit URLs or tasks to the active session.

```shell
# Submit a single URL with a deadline
browser4-cli co submit https://www.amazon.com/dp/B08PP5MSVB -deadline 2026-02-24T23:59:59Z

# Submit multiple URLs from a seed file
browser4-cli co submit --seed-file=seeds.txt
```

**3. Scrape Data**

Extract specific data from pages using CSS selectors.

```shell
browser4-cli co scrape https://www.amazon.com/dp/B08PP5MSVB --selector=".product-title" --attribute="textContent" --output=title.txt
```

**4. Close Session**

```shell
browser4-cli close
```

## Technical Notes

### Parameter Mapping

CLI parameters map directly to the underlying Agentic and Skeleton APIs.

**`browser4-cli co create`**

Parameters map to `AgenticContexts.createSession(...)` and control the browser environment:

*   `--profile-mode`: Maps to `BrowserProfileMode` (e.g., `temporary`, `default`).
*   `--max-open-tabs`: Controls concurrency per browser context.
*   `--max-browser-contexts`: Controls the number of isolated browser environments.
*   `--display-mode`: Maps to `DisplayMode` (e.g., `GUI`, `HEADLESS`).

**`browser4-cli co submit` & `scrape`**

Arguments map to `LoadOptions` to control page fetching behavior. Common options include:

*   `-deadline`: Set a time limit for the task.
*   `-expires`: Set cache expiration duration (e.g., `1d`, `1h`).
*   `-refresh`: Force a fresh fetch, ignoring cache.
*   `-parse`: Parse the page immediately after fetching.
*   `-storeContent`: Persist the page content to storage.

## References

- [LoadOptions.kt](../../../../submodules/Browser4/pulsar-core/pulsar-skeleton/src/main/kotlin/ai/platon/pulsar/skeleton/common/options/LoadOptions.kt)
- [AgenticContexts.kt](../../../../submodules/Browser4/pulsar-agentic/src/main/kotlin/ai/platon/pulsar/agentic/context/AgenticContexts.kt)
