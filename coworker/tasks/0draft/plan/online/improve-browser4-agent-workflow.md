# Improve Browser4's Agent Run Workflow

- Optimize token usage by capturing screenshots and DOM snapshots only when necessary.
  - Limit automatic captures to browser-interaction actions.
  - Update the agent prompt and workflow to dynamically determine the need for visual context based on the action's relevance to the webpage.
- Refine the `handleConsecutiveNoOps` logic to prevent false positive no-op detections.
  - Exclude actions unrelated to webpage state (e.g., internal reasoning, data processing) from webpage diff comparisons.

## References

- [PromptBuilder.kt](../../../../submodules/Browser4/pulsar-agentic/src/main/kotlin/ai/platon/pulsar/agentic/inference/PromptBuilder.kt)
- [InferencePromptBuilder.kt](../../../../submodules/Browser4/pulsar-agentic/src/main/kotlin/ai/platon/pulsar/agentic/inference/InferencePromptBuilder.kt)
- [RobustBrowserAgent.kt](../../../../submodules/Browser4/pulsar-agentic/src/main/kotlin/ai/platon/pulsar/agentic/agents/RobustBrowserAgent.kt)
