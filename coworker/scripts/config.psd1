@{
    Paths = @{
        WorkspaceRoot        = '..\..'
        CoworkerRoot         = '..'
        TasksRoot            = '..\tasks'
        TargetRepositoryRoot = 'D:\workspace\Browser4\Browser4-4.6'
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
