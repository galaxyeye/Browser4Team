#!/usr/bin/env pwsh

$prompt = @"
Pick a markdown file from the `tasks` directory and move it to the `tasks/in-process` directory.

Read `responsibilities.md` and follow the instructions with the task file.

Finally, move the task file to `tasks/done`, and move all the generated files to the `output` directory.
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
