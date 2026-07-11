---
status: done
---

# Phase 3 - trim unused MediaPipe libs

> Done 2026-07-11: excluded 8 unused .so files via `packaging { jniLibs.excludes }`; the app runs
> only the LiteRT-LM / qwen3 path. Verified on-device (structured-output generation, no
> UnsatisfiedLinkError). Split arm64 APK 160 -> 43 MB. See tracking.md.

## Overview

Investigate whether the vision, image-generator, and embedding-model `.so` files bundled by
flutter_gemma (~60 MB per ABI combined) are loaded for text-only inference,
and exclude them via `packaging { jniLibs.excludes }` if safe.
Gated on Q3 in [`00_start.md`](00_start.md). Highest payoff, only phase with runtime risk.

## Goals

1. Determine which flutter_gemma native libs the app actually loads.
2. Exclude confirmed-unused libs and verify inference still works on a device.

## Plan

- Inspect flutter_gemma's Android source for `System.loadLibrary` calls and lazy loading paths.
- Prototype excludes in `build.gradle.kts`, rebuild, run on a real device
  (emulator inference may not exercise the same code path).
- Exercise the full LLM flow (model download, generate, structured output) before calling it safe.
- Keep the exclude list commented with the flutter_gemma version it was verified against;
  re-verify on plugin upgrades.

## Out of scope

- Forking or patching flutter_gemma.

## Done when

- Either excludes land with a verified on-device LLM run, or the finding
  "libs are required" is logged and the phase is discarded.
