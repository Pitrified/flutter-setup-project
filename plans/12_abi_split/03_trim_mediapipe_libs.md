---
status: in progress
---

# Phase 3 - trim unused MediaPipe / RAG native libs

## Overview

flutter_gemma (0.13.6) bundles native libs for three feature areas via transitive Maven deps,
but the app only does text inference. Exclude the image-generation and RAG/embedding `.so` files
to cut the arm64 APK roughly in half. This is the largest size win and the only phase with
runtime risk (an eagerly-loaded lib would crash with `UnsatisfiedLinkError`).
Resolves Q3 in [`00_start.md`](00_start.md). Depends on phase 2 (packaging-excludes mechanism proven).

## Finding: the app is text-only

`lib/services/inference/flutter_gemma_engine.dart` uses only `FlutterGemma.installModel(...)` +
`InferenceModel` with `ModelType.qwen3`, `ModelFileType.litertlm`. No embedding, RAG, or image-gen API
is called anywhere in `lib/`. So only the LLM libs are needed at runtime.

## Lib -> Maven dep -> feature map (arm64 sizes)

Source deps in `~/.pub-cache/.../flutter_gemma-0.13.6/android/build.gradle`:

| `.so` lib | Size | From dep | Feature | Needed? |
|-----------|------|----------|---------|---------|
| libllm_inference_engine_jni | 26.4 MB | tasks-genai | text LLM | **keep** |
| liblitertlm_jni | 20.6 MB | litertlm-android | text LLM (litertlm format) | **keep** |
| libgemma_embedding_model_jni | 17.0 MB | localagents-rag | RAG embeddings | drop |
| libgecko_embedding_model_jni | 17.0 MB | localagents-rag | RAG embeddings | drop |
| libmediapipe_tasks_vision_jni | 14.3 MB | tasks-vision-image-generator | image gen | drop |
| libmediapipe_tasks_vision_image_generator_jni | 14.0 MB | tasks-vision-image-generator | image gen | drop |
| libimagegenerator_gpu | 10.4 MB | tasks-vision-image-generator | image gen | drop |
| libtext_chunker_jni | 9.4 MB | localagents-rag | RAG chunking | drop |
| libsqlite_vector_store_jni | 7.5 MB | localagents-rag | RAG vector store | drop |
| libsqlite3 | 1.7 MB | (shared) | keep - may back app's conversation store | keep |
| libflutter / libapp / libdartjni / libdatastore_shared_counter | - | Flutter | engine/app | keep |

Removable: image-gen group (~38.7 MB) + RAG group (~50.9 MB) = **~89 MB** off arm64.
Projected arm64 split APK ~71 MB, fat APK well under 150 MB.

## Plan

### Step 1 - add the excludes

Extend the `packaging { jniLibs { excludes } }` block in `android/app/build.gradle.kts`
(added in phase 2) with the unused libs:

```kotlin
excludes += listOf(
    "lib/armeabi-v7a/**",               // phase 2
    // image generation (unused - app is text-only)
    "**/libmediapipe_tasks_vision_jni.so",
    "**/libmediapipe_tasks_vision_image_generator_jni.so",
    "**/libimagegenerator_gpu.so",
    // RAG / embeddings (unused)
    "**/libgemma_embedding_model_jni.so",
    "**/libgecko_embedding_model_jni.so",
    "**/libtext_chunker_jni.so",
    "**/libsqlite_vector_store_jni.so",
)
```

Pin the flutter_gemma version this was verified against in a comment; re-verify on plugin upgrade,
since a new version could load these eagerly or rename them.

### Step 2 - build and measure

```bash
export PATH="$HOME/flutter/bin:$PATH"; export ANDROID_HOME="$HOME/android-sdk"
flutter clean
flutter build apk --release --split-per-abi --target-platform android-arm64,android-x64
unzip -l build/app/outputs/flutter-apk/app-arm64-v8a-release.apk "lib/arm64-v8a/*" | grep '\.so'
du -h build/app/outputs/flutter-apk/app-*-release.apk
```

