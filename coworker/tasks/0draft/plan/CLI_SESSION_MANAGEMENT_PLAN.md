# CLI Session Management Implementation Plan

Based on the review of `session-management.md` and the Rust CLI implementation (`sdks/browser4-cli`), several gaps have been identified where the code does not match the documented behavior.

## Gap Analysis

| Feature | Documentation | Current Implementation |
| :--- | :--- | :--- |
| **Named Sessions** | `-s=name` isolates session state (cookies, history, etc.). | `-s=name` only updates a field in a *single shared* state file (`cli-state.json`). Multiple named sessions overwrite each other locally. |
| **Persistence** | `--persistent` flag on `open` persists profile. | `--persistent` flag is parsed but **ignored**. It is not passed to the `open_session` tool. |
| **Profile Path** | `--profile=/path` specifies profile directory. | `--profile` flag is not implemented in `open` command arguments. |
| **Headed Mode** | `--headed` opens visible browser. | `--headed` flag is parsed but **ignored** (not passed to `open_session`). |
| **Session List** | `list` shows all sessions. | `list` calls server `list_sessions` but does not correlate IDs with local named sessions. |
| **Env Variable** | `PLAYWRIGHT_CLI_SESSION` sets default session. | Not implemented. |

## Implementation Plan

### 1. State Management Refactoring (`state.rs`)
Refactor `CliState` to support multiple session files instead of a single `cli-state.json`.

-   **Change Storage Structure**:
    -   From: `~/.browser4/cli-state.json`
    -   To: `~/.browser4/sessions/<name>.json`
    -   Default session name: `default`.
-   **Update `read_state` / `write_state`**:
    -   Accept `session_name: &str` argument.
    -   Read/write from `sessions/<session_name>.json`.

### 2. Argument Parsing & Environment (`args.rs`, `main.rs`)
Support environment variable and ensure `-s` flag correctly selects the state file.

-   **Update `parse_global_flags`**:
    -   Check `BROWSER4_CLI_SESSION` (and legacy `PLAYWRIGHT_CLI_SESSION`) environment variable if `-s` is not provided.
-   **Update `main`**:
    -   Pass the resolved session name to `read_state` / `write_state`.

### 3. Open Command capabilities (`main.rs`, `commands.rs`)
Pass CLI options to the server-side `open_session` tool.

-   **Update `create_session` signature**:
    -   Accept `capabilities: Option<Value>`.
-   **Update `handle_open`**:
    -   Extract `persistent` and `headed` from `tool_params` (need to ensure they are in `tool_params` first, which might require updating `tool_params_fn` in `commands.rs` or `CommandDef`).
    -   *Correction*: `tool_params_fn` for `open` currently ignores these. Update `tool_params_fn` in `commands.rs` to include `persistent`, `headed`.
    -   Or, better: parse them in `handle_open` if they are passed as "options".
    -   Construct `capabilities` object: `{ "persistent": true, "headed": true, "profilePath": ... }`.
    -   Pass to `create_session`.
-   **Update `CommandDef` for `open`**:
    -   Add `--profile` option definition.

### 4. Session Commands (`list`, `close`, `delete-data`)
Ensure they work with the new state structure.

-   **`list`**:
    -   Iterate over `~/.browser4/sessions/*.json`.
    -   Read each state file to get `sessionId`.
    -   Call server `list_sessions` to get active IDs.
    -   Print table: `Name | Session ID | Status (Active/Stale)`.
-   **`close` / `delete-data`**:
    -   Use resolved session name to find the correct state file.
    -   Perform action.
    -   For `delete-data`: Delete the local `sessions/<name>.json` file too.
-   **`close-all`**:
    -   Iterate all local session files and close them.

## Action Items

1.  **Modify `sdks/browser4-cli/src/state.rs`**: Implement `read_session_state(name)` and `write_session_state(name)`.
2.  **Modify `sdks/browser4-cli/src/commands.rs`**: Update `open` command definition to include `profile` and pass option values to params.
3.  **Modify `sdks/browser4-cli/src/main.rs`**:
    -   Integrate env var check.
    -   Update `handle_open` to build capabilities.
    -   Update `create_session` to send capabilities.
    -   Update `handle_list` to show local named sessions.
