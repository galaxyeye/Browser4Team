#!/usr/bin/env pwsh

$prompt = @"
Pick a markdown file from the `input` directory and move it to the `workshop` directory.

Read `responsibility.md` and follow the instructions with the input file.

Finally, move all the generated files the `output` directory
"@

$COPILOT = @(
    'copilot'
    '--model'
    'gpt-5.4'
    '--no-ask-user'
    '--log-level'
    'info'
    '--allow-all'
    '--prompt'
    $prompt
)

# Run the Copilot command with the defined prompt in non-interactive mode.
& gh @COPILOT
