# End-to-End Test: Skill Installation

Create an end-to-end (E2E) test to verify skill searching and installation. The test should be implemented in the `pulsar-e2e-tests` module and execute the following task:

```kotlin
val task = """
Search and install the following SKILLs:

self-improving-agent（自我迭代）
skill-creator（技能创造）
find-skills（发现新技能）
skills-vetter（保证技能安全）
automation-workflows（把技能串起来当工作流）

You should search for the skills using a browser, find the installation instructions, and then install them.
After installation, verify that they are working correctly by running a simple test command for each skill.
Document the entire process, including any challenges faced and how they were overcome.
"""

agent.run(task)
```

Ensure the test is robust and runs successfully. If you encounter any implementation issues, document both the problems and your resolutions.

## References

[pulsar-e2e-tests](../../../submodules/Browser4/pulsar-tests/pulsar-e2e-tests)
