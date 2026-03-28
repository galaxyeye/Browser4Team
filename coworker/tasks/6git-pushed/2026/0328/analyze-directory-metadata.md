# Analyze directory attributes

Create a PowerShell script (`.ps1`) that reads `move-folder-to-d.txt`, extracts the directory paths listed in the file, and analyzes the attributes of each directory. Output the results in a clear, readable format, such as a table or structured report.

For each directory, analyze and report the following:

- Path
- Size
- Size on disk
- Creation date
- Last modified date
- Last accessed date
- Owner and group
- Permissions and access control lists (ACLs), including read/write/execute access where available
- Hidden, read-only, system, archive, compressed, and encrypted attributes
- Whether the directory is a symbolic link, junction point, or other reparse point
- Number of files and subdirectories
- File types present and their counts (for example, `.txt`, `.docx`, `.jpg`)
- Directory structure metrics, such as depth and breadth
- File system type (for example, `NTFS` or `FAT32`)
- Volume information, including drive letter, volume label, total space, and free space
- Disk usage for the directory

## References

- [move-folder-to-d.txt](../../../bin/tools/system/move-folder-to-d.txt)
