# Improve WebDriver Method: `selectOption`

Known issue:

The current implementation cannot select the `branch` control on GitHub's agents page, even though it is a `<select>` element.

We need a better implementation of the `selectOption` method in `PulsarWebDriver.kt` so it can handle select elements more reliably and in a way that better resembles real user interaction.

- [GitHub Agents](https://github.com/platonai/Browser4/agents?author=galaxyeye)
- [PulsarWebDriver.kt](../../../../submodules/Browser4/pulsar-core/pulsar-plugins/pulsar-protocol/src/main/kotlin/ai/platon/pulsar/protocol/browser/driver/cdt/PulsarWebDriver.kt)
