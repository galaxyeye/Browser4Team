# Bug fix - test test_e2e_interaction_console_and_export

test test_e2e_interaction_console_and_export ...
thread 'main' (28152) panicked at tests\e2e.rs:982:5:
Timed out waiting for interactive state. Last state:
Object {
"checkbox": Bool(false),
"clickCount": Number(0),
"confirmResult": String(""),
"doubleClickCount": Number(0),
"dragDropped": String(""),
"dragStarted": Bool(false),
"fillValue": String("filled text"),
"hovered": Bool(false),
"keyEvents": Array [
String("down:!"),
String("up:!"),
],
"lastMouse": Null,
"lastWheel": Null,
"mouseDownCount": Number(0),
"mouseUpCount": Number(0),
"promptResult": String(""),
"selectValue": String(""),
"submitCount": Number(0),
"typeValue": String("hello world!"),
"uploadCount": Number(0),
"uploadName": String(""),
}
note: run with `RUST_BACKTRACE=1` environment variable to display a backtrace
error: test failed, to rerun pass `--test e2e`