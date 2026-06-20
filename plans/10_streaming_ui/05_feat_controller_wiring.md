---
status: planned
---

# Phase 5 - Controller + provider wiring

## Overview

Wire the streaming layer into the running app: `ConversationController` exposes a
live partial stream for the in-flight tutor turn, and Riverpod providers
construct the `StructuredStreamEngine<TutorResponse>` alongside the existing
one-shot engine. The final persistence path stays exactly as today - the stream
is additive and ends by appending the same fully-typed message.

Context: [`00.2_structured_streaming_asis.md`](00.2_structured_streaming_asis.md)
sections 1.1 + 6. Depends on
[`03_feat_structured_stream_engine.md`](03_feat_structured_stream_engine.md);
benefits from but does not require phase 4 (works against the fake).

## Goals

1. A `StructuredStreamEngine<TutorResponse>` available via providers, built from
   the active engine (same engine-kind selection as today).
2. `ConversationController.sendMessage` drives the streaming engine and exposes
   the in-flight `StructuredDelta<TutorResponse>` to the UI.
3. The persisted final tutor `ConversationMessage` is produced from the terminal
   delta's typed `value`, identical to today's result (no schema or storage
   change).
4. Failure handling unchanged in outcome: inference/parse failure still yields
   the existing fallback message text.

## Plan

- Providers
  ([`inference_provider.dart`](../../lib/providers/inference_provider.dart),
  [`conversation_provider.dart`](../../lib/providers/conversation_provider.dart),
  [`engine_registry.dart`](../../lib/services/inference/engine_registry.dart)):
  add a provider that wraps the active `InferenceEngine` in a
  `StructuredStreamEngine<TutorResponse>` using `TutorResponse.fromJson`. Reuse
  the existing engine-kind switching; the streaming engine should follow the
  same active engine the one-shot path uses (watch for the circular-dep pattern
  already fixed in commit 6f2d55d - mirror that structure).
- `ConversationController`
  ([`conversation_controller.dart`](../../lib/services/conversation/conversation_controller.dart)):
  - Add an in-flight stream surface, e.g.
    `Stream<StructuredDelta<TutorResponse>>? get streamingReply` plus a
    `StreamController` that is live only during a send.
  - Refactor `sendMessage` to: append the user message (unchanged) -> build
    prompt (unchanged) -> subscribe to `structuredStreamEngine.generateStream`
    -> forward each delta to the in-flight stream -> on terminal delta, build the
    tutor `ConversationMessage(tutorResponse: value)` and `appendMessage` exactly
    as today, then close the in-flight stream.
  - Keep the three-state mapping: `failure` delta -> the same error/fallback text
    currently produced for `StructuredInferenceFailure` / `StructuredParseFailure`.
  - Decide concurrency: ignore/queue a new send while one is streaming (the UI
    already gates with `_isSending`); document the choice.
- Keep `conversationStream` (the persisted `Conversation`) as the source of
  truth for committed messages; the in-flight delta stream is a separate,
  ephemeral channel that the UI overlays (phase 6).
- Tests: a controller test with the fake streaming engine asserting that
  `sendMessage` (a) emits intermediate deltas on the in-flight stream, (b)
  appends exactly one tutor message whose `tutorResponse` equals the terminal
  typed value, and (c) on a failure delta appends the existing fallback text and
  does not leave the in-flight stream open.

## Out of scope

- Widget rendering of partials (phase 6) - this phase exposes the stream; the
  screen still renders only committed messages until phase 6.
- Any change to persistence format or `Conversation` model.

## Done when

- Providers construct `StructuredStreamEngine<TutorResponse>` following the
  active engine kind.
- `ConversationController` exposes the in-flight delta stream and still persists
  an identical final message.
- Controller unit tests (fake streaming engine) pass; existing controller tests
  still pass.
