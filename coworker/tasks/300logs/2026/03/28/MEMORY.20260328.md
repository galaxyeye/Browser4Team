
## Analyze Directory Metadata

- **Context**: Needed a PowerShell utility that reads `bin\tools\system\move-folder-to-d.txt`, extracts the listed directory paths, and reports comprehensive Windows directory metadata in a readable format.
- **Action**:
    - Added `D:\workspace\Browser4Team\bin\tools\system\analyze-directory-metadata.ps1`.
    - Implemented parsing for directory paths embedded in the text report, including plain paths and rows with aligned columns.
    - Collected per-directory metadata including timestamps, owner/group, ACL entries, attribute flags, reparse-point/link type, file/subdirectory counts, file-type counts, directory depth/breadth metrics, filesystem/volume metadata, logical size, and allocation-unit-based size-on-disk.
    - Emitted both a human-readable text report and a structured JSON report under `bin\tools\system\logs\`.
    - Validated the script by running it against the real `move-folder-to-d.txt` input; the successful rerun produced `directory-metadata_20260328_112435.txt` and `directory-metadata_20260328_112435.json`.
- **Outcome**: The task now has a reusable analyzer script plus generated reports covering all listed directories, with missing paths (`C:\Users\pereg\.pulsar`, `C:\Users\pereg\.gradle`) called out explicitly instead of failing silently.
- **Lessons Learned**:
    - When scanning large Windows directory trees, skip descending into nested reparse points to avoid loops while still reporting link metadata.
    - "Size on disk" can be estimated reliably enough for reporting by rounding file lengths to the volume allocation unit from `Win32_Volume`.
    - Volatile directories such as `Temp` can change during long scans, so repeated validation runs may show small metric differences even when the script is correct.
