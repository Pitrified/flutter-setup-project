---
status: planned
---

# Phase 2 - Android APK from the CLI (no Android Studio)

## Overview

Prove the new Mac can reproduce the app you already ship by building the Android
APK from the command line only - no Android Studio. This validates the Flutter
toolchain end-to-end before tackling Apple platforms, and confirms the release
signing chain works on the new machine.

Context: [`00_intro.md`](00_intro.md), depends on
[`01_feat_toolchain_setup.md`](01_feat_toolchain_setup.md).

## Goals

1. Install the Android SDK command-line tools + JDK without the IDE.
2. Build a debug APK (sanity) and a signed release APK.
3. Install and launch on a physical Android device.

## Plan

### 1. SDK + JDK
- `brew install --cask android-commandlinetools`.
- `brew install --cask temurin17` (JDK).
- Set `ANDROID_HOME` and `JAVA_HOME` in the shell profile.

### 2. SDK packages + licenses
- `sdkmanager "platform-tools" "platforms;android-36" "build-tools;36.0.0"`.
- `flutter doctor --android-licenses`.
- Confirm `flutter doctor` Android section is green.

### 3. Signing material
- Recreate `android/key.properties` and the keystore at
  `~/cred/fala/upload-keystore.jks` (per [`../07_release/00_build_config.md`](../07_release/00_build_config.md)).
- Copy them securely; never commit them.

### 4. Build
- Sanity: `flutter build apk --debug`.
- Release: `flutter build apk --release` (and `flutter build appbundle` for
  Play).

### 5. Deploy
- `flutter install` or
  `adb install build/app/outputs/flutter-apk/app-release.apk`.

## Blockers

- Missing keystore -> release build fails. Build debug to unblock if needed.
- NDK / AGP version mismatches show up as Gradle errors - match the versions in
  `android/build.gradle.kts`.
- `flutter_gemma` pulls MediaPipe native libs; first build is slow and large.

## Out of scope

- Any Apple platform work.
- Changing the existing Android signing/release process (already done in
  Phase 07).

## Done when

- `flutter build apk --release` produces a signed APK.
- The APK installs and the app launches on a physical Android device.
