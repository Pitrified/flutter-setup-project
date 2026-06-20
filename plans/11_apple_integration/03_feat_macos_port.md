---
status: draft
---

# Phase 3 - macOS Desktop Port

## Overview

Generate the `macos/` runner and make `fala` run as a desktop app. The decisive
question for this whole initiative lives here: does `flutter_gemma` (MediaPipe
GenAI) run on macOS desktop? The answer determines whether macOS is a real
target or just the host for iOS builds.

Context: [`00_intro.md`](00_intro.md), depends on
[`01_feat_toolchain_setup.md`](01_feat_toolchain_setup.md).

## Goals

1. Generate the macOS platform folder without disturbing Dart code.
2. Resolve the on-device engine story on macOS (native vs cloud fallback).
3. Get the app launching and usable as a desktop window.

## Plan

### 1. Generate platform
- `flutter config --enable-macos-desktop`.
- `flutter create --platforms=macos .` (adds `macos/` only).

### 2. Dependency audit (do this FIRST - it is the make-or-break step)
- **`flutter_gemma` / MediaPipe**: confirm macOS desktop support. If
  unsupported:
  - (a) gate the on-device engine off on macOS, fall back to the `openai_dart`
    cloud path, or
  - (b) keep macOS as a dev/preview target only.
- **`flutter_secure_storage`**: macOS Keychain - works, needs the **Keychain
  Sharing** entitlement.
- **`hive` + `path_provider`**: fine on macOS.

### 3. Entitlements / sandbox
- Edit `macos/Runner/*.entitlements`:
  - `com.apple.security.network.client` (cloud calls + model download).
  - Keychain access group for secure storage.
  - File read/write scope if the model is cached to disk.

### 4. Build config
- Set the min deployment target in `macos/Podfile` and Xcode (e.g. macOS 11+).
- `cd macos && pod install`.

### 5. Run + adapt UI
- `flutter run -d macos`.
- Fix touch/phone assumptions: window resizing, mouse input, larger layouts.

## Blockers

- The on-device LLM engine decision gates everything else - resolve it before
  any UI polish.
- App Sandbox blocks network/file/keychain by default; missing entitlements
  cause silent runtime failures, not build errors.

## Out of scope

- iOS (Phase 4) and store distribution (Phase 5).
- A polished desktop-specific redesign; aim for functional first.

## Done when

- The macOS engine decision is recorded in the Log (native vs cloud fallback vs
  preview-only).
- `flutter run -d macos` launches the app and a core flow works end-to-end
  under that decision.
