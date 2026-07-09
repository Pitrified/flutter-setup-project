---
status: done
---

<!-- Results (2026-07-09): mechanism changed during implementation.
  The planned `ndk { abiFilters }` FAILED: it did not filter flutter_gemma's AAR jniLibs from the
  fat APK (still 272.7 MB, all 3 ABIs) AND it errors under `--split-per-abi` ("Conflicting
  configuration ... in ndk abiFilters cannot be present when splits abi filters are set").
  `--target-platform android-arm64,android-x64` also insufficient for the fat APK: only drops the
  Flutter *engine* v7a lib (272.7 -> 255.3 MB), plugin v7a libs remain.
  WORKING mechanism: `packaging { jniLibs { excludes += "lib/armeabi-v7a/**" } }` in build.gradle.kts
  - strips v7a from fat APK (236.1 MB), AAB (195.4 MB), and splits, persistently, no build flag.
  Caveat: `--split-per-abi` alone still emits a 3.8 MB empty v7a stub APK; pair it with
  `--target-platform android-arm64,android-x64` to suppress the stub.
  Verified by inspecting ABIs inside each artifact (fat/AAB now list only arm64-v8a + x86_64).
  Per-device Play download unchanged (arm64 64 MB, x86_64 33 MB) - dropping v7a changes on-disk
  size, not what an arm64 user downloads. On-device runtime check deferred (headless box). -->

# Phase 2 - restrict the supported ABI set

## Overview

Drop armeabi-v7a from every build and keep arm64-v8a + x86_64, via `abiFilters` in
`android/app/build.gradle.kts`. This shrinks the fat APK and CI artifacts and stops shipping
32-bit native libs that no realistic on-device-LLM phone needs.
Resolves Q1 (drop armeabi-v7a) and Q2 (keep x86_64 for emulators on other machines) in
[`00_start.md`](00_start.md). Depends on phase 1 (baseline sizes measured).

## Goals

1. Builds produce only arm64-v8a and x86_64; armeabi-v7a is gone from fat APK, split APKs, and AAB.
2. Fat APK and arm64 split re-measured; docs updated to match the new ABI set.
3. `flutter run` still works on an arm64 device and an x86_64 emulator.

## Plan

### Step 1 - add abiFilters

In `android/app/build.gradle.kts`, inside `defaultConfig { ... }`, add:

```kotlin
ndk {
    abiFilters += listOf("arm64-v8a", "x86_64")
}
```

This restricts which native libs Gradle packages for all build types and both the fat and
`--split-per-abi` outputs. No `splits` block is needed - `--split-per-abi` still emits one APK
per surviving ABI.

### Step 2 - rebuild and re-measure

```bash
export PATH="$HOME/flutter/bin:$PATH"; export ANDROID_HOME="$HOME/android-sdk"
flutter clean            # abiFilters change; avoid stale packaged libs
flutter build apk --release                       # fat, now 2 ABIs
flutter build apk --release --split-per-abi        # expect only arm64-v8a + x86_64 outputs
flutter build appbundle --release
du -h build/app/outputs/flutter-apk/*.apk
java -jar ~/android-sdk/bundletool.jar build-apks \
  --bundle=build/app/outputs/bundle/release/app-release.aab --output=/tmp/fala2.apks --overwrite
java -jar ~/android-sdk/bundletool.jar get-size total --apks=/tmp/fala2.apks --dimensions=ABI
```

Confirm: no `app-armeabi-v7a-release.apk` is produced; bundletool lists only two ABIs.
Fat APK should drop by roughly the armeabi-v7a lib weight (~40 MB on disk).

### Step 3 - verify runtime

- `flutter run --release` on an arm64 physical device (hand off to user - box is headless).
- `flutter run` on an x86_64 emulator (on a machine that has one) still launches.
  If neither is reachable now, record the abiFilters change and defer the live check with a note.

### Step 4 - docs

- Update the size-budget table in `docs/build-and-release.md` (drop the armeabi-v7a rows, refresh
  fat/arm64/x86_64 numbers).
- In the split-per-abi outputs table, drop the armeabi-v7a row and note the app targets arm64 + x86_64 only.

## Out of scope

- Excluding unused MediaPipe `.so` libs (vision/embedding) - phase 3. That is where the large arm64
  reduction lives; this phase only removes an entire ABI, not libs within an ABI.

## Done when

- `build.gradle.kts` has the two-ABI `abiFilters`; a clean build emits no armeabi-v7a artifacts.
- New sizes logged in `tracking.md`; docs tables updated.
- Runtime check on arm64 + x86_64 done, or explicitly deferred with a note in the Log.
