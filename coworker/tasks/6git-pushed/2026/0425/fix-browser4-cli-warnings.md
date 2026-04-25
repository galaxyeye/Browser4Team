# Fix warnings in `browser4-cli`

```shell
(base) PS D:\workspace\Browser4Team\submodules\Browser4\sdks\browser4-cli> cargo run open
warning: function `write_state` is never used
  --> src\state.rs:83:8
   |
83 | pub fn write_state(
   |        ^^^^^^^^^^^
   |
   = note: `#[warn(dead_code)]` (part of `#[warn(unused)]`) on by default

warning: function `clear_state` is never used
   --> src\state.rs:102:8
    |
102 | pub fn clear_state(state_dir: Option<&Path>, session_name: Option<&str>) {
    |        ^^^^^^^^^^^

warning: function `clear_all_state` is never used
   --> src\state.rs:111:8
    |
111 | pub fn clear_all_state(state_dir: Option<&Path>) {
    |        ^^^^^^^^^^^^^^^

warning: function `resolve_ref` is never used
   --> src\state.rs:139:8
    |
139 | pub fn resolve_ref(raw_ref: &str) -> String {
    |        ^^^^^^^^^^^

warning: `browser4-cli` (lib) generated 4 warnings
```