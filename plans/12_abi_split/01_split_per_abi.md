---
status: draft
---

# Phase 1 - split-per-abi build, measure, docs

## Overview

Adopt `flutter build apk --release --split-per-abi` as the documented path for sideload/test builds,
measure the real per-ABI sizes, and fix the stale <30MB size budget in the docs.
No gradle or code changes.
Context: [`00_start.md`](00_start.md).

## Goals

1. Per-ABI release APKs build cleanly and their sizes are recorded.
2. `docs/build-and-release.md` documents the split build and carries a realistic size budget.
3. AAB per-ABI download size verified as the Play Store reference number.

## Plan

- Run `flutter build apk --release --split-per-abi`; record the size of each `app-<abi>-release.apk`.
- Run `flutter build appbundle --release`; estimate per-device download size
  (`bundletool build-apks` + `get-size total`, or unzip inspection if bundletool is overkill).
- Update `docs/build-and-release.md`: add the split-per-abi command and outputs table,
  replace the <30MB budget with measured numbers (arm64 APK ceiling + Play download size).
- Note Flutter's automatic versionCode offsetting for split APKs
  (matters once Play Store uploads of APKs are involved; AAB avoids it).

## Out of scope

- Changing default build behavior (`abiFilters`, gradle splits config) - phase 2.
- Excluding MediaPipe libs - phase 3.

## Done when

- Split build succeeds and per-ABI sizes are logged in `tracking.md`.
- Docs updated; `flutter build apk --release` (fat) still works unchanged.