Confirm the seven libs are gone and only the LLM/engine libs remain.

### Step 3 - runtime verification (the gate)

Static analysis says these libs are unused, but flutter_gemma could load one eagerly during
`installModel`/model init. This MUST be exercised on a real device before the excludes are kept:

- Install the trimmed arm64 APK on a device.
- Run the full text flow: model download/install, start a conversation, generate a reply,
  and any structured-output path the app uses.
- Watch `adb logcat | grep -iE "UnsatisfiedLinkError|dlopen|couldn't find|flutter"` for load failures.

Headless box: this step hands off to the user (needs a device + display). Do not mark the phase
`done` on static analysis alone - excludes that crash at runtime are worse than the size.

### Step 4 - docs

Update the size-budget table in `docs/build-and-release.md` with the trimmed numbers and a note
that the build ships text-inference libs only (image-gen and RAG excluded).

## Out of scope

- Excluding the Maven deps themselves (dependency-level `exclude group:`). Heavier-touch and can
  break flutter_gemma's compilation if its Kotlin imports those classes; packaging excludes strip
  only the runtime `.so` and are reversible. Revisit only if class-level bloat matters.
- Adding RAG or image generation to the app (would require reverting the relevant excludes).

## Done when

- Excludes in `build.gradle.kts`; a build shows only the LLM libs in arm64.
- Full text flow verified on a real device with no load errors (or, if a lib proves required,
  that finding is logged, the specific exclude reverted, and the phase closed as partial).
- Docs updated with trimmed sizes.

## Results so far (2026-07-09, box - build only)

Excludes applied and committed. Build-side confirmed; **runtime NOT yet verified**.

| Artifact | Before trim | After trim |
|----------|-------------|------------|
| Fat APK | 236.1 MB | 146.5 MB |
| Split arm64-v8a | 160.4 MB | 70.8 MB |
| Split x86_64 | 79.5 MB | 79.5 MB (never had the libs) |
| AAB | 195.4 MB | 124.1 MB |
| Play download, arm64 | 64 MB | **31 MB** |
| Play download, x86_64 | 33 MB | 33 MB |

arm64 now retains only: llm_inference_engine, litertlm, flutter, app, sqlite3, dartjni,
datastore_shared_counter. The 7 image-gen/RAG libs are gone.

## TODO - runtime verification on G7 (blocks phase `done`)

This box is headless, so the excludes are unverified at runtime. Do this on G7 with a real
device (or an arm64/x86_64 emulator). If any check fails, revert the relevant exclude in
`android/app/build.gradle.kts` and log which lib is actually required.

- [ ] Pull branch `feat/abi-split` on G7; `flutter pub get`.
- [ ] `flutter build apk --release --split-per-abi --target-platform android-arm64,android-x64`.
- [ ] Install the matching split APK on the device
      (`adb install build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`).
- [ ] Start `adb logcat -c && adb logcat | grep -iE "UnsatisfiedLinkError|dlopen|couldn't find|E/flutter|FATAL"`
      before launching, and watch it throughout.
- [ ] Launch the app; confirm it reaches the main screen without a native-load crash.
- [ ] Run model install/download (`installModel`, qwen3 / litertlm) to completion.
- [ ] Start a conversation and generate at least one reply (exercises libllm_inference_engine + liblitertlm).
- [ ] Exercise the structured-output path the app uses (JSON/schema generation), if separate.
- [ ] Visual check: no error banners, replies render, no crash on repeated generations.
- [ ] Confirm logcat shows zero `UnsatisfiedLinkError` / `dlopen` failures for the excluded libs.
- [ ] If all pass: set phase 3 `status: done` in this file + tracking table, log the result.
- [ ] If any fail: revert the offending exclude(s), rebuild, re-run, and record the finding.

Note: prefer testing on a physical arm64 device over an emulator - x86_64 kept a different lib set,
so an x86_64 emulator would not exercise the exact arm64 libs that were trimmed.
