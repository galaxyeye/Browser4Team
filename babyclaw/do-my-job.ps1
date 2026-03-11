#!/usr/bin/env pwsh

$prompt = @"
Read responsibilities.md and do the job.
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
