---
status: draft
---

# Cloud-first, and the fate of the on-device engine

Status: draft spin-off. Not picked up, no phases derived.

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

## The obvious open question

Whether "dismissed" means removed or demoted. Demoted (keep the code, stop treating it as the quality
bar) costs nothing today and keeps the offline story for a future device generation. Removed reclaims
about 60 MB of APK and a plugin dependency, and forecloses the offline claim.

Nothing here is decided. This folder gets a `tracking.md` and phases if and when it is picked up.
