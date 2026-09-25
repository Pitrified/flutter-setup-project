---
status: done
priority: 0
description: |
  Token-by-token rendering of the structured tutor reply: a tolerant partial-JSON parser, a streaming
  engine API, real engines streaming over SSE, controller wiring and widgets that render a
  half-arrived object.
---

# Structured streaming - where this came from

This folder was worked before `00_start.md` was the convention, so its reasoning lives in two research
documents rather than in one origin note. They are the bootstrap, and this file points at them:

- [`00.1_initial_research.md`](00.1_initial_research.md) - whether a Flutter app can render a
  structured object as it arrives, and where the difficulty actually is: not the widget tree, but
  parsing SSE chunks and reducing deltas into Dart types.
- [`00.2_structured_streaming_asis.md`](00.2_structured_streaming_asis.md) - the as-is at the time and
  the injection points, which is what the six phases were cut from.
- [`01.1_analysis_vendored_vs_dep.md`](01.1_analysis_vendored_vs_dep.md) - the one build-or-depend
  decision, taken during phase 1.

The phase table and the log are in [`tracking.md`](tracking.md).

Written during the normalisation pass in
[`../21_plans_query_skill/02_normalisation.md`](../21_plans_query_skill/02_normalisation.md), because
neither research document is an origin note and promoting one into that role would misrepresent it.
