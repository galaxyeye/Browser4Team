# Run PerceptiveAgent with Browser4-CLI

PerceptiveAgent already uses browser tools by reading `TOOL_SPECIFICATION`. Extend this capability so it can use those tools to access the skill documentation and install `browser4-cli`.

The agent should be able to:

- read the relevant documentation
- understand the required installation steps
- execute the commands needed to install `browser4-cli`

## References

- [PerceptiveAgent.kt](../../../../submodules/Browser4/pulsar-agentic/src/main/kotlin/ai/platon/pulsar/agentic/PerceptiveAgent.kt)
