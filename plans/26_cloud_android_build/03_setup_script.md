---
status: draft
---

# Phase 03 - Fold into the setup script

## Sketch

When `24_cloud_sessions` writes the environment's setup script, the Android steps go in it. Points to settle then:

- The script should finish in about five minutes. The SDK install is fast; the first Gradle build, with the NDK and the dependency cache, took over five minutes here. Whether to warm the Gradle cache in the script, or leave the first build slow, is that folder's call.
- The snapshot keeps files, so an installed SDK and a warm `~/.gradle` survive into later sessions.
- The mirror script is still needed while Central rate-limits the environment's egress.
