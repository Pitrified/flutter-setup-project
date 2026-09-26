---
status: done
---

# Phase 01 - Build the APK in this session

## Overview

Install the Android SDK in the running session and build fala-language-tutor's debug APK.

## What the implementation found

- **SDK:** command-line tools `16111833` (the newest in Google's repository index), `platform-tools`, `platforms;android-36`, `build-tools;36.0.0`: 19 s, 488 MB. Licences accepted with `yes | sdkmanager --licenses`.
- **First build failed** after 108 s: Gradle got HTTP 429 from `repo.maven.apache.org`, reached both directly and through `plugins.gradle.org` redirects. Three plain `curl` requests to the same POM gave 200, 200, 429; Google's mirror of Central gave 200.
- **The init script, second attempt.** Adding the mirror as a new first repository failed: Flutter's Gradle plugin build prefers settings repositories and rejects one added to a project. Rewriting the URL of every existing `mavenCentral()` repository instead worked.
- **Debug build:** 341 s cold, of which Gradle installed NDK `28.2.13676358` and CMake 3.22.1 itself. `app-debug.apk` is 122.4 MB.
- **Release split build**, warm: 129 s. arm64-v8a 17.8 MB, x86_64 19.1 MB, against 43 MB and 48 MB when the app still carried `flutter_gemma`. Recorded in the tutor's `docs/build-and-release.md`.
- **Disk:** the SDK grew to 2.9 GB and `~/.gradle` to 4.3 GB.
- JDK 21 from the base image was accepted by AGP 9.0.1 and Gradle 9.1.0; nothing needed Java 17.
