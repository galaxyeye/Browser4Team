#!/usr/bin/env pwsh

$prompt = @"
Read Responsibilities.md and do your job.
"@

COPILOT = @(
    'gh'
    'copilot'
    '--model'
    'gpt-5.4'
    '--no-ask-user'
    '--log-level'
    'info'
    '--allow-all'
)

# Run the Copilot command with the defined prompt
& $COPILOT @($prompt)
