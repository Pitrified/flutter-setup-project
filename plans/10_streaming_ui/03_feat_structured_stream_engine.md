---
status: done
---

# Phase 3 - StructuredStreamEngine + StructuredDelta (G1)

## Overview

The heart of S2 + G1. A generic streaming sibling to the existing one-shot
`StructuredInferenceEngine<T>`: it maps an engine's raw-text stream (phase 2)
through the tolerant parser (phase 1) and yields `Stream<StructuredDelta<T>>` -
a best-effort partial map plus a typed `T` materialized only at completion. No
per-schema partial classes (G1).

Context: [`00.2_structured_streaming_asis.md`](00.2_structured_streaming_asis.md)
sections 3 (S2), 4b (G1), 4c (arrive-as-you-go). Depends on
[`01_feat_partial_json_parser.md`](01_feat_partial_json_parser.md) and
[`02_feat_engine_stream_api.md`](02_feat_engine_stream_api.md).

## Goals

1. A generic `StructuredDelta<T>` value type (G1):
   ```dart
   class StructuredDelta<T> {
     final Map<String, dynamic> partial; // best-effort, any depth, nullable leaves
     final T? value;                     // non-null only when isComplete
     final bool isComplete;
     final StructuredFailure? failure;   // terminal inference/parse failure
   }
   ```
2. A `StructuredStreamEngine<T>` composing `InferenceEngine` + the partial parser
   + a `fromJson` factory, exposing
   `Stream<StructuredDelta<T>> generateStream(InferenceRequest)`.
3. Final emission materializes `value` via `fromJson` (the same factory the
   one-shot path uses) and sets `isComplete: true`.
4. Failure modes preserved: inference failure and final-parse failure surface as
   `failure`, mirroring the three-state `StructuredResult<T>` contract.

## Plan

- Define `StructuredDelta<T>` and a small `StructuredFailure` (reuse the wording
  of `StructuredInferenceFailure` / `StructuredParseFailure` from
  [`structured_inference_engine.dart`](../../lib/services/inference/structured_inference_engine.dart)
  so the streaming and one-shot vocabularies match).
- Implement `StructuredStreamEngine<T>`:
  - Subscribe to `engine.generateStream(request)`.
  - On each cumulative buffer, run phase-1 `parse` -> partial map; emit a
    `StructuredDelta(partial: map, isComplete: false)`. Carry the phase-1
    closed-flags through (either inside `partial` via a sidecar, or as an extra
    field) so phase 6 can tell final vs in-progress nodes.
  - Coalesce emissions: do not emit if the partial map is structurally unchanged
    since the last tick (cheap deep-equality or a revision counter), to limit
    downstream rebuilds. Optional time-based debounce parameter, default off.
  - On stream completion, run the **strict** final parse (existing
    `StructuredOutputParser<T>` / `fromJson`) on the full buffer; emit a terminal
    `StructuredDelta(value: T, isComplete: true)` or one with `failure` set.
  - Apply a timeout consistent with the one-shot engine (30s default); on
    timeout emit a terminal `failure` delta.
- Keep it **generic**: constructor takes `fromJson` (and the parser), exactly
  like `StructuredOutputParser<T>`. No `TutorResponse` reference anywhere in this
  file.
- Decide the relationship to `StructuredInferenceEngine<T>`: leave the one-shot
  class as-is for the *persisted* final message; `StructuredStreamEngine<T>` is
  the parallel live path. Optionally factor shared bits (timeout, failure
  mapping) but do not merge them.
- Tests (with the phase-2 fake engine + a `TutorResponse.fromJson` instance):
  - intermediate deltas have growing `partial`, `value == null`,
    `isComplete == false`;
  - a nested array element appears partial before it is closed (arrive-as-you-go
    is observable at this layer, not just the UI);
  - the terminal delta has a fully-typed `value` equal to the one-shot parse of
    the same fixture;
  - an inference failure and a malformed-final-JSON case both yield a terminal
    `failure` delta;
  - emission coalescing suppresses no-op ticks.

## Out of scope

- Real engines (phase 4).
- Riverpod providers / controller (phase 5).
- Any widget binding (phase 6).

## Done when

- `StructuredDelta<T>` and `StructuredStreamEngine<T>` exist, generic, no domain
  types referenced.
- The terminal typed `value` is byte-for-byte equivalent to the existing
  one-shot path for the same input.
- Unit tests above pass, including the arrive-as-you-go nested-element assertion
  and both failure modes.
