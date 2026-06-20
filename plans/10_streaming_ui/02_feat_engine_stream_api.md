---
status: planned
---

# Phase 2 - Engine streaming API + Fake implementation

## Overview

Add a streaming method to the `InferenceEngine` interface so callers can consume
output as it is produced, and implement it first in `FakeInferenceEngine` -
which lets every downstream phase be built and tested with no network or device.
This is the smallest interface change that unblocks S2.

Context: [`00.2_structured_streaming_asis.md`](00.2_structured_streaming_asis.md)
sections 1.3 + 6. The current interface only has
`Future<InferenceResult> generate(...)`
([`inference_engine.dart`](../../lib/services/inference/inference_engine.dart)),
which collapses everything to a single value - the first hard buffering
boundary.

## Goals

1. A new method on `InferenceEngine`:
   `Stream<String> generateStream(InferenceRequest request)`.
2. A clear contract for what the stream yields (see decision below).
3. `FakeInferenceEngine` implements it by chunking a fixture so partial states
   are realistic (mid-string, mid-array).
4. `generate` and `generateStream` coexist; the one-shot path is untouched.

## Decision: cumulative buffer vs incremental deltas

Pick one and document it; downstream depends on it.

- **Yield cumulative buffer-so-far** (recommended): each event is the full text
  produced up to now. Pairs directly with phase 1's whole-buffer parser - the
  structured layer just parses each emission. Slightly more bytes over the
  stream (negligible for our sizes).
- Yield incremental deltas: each event is only the new tokens; the consumer
  accumulates. Matches OpenAI/gemma native shape but pushes accumulation into
  every consumer.

Recommendation: **expose cumulative** from `generateStream` and let each engine
adapter accumulate its native deltas internally. One accumulation site, simplest
consumers. (If we later want raw deltas too, add a second method; do not
overload this one.)

## Plan

- Extend the `InferenceEngine` abstract class with `generateStream`. Define the
  terminal behavior: the stream completes normally on success; on engine failure
  it should surface as a stream error or a final sentinel - decide and document
  (lean: emit normally, then let phase 3 detect failure via the engine's
  existing error channel / a thrown `InferenceException`). Keep `InferenceResult`
  semantics reachable so failures are not lost.
- Update `status` transitions to match `generate` (generating -> ready) so the
  existing `statusStream` UI keeps working during streaming.
- Implement in
  [`fake_inference_engine.dart`](../../lib/services/inference/fake_inference_engine.dart):
  load the existing fixture, then emit the serialized JSON in chunks (e.g. a few
  characters per tick with a small `Future.delayed`) so tests and manual runs
  exercise genuinely partial buffers, including a chunk boundary inside a string
  and inside an array element.
- Add a `default`/throwing or buffered fallback for engines not yet streaming
  (OpenAI, gemma) so the interface change compiles before phase 4: a mixin or
  base implementation that calls `generate` and emits its `rawText` once is an
  acceptable bridge - document it as temporary.
- Tests: assert the fake emits monotonically growing buffers, that the final
  emission equals the full fixture JSON, and that at least one intermediate
  emission is a valid *partial* (round-trips through phase 1 to a partial map).

## Out of scope

- Real OpenAI / gemma streaming (phase 4).
- Parsing the stream into typed deltas (phase 3).
- Provider/controller wiring (phase 5).

## Done when

- `InferenceEngine.generateStream` exists with a documented contract.
- `FakeInferenceEngine` streams a fixture in realistic chunks.
- A temporary buffered fallback keeps OpenAI/gemma compiling.
- Unit tests for the fake stream pass; existing engine tests still pass.
