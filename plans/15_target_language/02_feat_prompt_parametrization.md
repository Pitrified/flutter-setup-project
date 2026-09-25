---
status: done
---

# Phase 2 - Prompt parametrization

## Overview

Make the prompt take the language as data. This is the phase that changes what the model is told, so
it is the one with an output quality risk, and it is kept separate from the UI for that reason.
Context: [`00_start.md`](00_start.md), depends on [`01_feat_language_model.md`](01_feat_language_model.md).

## Goals

1. `assets/prompts/tutor_response/v3.txt` names no language of its own.
2. The controller passes both language axes.
3. The Portuguese behaviour is unchanged when the language is `pt-BR`.

## Plan

- Copy `v2.txt` to `v3.txt` and replace the seven hardcoded mentions with `{{target_language}}`
  (lines 1, 6, 17, 23 of v2) and `{{explanation_language}}` (lines 7, 12, 18). Keep `v2.txt` in place:
  the manager loads the highest version, and the old file is the record of what the prompt used to be.
- Decide what the variable is substituted with: the endonym, the English name, or both
  ("Portuguese (português)"). Both reads best for a model that has to answer *in* the language and be
  told *about* it in an English instruction, so start there and note it as the thing to revisit if
  output quality moves.
- In [`conversation_controller.dart:148`](../../lib/services/conversation/conversation_controller.dart),
  add `target_language` and `explanation_language` to the `buildPrompt` variables, reading the
  conversation's stored code and mapping it back through `TargetLanguage.fromCode`. Explanation
  language is English at the call site per Q3.
- Guard the substitution: `PromptManager.buildPrompt` silently leaves an unmatched `{{var}}` in
  place, which would ship the literal text to the model. Add a check that the built prompt contains
  no `{{` left, raising a named exception, and a test that trips it.
- Tests: the built prompt for `pt-BR` contains "Portuguese" and no `{{`; the same for a second
  language; a missing variable raises.

## Out of scope

- Any UI (phase 3). During this phase the language is whatever the default is.
- Per-language templates, rejected in Q4.
- Judging output quality in a second language, which needs a device (phase 4).

## Done when

- `scripts/check.sh` green.
- A `pt-BR` conversation produces a prompt equivalent to the v2 text, checked by reading the built
  string in a test, not by eye.
- Switching the stored default to another language changes the built prompt, with no code edit.

## What the implementation found

An existing test, `unknown variables are left as-is`, asserted exactly the behaviour the guard
removes. It was not a mistake when written: nothing in the template was load-bearing then. It is now,
so the test was rewritten to assert the throw, with a comment recording what it used to assert and
why that changed. A silently-unsubstituted `{{target_language}}` makes the model answer in a language
it guessed, which reads as a bad reply rather than as a bug, and that is the case the guard exists for.

The variable substitution needed no ordering care: `explanation_language` and `target_language` never
appear inside each other's values.

Beyond the planned tests, there is one on the **real** shipped asset
(`test/services/prompt_template_v3_test.dart`) built with the **real** variable set the controller
passes, exported as `ConversationController.explanationLanguage` so the test cannot drift from the
call site. A fixture template would have passed while the shipped one was broken.

`v2.txt` stays in place and unused: `_findLatestVersion` counts down from v10, so v3 is what loads.
