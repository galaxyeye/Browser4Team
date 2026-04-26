# Fix Bug in MCPToolControllerE2ETest.testMouseDialogAndTabCommands

```
java.lang.AssertionError: Expected mousedown to increment mouseDownCount
Last state: {"clickCount":0,"doubleClickCount":0,"hovered":false,"dragStarted":false,"dragDropped":"","promptResult":"","confirmResult":"","keyEvents":[],"mouseDownCount":0,"mouseUpCount":0,"lastMouse":[120,120],"lastWheel":null,"typeValue":"","fillValue":"","checkbox":false,"selectValue":"","uploadCount":0,"uploadName":"","submitCount":0}

	at ai.platon.pulsar.rest.api.controller.MCPToolControllerE2ETest.waitForState(MCPToolControllerE2ETest.kt:697)
	at ai.platon.pulsar.rest.api.controller.MCPToolControllerE2ETest.waitForState$default(MCPToolControllerE2ETest.kt:682)
	at ai.platon.pulsar.rest.api.controller.MCPToolControllerE2ETest.testMouseDialogAndTabCommands(MCPToolControllerE2ETest.kt:473)

```