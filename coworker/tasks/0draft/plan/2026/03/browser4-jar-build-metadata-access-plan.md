# Build Metadata for `Browser4.jar`

For a typical Kotlin/Java/Spring application, what brand-related, product-related, build-related, and release-related metadata should be included? Common examples may include manufacturer, product name, version, build number, release date, and similar fields.

Please provide a clear list of the recommended metadata fields, and for each one explain:

- what it represents
- why it matters
- when it is important in development, release, operations, support, or integration scenarios

Then explain how this metadata should be collected and updated during each build of `Browser4.jar`. Cover practical sources of truth such as build scripts, Git data, CI/CD pipelines, environment variables, release processes, and manually maintained product information where appropriate.

After that, explain how consumers of the built artifact, such as `browser4-cli`, should access this metadata after the build is complete. Include the most practical access patterns for Java-based artifacts, such as manifest entries, embedded resource files, Spring build information, version endpoints, or dedicated APIs, and describe the trade-offs of each approach.

Please answer the questions first, and then provide a concrete implementation plan.

Use English for the entire document.
