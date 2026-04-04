@{
    Paths = @{
        WorkspaceRoot        = '..\..'
        CoworkerRoot         = '..'
        TasksRoot            = '..\tasks'
        TargetRepositoryRoot = '..\..\submodules\Browser4'
    }

    Scheduler = @{
        WorkingDirectory = '..\..'
    }

    COPILOT = @(
        'gh'
        'copilot'
        '--no-ask-user'
        '--log-level'
        'info'
        '--allow-all'
    )
}
