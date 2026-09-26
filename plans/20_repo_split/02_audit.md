---
status: planned
---

# Phase 02 - Audit

## Overview

Every tracked path gets a destination, so phases 03 and 04 are a list to execute rather than decisions made while deleting.
Read-only: nothing moves in this phase.

## Goals

1. A table in `02.1_audit_table.md`, one row per file or tight group of files, covering all of `git ls-files`.
2. Each row has a destination and a one-line reason:
   - `fala`: moves to fala-language-tutor only.
   - `guide`: stays here only.
   - `both`: duplicated, as the LLM testing machinery is.
   - `link`: stays in fala-language-tutor, and the guide links to it rather than copying.
   - `drop`: nobody keeps it, such as the on-device engine if Q5 is a.
3. The same for `pubspec.yaml` dependencies, for each repo.
4. `plans/`: each folder's destination, which answers Q3.
5. A list of what the guide says that is not written yet: headless and human setup, the pattern index, the distribution approaches.

## Plan

- Walk `lib/`, `test/`, `integration_test/`, `tool/`, `scripts/`, `android/`, `docs/` (including `library/` and `guides/`), `plans/`, `assets/`, `.github/`, the root files.
- For `lib/`, follow imports rather than folder names: `InferenceEngine`, the structured-output parser and the streaming layer are generic; the conversation controller is not (`00_start.md`, "The hard parts").
- Record anything the audit shows to be wrong about the brainstorm as a new question rather than silently adjusting the table.

## Out of scope

- Moving or deleting anything.
- Writing the plan for fala-language-tutor; phase 03 does that from this table.

## Done when

- Every path in `git ls-files` falls under a row, checked by a script run once and logged, not by reading.
- Q3, Q5 and Q6 have answers, or the audit has said what would answer them.
