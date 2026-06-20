---
status: planned
---

# Phase 6 - Live partial-tolerant widgets

## Overview

The payoff: render the rich tutor widget in real time. The in-flight
`StructuredDelta<TutorResponse>` (phase 5) drives a live `MessageBubble` +
`CorrectionCard` whose fields fill in *as they arrive* (4c flipped) - the
conversational reply types out, the corrected sentence paints, and each
correction row appears immediately with its own leaves streaming in. On
completion the live overlay is replaced by the committed message from
`conversationStream`. This phase is where the "tolerate more complexity for
nested streaming" budget is spent.

Context: [`00.2_structured_streaming_asis.md`](00.2_structured_streaming_asis.md)
sections 4c + 4 (anti-jank notes). Depends on
[`05_feat_controller_wiring.md`](05_feat_controller_wiring.md).

## Goals

1. While a turn streams, render a live tutor entry bound to the in-flight delta
   instead of (or above) the `TypingIndicator`.
2. `MessageBubble` and `CorrectionCard` tolerate `null` / partial leaves and
   mid-token strings without breaking layout.
3. Correction rows appear as their array elements arrive and fill in live; a row
   marks itself final using phase-1 closed-flags.
4. Granular rebuilds: only the changed line repaints, not the whole `ListView`.
5. On completion, seamlessly hand off to the committed message (no fl/flicker,
   no duplicate).

## Plan

- Typed access over G1's map: add a tiny accessor extension/helper that reads the
  fields the widgets watch from `StructuredDelta.partial`
  (`correction.content`, `correction.translation`, `correction.errors[i].*`,
  `conversation.content`, `conversation.translation`) returning nullable values.
  Keep it thin - this is the only place that knows the `TutorResponse` field
  paths; it does not reintroduce a hand-written `PartialT`.
- Live entry in
  [`conversation_screen.dart`](../../lib/screens/conversation/conversation_screen.dart):
  replace the `_isSending` -> `TypingIndicator` slot with a widget that listens
  to the controller's in-flight delta stream (`StreamBuilder` /
  `ValueListenableBuilder`). When no turn is in flight, behave as today.
- `MessageBubble`
  ([`message_bubble.dart`](../../lib/screens/conversation/widgets/message_bubble.dart)):
  accept a partial source (a nullable `conversation.content` / `translation`)
  and render the prefix-so-far; keep the existing tap-to-reveal translation,
  disabled until `translation` is present. Use `AnimatedSize` (already present)
  for graceful growth.
- `CorrectionCard`
  ([`correction_card.dart`](../../lib/screens/conversation/widgets/correction_card.dart)):
  - Drive from a list of partial errors (length = elements-so-far). Give each row
    a stable `ValueKey(index)`.
  - Per row, render `original` as soon as present; show a skeleton/placeholder
    for not-yet-arrived `corrected` / `explanation`; only draw the strike->replace
    `RichText` once both `original` and `corrected` exist (per-widget completeness
    gate - the case 00.2 calls out where a half value would mislead).
  - Mark a row final using phase-1 closed-flags; stop expecting new rows when the
    `errors` array is closed.
- Anti-jank: bind each sub-widget to a `select`ed slice / its own listenable so a
  token update to `conversation.content` does not rebuild the correction rows and
  vice versa. Rely on the phase-3 emission coalescing; add a short debounce here
  only if profiling shows flicker.
- Handoff: when the terminal delta arrives (or `conversationStream` emits the
  committed message), drop the live overlay and show the persisted entry. Ensure
  exactly one visible tutor bubble across the transition (guard against the live
  overlay and the committed message both showing for a frame).
- Manual/widget tests: a widget test pumping a sequence of partial deltas
  asserting (a) the bubble text grows, (b) a correction row appears partial then
  completes, (c) no exception on `null` leaves, (d) after completion only the
  committed message remains.

## Out of scope

- New correction visuals beyond the current strike/replace + explanation.
- Persisting partial states (only the final message is stored, unchanged).
- Streaming the `conversation.translation` urgently - it may arrive last and only
  matters on tap.

## Done when

- A streaming turn renders a live tutor bubble + correction rows that fill in as
  the data arrives, with no broken/half-rendered strike-replace and no layout
  jumps.
- Rebuilds are granular (verified by widget-rebuild instrumentation or review).
- Handoff to the committed message is seamless (single bubble, no flicker).
- Widget tests above pass; `flutter analyze` / project lints clean.
- End-to-end manual check against the fake engine, and (if phase 4 done) against
  OpenAI streaming.
