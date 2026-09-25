---
status: draft
priority: 0
---

# A navigation map that cannot go stale

Status: draft spin-off, raised 2026-09-25. No phases derived.

## Where this came from

The ask: "a neat state graph of the navigation screens, or at least a way to clarify which buttons
lead where. What are the industry standards for this, merged with the AI-driven development
approach?" Framed as quality of life for unsupervised agentic development, in the vein of the
practices being borrowed from klide.

## What the app actually has (2026-09-25)

Four routes, declared in [`../../lib/app.dart`](../../lib/app.dart):

| path | screen |
| --- | --- |
| `/` | welcome |
| `/conversation` | conversation |
| `/model-download` | model download |
| `/settings` | settings |

A flat list, which is the easy half. The hard half is that the edges are not in the route table:

- **Guards.** `GoRouter.redirect` rewrites destinations from `AppController` state: `AppNeedsModel`
  forces `/model-download`, `/conversation` bounces to `/` unless `AppReady`, `/model-download`
  bounces to `/` once ready, and `/settings` is always reachable. Half the navigation behaviour lives
  in that function, and a diagram of the route list alone would not show any of it.
- **Buttons.** The rest of the edges are `context.go(...)` calls and a drawer, scattered across the
  screens.
- **Modal sheets and dialogs** (CEFR, topic, language picker, the language-switch confirmation) are
  not routes at all, so they are invisible to any route-derived map, while being most of what a person
  actually taps.

Note that `/model-download` and its state are on the way out if
[`../16_cloud_first_engine/00_start.md`](../16_cloud_first_engine/00_start.md) lands, which is a
reason to do that first and map afterwards.

## Industry practice, as far as it goes

To be checked against current sources when this is picked up; written here from what is known now,
and each line should be verified rather than trusted.

- **The route table is the source of truth.** With `go_router`, `go_router_builder` gives typed routes
  so navigation is code rather than strings, which makes call sites greppable. That is the closest
  thing to a standard.
- **Mermaid in markdown** (`flowchart` or `stateDiagram-v2`) is the common lightweight way to draw it,
  because GitHub renders it and it diffs as text. Design tools (Figma flows, FlowMapp, whimsical) are
  the product-side equivalent and are not worth it for a four-screen app.
- **Nobody solves staleness by discipline.** A hand-drawn diagram is wrong within a few commits. The
  two real options are generating the map from the code, or gating the hand-written one against the
  code.

## The angle that makes it worth doing here

For an agent, a picture is worth much less than a machine-readable map. The useful artifact is a small
structured file (routes, guards, and which screen reaches which) that an agent reads before touching
navigation, with the human-facing Mermaid diagram generated from the same file, and a gate that fails
when the file and `lib/` disagree. That is the klide "encode lessons in structure" rule applied to
navigation: not prose saying "remember the redirect", but a check that notices.

Candidate mechanisms, cheapest first:

1. A gate that extracts every `AppRoutes.*` constant and every `GoRoute(path:)` and asserts the map
   file lists exactly those paths. Catches an added or renamed route immediately.
2. The same for edges: grep `context.go(` / `context.push(` call sites per file, and assert each is in
   the map. Noisier, and the one most likely to annoy.
3. Dumping `router.configuration.routes` from a debug build or a test, rather than parsing source.
   Needs checking whether that API is public and stable in the pinned go_router.

## Open questions

- Q1: what is the artifact: a generated Mermaid diagram, a hand-written map with a gate, or a
  machine-readable YAML with both generated from it?
  Recommended: the third, because the agent reads the YAML and the person reads the diagram, and one
  source means they cannot disagree.
  NEW_ANS:
- Q2: do modal sheets and dialogs belong in the map, given they are not routes?
  Recommended: yes, as a separate section, since they are most of the interaction; but they cannot be
  gated against the route table, so they stay hand-written and honest about that.
  NEW_ANS:
- Q3: does this wait for `16_cloud_first_engine`, which deletes a route and a guard?
  Recommended: yes. Mapping a screen that is about to be removed is work done twice.
  NEW_ANS:
