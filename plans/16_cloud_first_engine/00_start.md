---
status: superseded
priority: 0
description: |
  Remove the on-device engine entirely: drop flutter_gemma and the first-launch
  model download, reclaim most of the APK, and rewrite the offline claim that no
  longer holds. Raised because APK size is the priority and local models are too
  shaky and slow to keep.
---

# Cloud-first, and the fate of the on-device engine

Superseded on 2026-09-26 by [`../20_repo_split/00_start.md`](../20_repo_split/00_start.md) Q5.
The tutor moves to `fala-language-tutor`, which is written cloud only, so nothing is removed here: the on-device engine stays in this repo as a gallery pattern. The body below is the record of the removal plan as it stood.

Status: draft spin-off, **raised to priority 1 on 2026-09-25** and the open question below is
answered: the ask was "reduce the APK size even more, no local models at all", which is the
*removal* branch, not the demotion one. Phases still to be derived.

## Where this came from

Answering Q5 of [`../15_target_language/00_start.md`](../15_target_language/00_start.md) on
2026-09-24: "Local models are soon to be dismissed. Too shaky and slow. We target cloud main for now."

That settled the language question it was asked about (nothing is gated on measuring Qwen3-0.6B in a
second language), but it is a statement about the product, not about languages, and it is out of scope
for phase 15. It is recorded here so the decision is not buried in another feature's answer slot.

## What it would mean

An inventory, not a plan. Dropping `flutter_gemma` and the on-device path would touch:

- `EngineKind` and the engine registry, the fake engine staying for tests.
- `ModelDownloadScreen`, `RuntimeModelManager`, `ModelConfig`, and the whole first-launch download
  flow, which exists only to fetch a `.litertlm` file.
- The APK: `flutter_gemma` and the MediaPipe/LiteRT native libs are what phase 12 spent its effort
  trimming (fat APK 273 to 103 MB, arm64 split 160 to 43 MB). Without them the app is a thin client.
- The offline claim. "Fully offline after model download" is in the functional specs, the store
  listing and the privacy policy, and a cloud-only app cannot make it.
- The key distribution problem gets worse, not better: with no on-device fallback, a user without a
  working key has no app at all. That is [`../13_key_distribution/00_start.md`](../13_key_distribution/00_start.md).
- Phase 14's audio options inherit the same shift, since the local-vs-cloud axis there was partly
  justified by the app already running a local model.

## The open question, now answered

Whether "dismissed" meant removed or demoted. **Removed** (2026-09-25): no local models at all, and
APK size is the reason, so keeping the code for a future device generation does not buy anything.

What that makes concrete, and what phases will have to cover:

- Drop the `flutter_gemma` dependency, `FlutterGemmaEngine`, and `EngineKind.gemma`. `FakeInferenceEngine`
  stays: every test uses it.
- Delete the first-launch download path that exists only to fetch a `.litertlm` file:
  `ModelDownloadScreen`, `RuntimeModelManager`, `ModelConfig`, the `model_metadata` Hive box, and the
  `AppNeedsModel` state and its redirect in `app.dart`.
- Undo what phase 12 needed: the `jniLibs.excludes` block and the ABI notes in
  `docs/build-and-release.md` exist to trim MediaPipe and LiteRT native libraries that will no longer
  be there. Measure the new APK rather than predicting it; the current arm64 split is 43 MB and almost
  all of that is native code being removed.
- Rewrite the offline claim wherever it appears: `docs/functional-specs.md`, the store listing, and
  `docs/privacy-policy.md`. A cloud-only app cannot say "fully offline after model download".
- Note the dependency both ways with [`../13_key_distribution/00_start.md`](../13_key_distribution/00_start.md):
  with no local fallback, a user without a working key has no app at all, so key distribution stops
  being a nicety.

This folder gets a `tracking.md` and phases when it is picked up.
