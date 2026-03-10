@{
    Paths = @{
        WorkspaceRoot        = '..\..'
        CoworkerRoot         = '..'
        TasksRoot            = '..\tasks'
        TargetRepositoryRoot = '..\..\Browser4'
    }

    Scheduler = @{
        WorkingDirectory = '..\..'
    }

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
}
