---
status: planned
---

# Phase 4 - Real engines streaming (OpenAI + flutter_gemma)

## Overview

Replace the temporary buffered fallback from phase 2 with genuine streaming in
the two production engines, so `generateStream` emits real partial buffers.
This is the only phase with network / on-device risk; the entire layer above
(phases 1-3) is already proven against the fake, so failures here are isolated
to the adapters.

Context: [`00.2_structured_streaming_asis.md`](00.2_structured_streaming_asis.md)
sections 1.2 + 6. Depends on
[`02_feat_engine_stream_api.md`](02_feat_engine_stream_api.md).

## Goals

1. `OpenAiInferenceEngine.generateStream` streams via the streaming endpoint,
   accumulating into the cumulative-buffer contract from phase 2.
2. `FlutterGemmaEngine.generateStream` yields its running buffer instead of
   discarding the token loop.
3. Structured-output constraint (strict JSON schema) preserved under streaming
   for OpenAI, so partial buffers are always well-formed-JSON prefixes.
4. The same error taxonomy as the one-shot path (auth / rate-limit / timeout /
   connection / generic) surfaces through the stream.

## Plan

### OpenAI ([`openai_inference_engine.dart`](../../lib/services/inference/openai_inference_engine.dart))

- Switch the call to `client.chat.completions.createStream(...)`, keeping
  `responseFormat: ResponseFormat.jsonSchema(...)` (verify `openai_dart`
  supports json_schema under streaming; it does per 00.2 research - confirm at
  the installed version).
- Accumulate `choice.delta.content` into a `StringBuffer` and yield the buffer
  after each chunk (cumulative contract). Use the SDK's `textDeltas()` /
  accumulator helper if it simplifies this.
- Map the existing exceptions (`AuthenticationException`, `RateLimitException`,
  `RequestTimeoutException`, `ConnectionException`, `OpenAIException`) onto the
  phase-2 failure contract; keep the key-read-on-every-call and client-rebuild
  behavior unchanged.
- **Endpoint note:** keep the choice of Chat Completions vs the Responses API
  encapsulated here. If we adopt `/v1/responses` later, adapt its richer delta
  events into the same cumulative buffer - the `generateStream` contract does
  not change. Record any move in the Log.

### flutter_gemma ([`flutter_gemma_engine.dart`](../../lib/services/inference/flutter_gemma_engine.dart))

- In `generateStream`, run the existing
  `chat.generateChatResponseAsync()` loop but **yield** the running buffer on
  each `TextResponse.token` instead of only returning at the end. The token
  stream already exists (line ~68 today); we stop throwing it away.
- Preserve status transitions and exception handling.
- Note: no constrained decoding on-device yet, so partial gemma buffers may not
  be valid-JSON prefixes; phase 1's tolerant parser already handles that.

### Both

- Remove the temporary buffered fallback added in phase 2 (or keep it only as
  the base for engines that genuinely cannot stream, e.g. a future one).
- Tests: unit-test the OpenAI adapter with an injected fake streaming client
  (the `OPENAIClientBuilder` seam already exists for this) asserting cumulative
  emission and error mapping. Gemma is harder to unit-test without a device;
  cover the buffer-accumulation logic by extracting it into a testable helper if
  practical, otherwise rely on a manual/integration check and note it.

## Out of scope

- Controller / provider wiring (phase 5).
- UI (phase 6).
- Switching to the Responses API (optional future; only the seam is set here).

## Done when

- Both real engines implement `generateStream` with the cumulative contract and
  correct status + error handling.
- OpenAI streaming verified against the strict JSON schema (partial buffers are
  JSON prefixes).
- OpenAI adapter unit tests (fake streaming client) pass; gemma accumulation
  logic covered by a unit-testable helper or an explicitly noted manual check.
- The temporary phase-2 fallback is removed or demoted to a documented base case.
