# implementation tracking

Split Android release builds per ABI so devices only get the native code they run,
and right-size the ABI set for an on-device LLM app.
Analysis and decisions in [`00_start.md`](00_start.md).

## Key decisions

- Fat APK stays the default `flutter build apk` output; per-ABI builds are an additional documented path.
- Play Store uploads stay AAB (already per-ABI server-side); this effort mostly serves sideload/test builds.
- Phases 2 and 3 are gated on open questions Q1-Q3 in `00_start.md`.

## Phases

| # | Phase                                   | Plan                                                     | Status |
| - | --------------------------------------- | -------------------------------------------------------- | ------ |
| 1 | split-per-abi build, measure, docs       | [`01_split_per_abi.md`](01_split_per_abi.md)             | done |
| 2 | decide ABI set (drop armeabi-v7a?)       | [`02_abi_set.md`](02_abi_set.md)                         | draft  |
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
