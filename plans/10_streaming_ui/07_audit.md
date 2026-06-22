---
status: done
---

# Phase 7 - Code audit of the streaming UI work

Review of the June-22 commits (`a2016c6` .. `198736a`) implementing S2 + G1
streaming. Each item below has a **Decision** line for you to fill in
(`fix` / `wontfix` / `defer`, plus any note). Nothing here is correctness
-critical; the items are minor.

## Summary of findings

Solid, coherent work. The design holds together: one tolerant parser, one
generic transport (`StructuredDelta<T>`), no per-schema partial mirror type, and
the streaming path stays parallel to the one-shot path rather than replacing it.
The `Stream.timeout`-under-suspended-`async*` bug is correctly solved with a
manual timer + fire-and-forget cancel, with comments explaining *why* at the
non-obvious spots. Test coverage is real (parser edge cases, stall timeout,
handoff gating). No correctness bugs found.

## Worth fixing

### 1. Dead accessors in `streaming_reply_view.dart`

[`streaming_reply_view.dart`](../../lib/screens/conversation/widgets/streaming_reply_view.dart)
defines `correctionContent` and `correctionsClosed`; neither is used anywhere in
`lib/` or `test/`. The card renders `corrected` per-row, not via
`correctionContent`. Either delete them or note they are reserved.

**Decision:** delete

### 2. `structuredInferenceEngineProvider` is orphaned

[`inference_provider.dart:61`](../../lib/providers/inference_provider.dart#L61)
is defined and only referenced by its own doc comment; the controller switched
to `structuredStreamEngineProvider`. If the one-shot path is retired, remove it;
if it is kept as a persisted-final-message fallback, it is not wired to anything,
so a comment should say so.

**Decision:** mark as valid but orphaned, but keep them

### 3. Two sources of truth for "sending"

The screen tracks its own `_isSending`
([`conversation_screen.dart:37`](../../lib/screens/conversation/conversation_screen.dart#L37))
while the controller exposes `isSending`
([`conversation_controller.dart:55`](../../lib/services/conversation/conversation_controller.dart#L55)),
which is only read by a test. They cannot drift dangerously today (the overlay
gate uses the widget copy), but the controller getter is test-only API. Either
drive the overlay from `controller.isSending` or drop the getter.

**Decision:** pick the best convention to keep it clean

### 4. Duplicated exception -> message mapping in the OpenAI engine

[`openai_inference_engine.dart`](../../lib/services/inference/openai_inference_engine.dart)
maps the same five exceptions to identical strings in both `generate` and
`generateStream`. A shared `String _messageFor(Object e)` would keep them from
drifting.

**Decision:** do it, clean and tidy

## Notes (judgment calls, not defects)

### 5. Engine status can stall on `generating` after a timeout cancel

When `StructuredStreamEngine.onCancel` fires-and-forgets `sub.cancel()`
([`structured_stream_engine.dart:213`](../../lib/services/inference/structured_stream_engine.dart#L213)),
the engine's `async*` is abandoned mid-`await`, so its
`finally { _setStatus(ready) }` only runs when the underlying HTTP/gemma future
resolves. For a real network stall the status indicator could read `generating`
for a while after the UI already showed a timeout failure. Acceptable (the
stream contract is honored; only the cosmetic status lags). Worth a one-line
comment so nobody "fixes" it by awaiting the cancel and reintroducing the hang.

**Decision:** add a one-line comment explaining the cosmetic lag

### 6. Post-close timer re-arm edge case

In the event handler, `resetTimer()` runs before the `isClosed` checks
([`structured_stream_engine.dart:158`](../../lib/services/inference/structured_stream_engine.dart#L158)).
If the upstream delivers a buffered event after a timeout already closed the
controller, a fresh `Timer` is armed; it later fires `emitFailure`, which no-ops
on `isClosed`. Harmless, but it is a dangling timer for up to `timeout`. Moving
`if (controller.isClosed) return;` to the top of the handler would close it.

**Decision:** move the `isClosed` check to the top of the handler to prevent dangling timers

### 7. Coalescing cost

`_signature` does a full `jsonEncode` of value + closure every tick
([`structured_stream_engine.dart:230`](../../lib/services/inference/structured_stream_engine.dart#L230)),
on top of the full re-parse - O(n) twice per token. Fine at tutor-reply sizes
and explicitly called out as "optimize only if profiling says so." The one place
to watch if buffers ever grow.

**Decision:** defer optimization until profiling shows a problem

## Non-issues verified

- **Handoff duplicate/flicker**: clean. `showStreamingOverlay` gates on
  `messages.last.role`, so the same rebuild that commits the tutor message
  removes the overlay - no frame shows both.
- **Parser truncation**: dangling escapes, incomplete `\u`, mid-token numbers
  (`12.`, `1e`), unterminated strings, key-without-colon all handled tolerantly,
  and the key is not committed prematurely.
- **Card-above-bubble**: consistent in both the live entry and committed list,
  with a widget test asserting the y-order.
- **Formatting**: `dart format` would change 26 of 61 files repo-wide and there
  is no `page_width` config, so the repo gates on `analyze`, not `format`. The
  long constructor lines are consistent with that; not a defect against current
  conventions.
