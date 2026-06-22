---
status: planned
---

# Phase 1 - Tolerant incremental JSON parser

## Overview

The foundation of S2: a pure-Dart function that turns the *cumulative*
raw-text buffer seen so far into a best-effort `Map<String,dynamic>`, closing
any open strings / objects / arrays so a partially-streamed JSON document still
yields a usable map at every tick. No Flutter, no network - fully unit-testable
in isolation. Everything downstream (phase 3 `StructuredStreamEngine`) consumes
this.

Context: [`00.2_structured_streaming_asis.md`](00.2_structured_streaming_asis.md)
section 4a + 4c. This phase deliberately stays **schema-agnostic** - it knows
nothing about `TutorResponse`.

## Decision to make first: dependency vs vendored

Evaluate **`llm_json_stream`** (pub.dev) against a small vendored scanner.

- `llm_json_stream`: reactive, path-subscription parser built for LLM output.
  Pro: arrive-as-you-go semantics out of the box. Con: a dependency to track;
  its emission model (per-path subscriptions) may not map 1:1 onto our
  "give me the whole partial map each tick" shape.
- Vendored scanner (~120-150 lines): a single-pass tolerant tokenizer that
  balances the stack and emits a `Map`. Pro: zero deps, exact control, trivial
  to test against our fixtures. Con: we own the edge cases (escapes, unicode,
  numbers, mid-token literals).

Record the choice and the why in the Log. Default lean: **vendored** for zero
deps and full control, given the parser is generic and small. Keep the public
API identical either way so the choice does not leak past this phase.

**Decided 2026-06-22: vendored.** Full pro/con assessment of `llm_json_stream`
(API shape, closed-flags gap, maintenance) in
[`01.1_analysis_vendored_vs_dep.md`](01.1_analysis_vendored_vs_dep.md).

## Goals

1. A `PartialJson` (name TBD) component exposing a pure function:
   `PartialJsonResult parse(String cumulativeBuffer)`.
2. `PartialJsonResult` carries: the best-effort `Map<String,dynamic> value`,
   and per-node "closed" information sufficient for phase 6 to know when an
   array has stopped growing and when an element/string is final.
3. Leaves are exposed at their current prefix (a mid-token string is its prefix
   so far); absent keys are simply absent from the map.
4. Generic over depth and shape - no `TutorResponse` knowledge.

## Plan

- Define the public surface: input is the *whole* buffer-so-far (not a delta),
  output is the best-effort map plus closed-flags. Re-parsing the whole buffer
  each tick is simplest and fast enough for our document sizes; note it and move
  on (optimize only if profiling says so).
- Implement (vendored path): a tolerant scanner that walks characters, tracks a
  stack of open containers and the current string/escape state, and on
  end-of-input synthesizes the closing tokens needed to make the prefix valid,
  then `jsonDecode`s the repaired string (or builds the map directly).
- Closed-flags: track which container indices/keys were closed by a real
  `]`/`}`/`"` in the input vs. synthesized at EOF. This is the signal phase 6
  uses for "this row is final" and "no more rows coming."
- Edge cases to cover with tests: empty buffer; `{`; `{"a"`; `{"a":`;
  `{"a":"hel`; `{"a":"hello","b":[`; `{"a":[{"x":1},{"x":` (last element
  partial); escaped quotes `"he\"llo`; numbers mid-token `{"n":12`; unicode
  escapes; markdown-fenced JSON prefix (reuse `JsonExtractor` strategies or note
  that fences only matter at completion).
- Decide interaction with the existing
  [`json_extractor.dart`](../../lib/services/inference/json_extractor.dart):
  the extractor is whole-document (fences, `{..}` substring). For streaming we
  parse the raw buffer directly; keep the extractor for the *final* parse path
  only. Document the boundary.

## Out of scope

- Typed projection onto `TutorResponse` (phase 3 / the delta type).
- Any Stream plumbing - this phase is a synchronous pure function.
- Widget-side handling of partial values (phase 6).

## Done when

- The parser is implemented behind a small, documented public API with no
  Flutter imports.
- Unit tests cover the edge-case list above and pass; each test feeds a
  truncated buffer and asserts the recovered map + closed-flags.
- The dependency-vs-vendored decision is recorded in `tracking.md` Log.
- `dart analyze` / project lints clean for the new files.
