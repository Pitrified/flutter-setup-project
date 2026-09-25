---
status: planned
---

# Phase 4 - The repo stops citing the diary

## Overview

`plans/` records how the project got here; `docs/` records what it is. Today fourteen comments and doc
lines cite a plan folder or a `Qn`/`Dn` id as the authority for something, and the README's phase table
adds twelve more links. Each citation is rehomed into the docs file whose topic it is, and the README is
rewritten to point at `docs/` as the current state and `plans/` as the diary. One phase, because it is
one measurement going to zero, and its last commit arms the check from
[`03_checker_and_gate.md`](03_checker_and_gate.md).
Context: [`00_start.md`](00_start.md), "Plans are a diary, not documentation".

## Goals

1. `python3 scripts/plans.py check --no-citations` reports nothing.
2. Every decision that was being cited is written in a docs file, so the reader who followed the old
   reference still finds the answer, in fewer hops.
3. The check is in `scripts/check.sh`, so the fifteenth citation cannot land.

## Plan

Per citation: read what it was pointing at, write the decision in the topical doc (Q15), and change the
comment to point there or to say the thing outright.

- `lib/models/target_language.dart:12`, `lib/services/conversation/conversation_controller.dart:41` -
  the language setting's defaults, into `docs/functional-specs.md` or `docs/prompt-engineering.md`.
- `lib/services/conversation/conversation_controller.dart:240`,
  `test/services/conversation_controller_test.dart:163`,
  `integration_test/app_test.dart:160` - an unparseable reply reads as a failed turn, into the docs page
  that covers structured output.
- `lib/services/inference/openai_inference_engine.dart:24`, `tool/mock_openai.py:15`,
  `scripts/e2e.sh:9`, `integration_test/app_test.dart:94` - the base-URL override, the mock's deliberate
  limits, and why the key goes through the real Settings field: `docs/getting-started.md` already has the
  emulator section, so they belong there.
- `docs/prompt-engineering.md:161` - a `TLn` id from folder 15; state the rule instead of citing it.
- `docs/build-and-release.md:28`, `:59`, `:138` and `android/app/build.gradle.kts:45` - the ABI and
  MediaPipe exclusions. The doc already explains them, so these become internal references.
- `README.md` - the phase table goes; it points at `docs/` for what the project is and at `plans/` for
  the diary (Q16).
- Last commit: add `--no-citations` to `scripts/check.sh`.

## Out of scope

- The pointers in `.github/copilot-instructions.md`, `docs/README.md` and
  `docs/ai-development-playbook.md` that name the plans tree or its shape. Those are the convention, not
  a citation, and the rule permits them.
- Rewriting the docs beyond the decisions being moved in. A decision with no topical home means a doc is
  missing, which is ordinary docs maintenance and gets raised rather than improvised here.

## Done when

- The measurement is zero, and `scripts/check.sh` includes the rule and is green.
- Each rehomed decision is findable by reading `docs/` alone, checked by opening the doc and not the
  plan.
- `scripts/gates/links.py` green, and nothing in the README links into `plans/` except `plans/` itself.
