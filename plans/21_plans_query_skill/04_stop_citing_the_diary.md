---
status: done
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

1. `python3 scripts/plans.py check --citations` reports nothing.
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
- Last commit: add `--citations` to `scripts/check.sh`.

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

## What the implementation found

- **33 references in 14 files, not 28 in 13.** The renames in phase 2 turned README rows into
  `plans/NN_*/00_start.md` links, and three were mine from the same day, in `scripts/plans.py`,
  `scripts/check.sh` and `docs/git-workflow.md`. Writing a rule does not exempt the author from it.
- **The README was the real finding.** Sixteen of the 33 were its phase table, and rewriting it showed
  why: it still said "The project is in the planning phase. No code exists yet", described `docs/` as
  "empty until Phase 02 executes", listed the tech stack as "planned" and the Flutter SDK as "not yet
  installed", and stopped at phase 07 of 21. A front page that indexes the diary rots with the diary.
  It now says what the app does, points at `docs/` for the as-is and at `plans/` for the diary, and
  shows the `list` command instead of a table to maintain.
- **Four decisions had no doc and now do**: the target language rules (`docs/functional-specs.md`,
  a new "Target language" subsection), what a parse failure shows the learner
  (`docs/library/structured-output-system.md`), how the app is pointed at the mock and what the mock
  does not prove (`docs/getting-started.md`, two new subsections). That is Q15 working as intended: the
  missing doc was the reason the citation existed.
- **Two citations were only ever a shorthand.** `docs/prompt-engineering.md` cited a `TLn` id to say
  cloud is the tuning target, and `docs/build-and-release.md` cited folder 12 three times for exclusions
  it already explains. Both became the statement itself, which is shorter than the reference was.
- All five gates green with `--citations` armed.
