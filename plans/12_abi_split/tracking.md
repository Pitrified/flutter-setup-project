# implementation tracking

Split Android release builds per ABI so devices only get the native code they run,
and right-size the ABI set for an on-device LLM app.
Analysis and decisions in [`00_start.md`](00_start.md).

## Key decisions

- Fat APK stays the default `flutter build apk` output; per-ABI builds are an additional documented path.
- Play Store uploads stay AAB (already per-ABI server-side); this effort mostly serves sideload/test builds.
- ABI set (resolved 2026-07-09 via Q1/Q2): support **arm64-v8a + x86_64**; drop armeabi-v7a.
  x86_64 kept for emulators that live on other machines.
- Mechanism for dropping an ABI in a Flutter+plugin project: `packaging { jniLibs { excludes } }`
  in build.gradle.kts, NOT `ndk.abiFilters` (ignored for AAR libs + conflicts with --split-per-abi)
  and NOT `--target-platform` alone (only drops the engine lib, not plugin libs). Split builds must
  add `--target-platform android-arm64,android-x64` to avoid an empty v7a stub APK.
- Phase 3 remains gated on Q3 (are the MediaPipe vision/embedding libs loaded for text inference).

## Phases

| # | Phase                                   | Plan                                                     | Status |
| - | --------------------------------------- | -------------------------------------------------------- | ------ |
| 1 | split-per-abi build, measure, docs       | [`01_split_per_abi.md`](01_split_per_abi.md)             | done |
| 2 | restrict ABI set (drop armeabi-v7a)      | [`02_abi_set.md`](02_abi_set.md)                         | done |
| 3 | trim unused MediaPipe libs               | [`03_trim_mediapipe_libs.md`](03_trim_mediapipe_libs.md) | draft  |

Status values: draft / planned / in progress / done / superseded / discarded.

## Log

Append-only. Newest at the bottom.

- 2026-07-08 : bootstrapped the plan folder on branch `feat/abi-split`; measured the fat APK
  (272.7 MB, ~268 MB uncompressed native libs across arm64-v8a / armeabi-v7a / x86_64);
  drafted 3 phases, open questions Q1-Q4 pending user input
- 2026-07-09 : detailed phase 1 to `planned` - concrete build/measure/docs steps; confirmed bundletool
  is not installed (plan fetches the jar, no sudo needed); no existing `--split`/`abiFilters` refs in docs
- 2026-07-09 : phase 1 DONE. Built split APKs (arm64 160.4 / x86_64 79.5 / armeabi-v7a 40.3 MB) and AAB (221 MB).
  bundletool 1.18.3 fetched to ~/android-sdk/bundletool.jar (the /latest/download/ URL served HTML - used the
  versioned asset). Per-device Play download: arm64 64 MB, x86_64 33 MB, armeabi-v7a 21 MB. Updated
  docs/build-and-release.md with a split-per-abi subsection and a measured size-budget table (dropped the stale
  <30MB line). arm64 carries 14 .so libs vs 7 for x86_64 -> confirms phase 3 (trim vision/embedding libs) is the big win.
- 2026-07-09 : user answered Q1-Q4 in 00_start.md and pushed phase 1. Q1 drop armeabi-v7a, Q2 keep x86_64,
  Q3 check MediaPipe libs, Q4 no hard target. Detailed phase 2 to `planned`: add two-ABI abiFilters
  (arm64-v8a + x86_64), clean-rebuild, re-measure, update docs.
- 2026-07-09 : phase 2 DONE. abiFilters approach failed (didn't filter flutter_gemma AAR libs; conflicts
  with --split-per-abi) - pivoted to `packaging { jniLibs { excludes += "lib/armeabi-v7a/**" } }` in
  android/app/build.gradle.kts. Fat APK 272.7->236.1 MB, AAB 230.9->195.4 MB, both now arm64+x86_64 only;
  splits drop the v7a stub when paired with --target-platform. Per-device download unchanged (arm64 64 MB).
  Updated docs/build-and-release.md (split command + size table). On-device runtime check deferred (headless).
