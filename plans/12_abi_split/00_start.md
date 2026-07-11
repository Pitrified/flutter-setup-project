# ABI split for release APKs - brainstorm

## The idea

The first release build on the Linux box produced a 272.7 MB fat APK.
Split the build per ABI so a device only downloads the native code it can run,
and decide which ABIs we actually support.

## Current state

- `flutter build apk --release` builds one fat APK with three ABIs:
  arm64-v8a (14 libs), armeabi-v7a (6 libs), x86_64 (7 libs).
- Uncompressed native libs total ~268 MB of the 272.7 MB APK; the Dart/assets part is small.
- The weight comes from `flutter_gemma`'s bundled MediaPipe stack, per ABI:
  `libllm_inference_engine_jni.so` (19-30 MB), `liblitertlm_jni.so` (~20-24 MB),
  `libgemma_embedding_model_jni.so` + `libgecko_embedding_model_jni.so` (~17 MB each),
  `libmediapipe_tasks_vision_jni.so` + `libmediapipe_tasks_vision_image_generator_jni.so` (~14 MB each).
- `android/app/build.gradle.kts` has no `splits` or `abiFilters` config; minSdk 26, target/compile 36.
- `docs/build-and-release.md` states a size budget of "<30MB APK (model downloads separately at runtime)".
  That budget predates the flutter_gemma native libs and is unreachable while they are bundled;
  an arm64-only APK will land around 90-110 MB.

## Options considered

1. **`flutter build apk --release --split-per-abi`** - no code change, produces one APK per ABI
   (`app-arm64-v8a-release.apk` etc.). Flutter offsets versionCode per ABI automatically.
   Best for sideloading/testing; the fat APK remains available when wanted.
2. **`abiFilters` in `build.gradle.kts`** - permanently restrict which ABIs are built.
   Dropping armeabi-v7a (32-bit, pre-2016 phones; questionable for on-device LLM anyway)
   and keeping arm64-v8a + x86_64 (emulator) is defensible.
   Riskier than option 1 because it changes every build, including `flutter run` on an emulator if x86_64 is dropped.
3. **`flutter build appbundle`** - the Play Store serves per-ABI splits automatically from an AAB.
   Already the documented upload format in `docs/build-and-release.md` and `plans/07_release/`;
   nothing to do beyond verifying the per-ABI download size from the bundle.
4. **Trim unused MediaPipe libs** - the vision and image-generator libs (~28 MB/ABI) look unrelated
   to our text-only usage; embedding model libs (~34 MB/ABI) may also be unused.
   Would need `packagingOptions` excludes and runtime verification that flutter_gemma does not load them lazily.
   Highest payoff per ABI but also the only option that can break at runtime.

## Proposed approach

Do option 1 now (pure build/docs change, zero risk), sizing the per-ABI APKs to get real numbers.
Fold option 3 in as a verification step since the release plan already uses AAB.
Treat options 2 and 4 as follow-up phases gated on the open questions below.

## Decisions

- Keep the fat APK as the default `flutter build apk` output for now; the split is an additional
  documented path, not a replacement (avoids surprising `plans/07_release` scripts and docs).
- Update the stale <30MB size budget in `docs/build-and-release.md` to reflect reality,
  splitting it into "APK ceiling" and "Play Store download size" numbers once measured.

## Open questions

- Q1: Do we support armeabi-v7a at all? A 32-bit device running a local LLM is unrealistic;
  dropping it via abiFilters halves nothing for users (they download one ABI anyway)
  but shrinks the fat APK and CI artifacts.
  ANS: drop it
- Q2: Is x86_64 needed day-to-day? Only for PC emulators; the box is headless with no AVD yet.
  ANS: keep it, we do have emulators (on other machines)
- Q3: Are the vision / image-generator / embedding MediaPipe libs actually loaded by flutter_gemma
  for text inference, or safe to exclude (option 4)?
  ANS: no. The app uses only the LiteRT-LM path (ModelType.qwen3 / ModelFileType.litertlm,
  Qwen3-0.6B.litertlm) with no embedding/RAG and no .task/.bin models. The MediaPipe libs
  (tasks-genai, tasks-vision-image-generator) and RAG libs (localagents-rag) are unused ->
  safe to exclude, pending an on-device re-test after excluding. See tracking.md 2026-07-11.
- Q4: What is the acceptable download size target to replace the stale <30MB budget?
  ANS: whatever, app needs to work

