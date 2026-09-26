---
status: in progress
priority: 0
description: |
  Build a debug APK in a claude.ai cloud session: the Android SDK installed by hand, Gradle
  pointed at a mirror of Maven Central because Central rate-limits the environment, and the
  steps written into the fresh-session note of both repos until a setup script replaces it.
---

# Build the APK in a cloud session

Spun off 2026-09-26. Phases in [`tracking.md`](tracking.md).

## Where this came from

The ask, after the repo split: "we expand the cloud environment to be able to build the debug apk. Both here in the current one and in the temporary guide for the future ones."
"The temporary guide" is the "Fresh cloud session" section of `docs/getting-started.md`, which both this repo and fala-language-tutor carry until `24_cloud_sessions` gives the environment a setup script.

It also answers a number the split left open: the tutor's APK size without `flutter_gemma`, which the tutor's build doc said was unmeasured.

## Decisions

- **Network.** The user added `dl.google.com` to the `Default` environment on 2026-09-26 (`24_cloud_sessions/00_start.md` Q7 had planned that for a new Flutter environment; `Default` got it first).
- **Maven Central through Google's mirror.** Central answered this environment with HTTP 429 on a third of plain requests and failed the first Gradle build. A Gradle init script in `~/.gradle/init.d/` rewrites every `mavenCentral()` URL to `maven-central.storage-download.googleapis.com`, which is on the Trusted list through `*.googleapis.com`. It is machine-level: no build file in either repo changes, so CI and the workstation are unaffected. Each repo carries a copy at `tool/maven-central-mirror.gradle` for the note to install.
- **Where this lives.** Here, in the guide, because it is setup of a headless machine; the tutor's copy of the note is the same text.

## Out of scope

- An emulator: there is no `/dev/kvm`.
- Release signing: the key stays off cloud machines (`19_apk_distribution/00_start.md` Q4, now in fala-language-tutor as `06_apk_distribution`).
- The setup script itself, which is `24_cloud_sessions`.
