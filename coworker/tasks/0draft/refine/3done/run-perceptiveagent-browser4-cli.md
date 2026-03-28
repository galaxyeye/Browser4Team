I’m polishing the draft in place so the source file stays aligned with the refined version I return.

● Read run-perceptiveagent-browser4-cli.md
  │ coworker\tasks\0draft\refine\2working\run-perceptiveagent-browser4-cli.md
  └ 10 lines read

● Edit
  └ Edit coworker\tasks\0draft\refine\2working\run-perceptiveagent-browser4-cli.md

# Run PerceptiveAgent with Browser4-CLI

PerceptiveAgent already uses browser tools by reading `TOOL_SPECIFICATION`. Extend this capability so it can use those tools to access the skill documentation and install `browser4-cli`.

The agent should be able to:

- read the relevant documentation
- understand the required installation steps
- execute the commands needed to install `browser4-cli`

## References

- [PerceptiveAgent.kt](../../../../submodules/Browser4/pulsar-agentic/src/main/kotlin/ai/platon/pulsar/agentic/PerceptiveAgent.kt)
