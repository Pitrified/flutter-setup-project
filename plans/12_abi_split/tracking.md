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
| 2 | decide ABI set (drop armeabi-v7a?)       | [`02_abi_set.md`](02_abi_set.md)                         | done   |
| 3 | trim unused MediaPipe libs               | [`03_trim_mediapipe_libs.md`](03_trim_mediapipe_libs.md) | done   |

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
- 2026-07-11 : rebuilt split APKs on g7 (arm64 153 / x86_64 76 / armeabi-v7a 38 MB on disk;
  flutter reports 160.4 / 79.5 / 40.3 MB uncompressed). Debug-signed (no key.properties on this box).
  Installed app-arm64-v8a-release.apk on the connected Pixel 7 Pro (versionCode 2001) and launched it.
- 2026-07-11 : on-device smoke test PASSED on the Pixel 7 Pro - model download + structured
  streaming generation both work on the arm64 split APK. Runtime log confirms the LiteRT-LM path
  (`LiteRtLmSession`, `fileType=litertlm, modelType=qwen3`).
- 2026-07-11 : Q3 RESOLVED (unblocks phase 3). Could not read /proc/maps (release APK not
  debuggable, device unrooted), so resolved by source: flutter_gemma 0.13.6 has two independent
  engine paths from separate deps - LiteRT-LM (`litertlm-android:0.10.0`, .litertlm models) and
  MediaPipe (`tasks-genai:0.10.33` + `tasks-vision-image-generator:0.10.26.1`, .task/.bin models),
  plus RAG (`localagents-rag:0.3.0`). The app uses ONLY ModelType.qwen3 / ModelFileType.litertlm
  (Qwen3-0.6B.litertlm) with no embedding/RAG and no .task/.bin usage anywhere in lib/. So the
  MediaPipe + RAG native libs are all unused for this app and are phase-3 exclusion candidates:
  libllm_inference_engine_jni, libmediapipe_tasks_vision_jni,
  libmediapipe_tasks_vision_image_generator_jni, libgemma_embedding_model_jni,
  libgecko_embedding_model_jni (~75-90 MB/ABI). Must still verify on-device after excluding, since
  a static initializer could dlopen one at plugin init.
- 2026-07-11 : phases 2 + 3 DONE and verified on-device. Phase 2: ndk.abiFilters does NOT work with
  the Flutter plugin (it appends to a set the plugin re-seeds with all ABIs, and conflicts with
  --split-per-abi) - dropped armeabi-v7a via `--target-platform android-arm64,android-x64` instead,
  documented in docs/build-and-release.md. Phase 3: added `packaging { jniLibs.excludes }` in
  android/app/build.gradle.kts for 8 unused libs (the 5 above + libimagegenerator_gpu,
  libtext_chunker_jni, libsqlite_vector_store_jni found in the full APK inventory); kept
  liblitertlm_jni and libsqlite3. Results: fat APK 273 -> 103 MB, split arm64 160 -> 43 MB,
  x86_64 80 -> 48 MB, no v7a APK. Reinstalled trimmed arm64 on the Pixel 7 Pro: LiteRT-LM engine
  initialized and a structured-output generation streamed valid JSON with no UnsatisfiedLinkError -
  the excludes are safe. Re-verify the exclude list on flutter_gemma upgrades.
