#!/usr/bin/env pwsh

$prompt = @"
Pick a markdown file from the `input` directory and perform the following tasks:

* move it to the `workshop` directory
* refine the content to make it more clear and concise
* create new versions of the content with different writing styles, including:
    * x.com
    * linkedin.com
    * 微信公众号
    * weibo.com
    * zhihu.com
* finally, move the refined content and newly created files to the `output` directory
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
