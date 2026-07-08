---
status: done
---

<!-- Results (2026-07-09):
  Split APKs on disk: arm64-v8a 160.4 MB, x86_64 79.5 MB, armeabi-v7a 40.3 MB (fat 272.7 MB).
  Play download from AAB (bundletool get-size --dimensions=ABI): arm64 64 MB, x86_64 33 MB, armeabi-v7a 21 MB.
  bundletool: /latest/download/ redirect served HTML (corrupt jar); use the versioned asset URL instead.
  arm64 is heaviest - it alone carries 14 native .so libs vs 7 for x86_64 (embedding + vision libs) -> phase 3 target.
  Fat path unchanged (no gradle/Dart edits), verified by inspection, no rebuild. -->


# Phase 1 - split-per-abi build, measure, docs

## Overview

Adopt `flutter build apk --release --split-per-abi` as the documented path for sideload/test builds,
measure the real per-ABI APK sizes and the AAB per-device download size, and replace the stale
"<30MB" size budget in `docs/build-and-release.md` with measured numbers.
No gradle or Dart changes - this phase is build invocation, measurement, and docs only.
Context: [`00_start.md`](00_start.md).

## Goals

1. Per-ABI release APKs build cleanly; each `app-<abi>-release.apk` size is recorded in `tracking.md`.
2. AAB per-device download size measured as the Play Store reference number.
3. `docs/build-and-release.md` documents the split build path and carries a realistic, sourced size budget.
4. The default `flutter build apk --release` (fat APK) path still works unchanged.

## Plan

### Step 1 - build split APKs and measure

```bash
export PATH="$HOME/flutter/bin:$PATH"; export ANDROID_HOME="$HOME/android-sdk"
cd /home/pmn/repos/flutter-setup-project
flutter build apk --release --split-per-abi
ls -lh build/app/outputs/flutter-apk/app-*-release.apk
```

Expect three outputs: `app-arm64-v8a-release.apk`, `app-armeabi-v7a-release.apk`, `app-x86_64-release.apk`.
Record each size. arm64 is the number that matters for real devices (projected ~90-110 MB from `00_start.md`).
Note: this is a warm build (Gradle deps cached from the first fat build), so expect minutes, not ~22 min.

### Step 2 - build the AAB and measure per-device download

```bash
flutter build appbundle --release
ls -lh build/app/outputs/bundle/release/app-release.aab
```

The `.aab` on-disk size is not the user download size (it holds all ABIs). To get the real per-device number,
use bundletool. It is **not installed** (no sudo needed - it is a single jar):

```bash
# one-time: fetch bundletool jar into the SDK dir
curl -sL -o ~/android-sdk/bundletool.jar \
  https://github.com/google/bundletool/releases/latest/download/bundletool-all.jar
java -jar ~/android-sdk/bundletool.jar build-apks \
  --bundle=build/app/outputs/bundle/release/app-release.aab \
  --output=/tmp/fala.apks --mode=default
java -jar ~/android-sdk/bundletool.jar get-size total --apks=/tmp/fala.apks --dimensions=ABI
```

Fallback if the bundletool download is unavailable: unzip the `.aab` and sum
`base/lib/arm64-v8a/*` + `base/dex` + `base/res` + `base/assets` for a rough arm64 install estimate,
and label the number "approximate" in the docs.

### Step 3 - update docs

In `docs/build-and-release.md`:

- Add a "Smaller APKs (split per ABI)" subsection under Quick start with the `--split-per-abi` command
  and the three output paths.
- Add a one-line caveat that split APKs get per-ABI-offset versionCodes (Flutter adds 1000/2000/... );
  irrelevant for AAB uploads, matters only if uploading split APKs directly to Play.
- Replace the `## Size budget` section: drop the unreachable "<30MB" line. State two measured numbers:
  fat APK size, arm64-only split APK size, and the bundletool per-device download from the AAB.
  Keep the "model downloads separately at runtime" note.

## Out of scope

- Changing default build behavior via `abiFilters` / gradle `splits` block - phase 2.
- Excluding unused MediaPipe `.so` libs - phase 3.
- Deleting the fat APK path or editing `plans/07_release` release scripts.

## Done when

- All three split APK sizes and the AAB per-device size are logged in `tracking.md`.
- `docs/build-and-release.md` reflects the split command and measured budget; the stale <30MB line is gone.
- `flutter build apk --release` (fat) still produces `app-release.apk` unchanged.
