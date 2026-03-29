# Improve Rust E2E Tests

Currently, some of the tests are run without asserting their success, which can lead to unnoticed failures. 
We should update the tests to include assertions that verify the expected outcomes of each test case. 
This will help us catch any issues early and ensure that our E2E tests are reliable and effective in validating the 
functionality of our browser automation features.

The target HTML page (return by `interactive_html()`) used to test shows necessary data in `#state-log` section for each 
interaction, the test code should read the page content and assert the expected results after each interaction command.

Here is an interaction log example for a click command:

```
{"clickCount":1,"doubleClickCount":1,"hovered":true,"dragStarted":true,"dragDropped":"drag-source","promptResult":"__dismissed__","confirmResult":"dismissed","keyEvents":["down:Alt","down:Insert","up:Insert","down:F12","up:F12"],"mouseDownCount":14,"mouseUpCount":14,"lastMouse":[305,316],"lastWheel":null,"typeValue":"","fillValue":"","checkbox":false,"selectValue":"green","uploadCount":1,"uploadName":"","submitCount":0}
```

If some tests are failing, we should investigate the root cause and find out whether it's due to a bug in the Rust code, 
a problem in the test page, or an issue in the backend server. Once we identify the cause, we can implement the necessary 
fixes to ensure that all tests pass successfully.
