# Browser4Team

The digital team established with the mission of developing Browser4.

Clone the repository to get started:

```shell
git clone --recurse-submodules https://github.com/galaxyeye/Browser4Team.git
```

Start development:

1. run `coworker-scheduler.ps1` to start recurring automation
2. draft tasks in `0draft` (or anywhere)
3. copy ready tasks to `1created` for execution
4. once executed, you can find results in `3_1complete` and detailed logs in `300logs`
5. review results if needed
6. move task file from `3_1complete` to `5approved` to trigger git pushing

See also:

- [README.md](coworker/tasks/0draft/README.md)
- [README.zh.md](coworker/tasks/0draft/README.zh.md)