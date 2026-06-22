# Structured streaming (S2 + G1) - implementation tracking

Implements the **S2 (streaming structured deltas) + G1 (generic map-transport
delta)** path for rendering the rich tutor widget in real time: a partial,
typed-at-completion stream where nested objects (each correction) fill in *as
they arrive*. Analysis, options, and the rejected alternatives are in
[`00.2_structured_streaming_asis.md`](00.2_structured_streaming_asis.md)
(generic primer in [`00.1_initial_research.md`](00.1_initial_research.md)).

## Key decisions (span phases)

- **S2, not S1 or S3.** Stream a partial *typed* object, not just tokens (S1),
  and do not adopt AG-UI as a wire format (S3) - its payoff is the Python/JS
  ecosystem we cannot use in Flutter. See 00.2 sections 3 + 5.
- **G1 transport: one generic `StructuredDelta<T>`** carrying a best-effort
  `Map<String,dynamic> partial` + a typed `T? value` (non-null only at
  completion) + `isComplete` + `failure`. No hand-written `PartialT` per schema;
  no `fromJson` changes. G2 (codegen) stays in pocket. See 00.2 section 4b.
- **Nested elements stream as they arrive (4c flipped).** Expose whatever the
  tolerant parser holds at every depth, leaves nullable/partial; per-widget
  completeness gate available where a half value would mislead. Cost is mostly
  widget-side polish; it nudges us toward G1 (free recursion). See 00.2 4c.
- **Additive, not a rewrite.** The existing one-shot
  `StructuredInferenceEngine<T>` + persistence path stay for the *final*
  message; the streaming layer is a parallel stream for the in-flight turn only.
- **Engine hides the endpoint.** OpenAI `createStream` today; free to move to
  the Responses API later without changing the `generateStream` contract.

## Phases

| #  | Phase                                   | Plan                                                            | Status  |
| -- | --------------------------------------- | -------------------------------------------------------------- | ------- |
| 1  | Tolerant incremental JSON parser        | [`01_feat_partial_json_parser.md`](01_feat_partial_json_parser.md)       | done    |
| 2  | Engine streaming API + Fake impl        | [`02_feat_engine_stream_api.md`](02_feat_engine_stream_api.md)           | planned |
| 3  | StructuredStreamEngine + StructuredDelta| [`03_feat_structured_stream_engine.md`](03_feat_structured_stream_engine.md) | planned |
| 4  | Real engines streaming (OpenAI + gemma) | [`04_feat_real_engine_streaming.md`](04_feat_real_engine_streaming.md)   | planned |
| 5  | Controller + provider wiring            | [`05_feat_controller_wiring.md`](05_feat_controller_wiring.md)           | planned |
| 6  | Live partial-tolerant widgets           | [`06_feat_live_widgets.md`](06_feat_live_widgets.md)                     | planned |

Status values: draft / planned / in progress / done / superseded / discarded.

Sequencing rationale: phases 1-3 are pure Dart, zero Flutter, fully
unit-testable with no network or device - the cheapest, lowest-risk foundation.
Phase 4 introduces the only network/device risk. Phases 5-6 wire it into the
running app and are where the UX polish lives.

## Log

Append-only. Newest at the bottom.

- 2026-06-20 : bootstrapped the plan folder from 00.2; drafted phases 1-6, all `planned`.
- 2026-06-22 : phase 1 dependency-vs-vendored decision = **vendored**. `llm_json_stream`
  solves the tokenizer edge cases but its API is inverted against our needs: it is a
  stateful `Stream<String>`-fed, path-subscription parser with no whole-map snapshot and
  no per-node closed event (only node-start callbacks + a root `.future`). Our phase-1
  surface is a sync pure `parse(cumulativeBuffer) -> map + per-node closed-flags`; the
  closed-flags would be hand-written on top of the dep regardless. Full analysis in
  [`01.1_analysis_vendored_vs_dep.md`](01.1_analysis_vendored_vs_dep.md).
- 2026-06-22 : phase 1 **done**. Vendored
  [`partial_json_parser.dart`](../../lib/services/inference/partial_json_parser.dart):
  sync `PartialJsonParser.parse(buffer) -> PartialJsonResult { value, closure }`, where
  `JsonClosure` carries per-node `closed` flags + `fields`/`elements` children. Single-pass
  recursive-descent scanner, builds the map directly (no repair-then-decode) so closed vs
  open falls out of seeing a real terminator. No Flutter imports. 20 unit tests cover the
  plan's edge-case list (empty/`{`/`{"a"`/`{"a":`, mid-token string, escaped quote, unicode
  escape complete + truncated, numbers mid-token, partial last array element, fence prefix,
  full-doc round-trip vs `jsonDecode`); `flutter analyze` clean.
