---
status: draft
---

# Phase 2 - decide the supported ABI set

## Overview

Decide whether to drop armeabi-v7a (and possibly x86_64) via `abiFilters` in
`android/app/build.gradle.kts`, shrinking every build including the fat APK.
Gated on Q1/Q2 in [`00_start.md`](00_start.md); depends on phase 1 measurements.

## Goals

1. Explicit, recorded decision on the supported ABI list.
2. If ABIs are dropped: `abiFilters` set, fat APK size re-measured, docs updated.

## Plan

- Answer Q1 (armeabi-v7a) and Q2 (x86_64 for emulator) with the user.
- If dropping: add `ndk { abiFilters += listOf(...) }` to `defaultConfig`, rebuild, re-measure.
- Sanity-check that `flutter run` on the intended dev targets still works.

## Out of scope

- MediaPipe lib exclusions - phase 3.

## Done when

- Decision logged in `tracking.md`; build config matches it; docs agree.
