## Tasks

- Scan every direct subdirectory for `do-my-job.ps1` which marks the directory as the employee's workspace
- Check `${workspace}/input/` for a Markdown file as the task input
- If task file found, run `${workspace}/do-my-job.ps1` so the employee can perform their task
  - no waiting for the task to complete, just trigger it and move on to the next workspace
- If no task file found, skip the workspace and check the next one
- Create a PowerShell script to automate this process

## Memory

- Store the results of each `do-my-job.ps1` execution as memory entries
- Create the following memory layers:
    - Daily: `memory/yyyy/MM/yyyy-MM-dd.MEMORY.md`
    - Weekly: `memory/yyyy/MM/yyyy-WW.MEMORY.md`
    - Monthly: `memory/yyyy/yyyy-MM.MEMORY.md`
    - Yearly: `memory/yyyy.MEMORY.md`
    - Global: `memory/global.MEMORY.md`
- Update daily memory after each execution, and append to weekly, monthly as appropriate
- Update yearly and global memory every day if not already updated
- Generate memory according to the specifications
- Create a PowerShell script to manage memory entries and generate memory files

## References

- [memory-specification.md](../memory/references/memory-specification.md)