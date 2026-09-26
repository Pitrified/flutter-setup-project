---
status: done
---

# Phase 02 - Audit

## Overview

Every tracked path gets a destination, so phases 04 and 05 are a list to execute rather than decisions made while deleting.
Read-only: nothing moves in this phase.

## Goals

1. A table in `02.1_audit_table.md`, one row per file or tight group of files, covering all of `git ls-files`.
2. Each row has a destination and a one-line reason:
   - `fala`: moves to fala-language-tutor only.
   - `guide`: stays here only.
   - `both`: duplicated, as the LLM testing machinery is.
   - `link`: stays in fala-language-tutor, and the guide links to it rather than copying.
   - `drop`: nobody keeps it.
3. The same for `pubspec.yaml` dependencies, for each repo.
4. `plans/`: each folder's destination, which answers Q3.
5. A list of what the guide says that is not written yet: headless and human setup, the pattern index, the distribution approaches.
6. The gallery's candidate items (Q6): router and navigation, basic pages, components, storage including secure storage, the on-device engine (Q5), and whatever else the walk turns up. Each marked as present here today or to be written.

## Plan

- Walk `lib/`, `test/`, `integration_test/`, `tool/`, `scripts/`, `android/`, `docs/` (including `library/` and `guides/`), `plans/`, `assets/`, `.github/`, the root files.
- For `lib/`, follow imports rather than folder names: `InferenceEngine`, the structured-output parser and the streaming layer are generic; the conversation controller is not (`00_start.md`, "The hard parts").
- Record anything the audit shows to be wrong about the brainstorm as a new question rather than silently adjusting the table.

## Out of scope

- Moving or deleting anything.
- Writing the plan for fala-language-tutor; phase 04 does that from this table.

## Done when

- Every path in `git ls-files` falls under a row, checked by a script run once and logged, not by reading.
- Every plan folder has a destination (Q3), and the gallery list (goal 6) exists.

## What the implementation found

The table is [`02.1_audit_table.md`](02.1_audit_table.md): 148 path patterns over 303 tracked files, plus dependencies, plan folders, gallery candidates and the guide's missing pages.

- **Coverage checked by script**, not by reading: every `git ls-files` path matches a pattern and every pattern matches a file. Seen failing once on purpose (`tool/*` misspelt as `tools/*`: two files unmatched, one empty pattern) before it passed. The script is in the log entry.
- **Dead code.** `lib/utils/logger.dart`, `lib/services/debug/debug_monitor.dart`, `lib/config/error_messages.dart` and `lib/widgets/error_boundary.dart` have no users. `DebugMonitor` also calls `debugPrint`, against the hard rules.
- **Unused dependencies.** `logger`, `riverpod_annotation`, `riverpod_generator` and `mockito`.
- **A doc bug.** `docs/coding-standards.md` names `lib/utils/logger.dart` as the project logger; the code uses `AppLogger` in `lib/services/logging/`.
- **Two couplings in code meant to be generic.** `OpenAiInferenceEngine` imports the tutor's response schema, and `engine_registry.dart`, a service, imports a provider.
- **Shared `applicationId`.** Both apps would be `com.fala.app`, and Android treats two apps with one id as the same app.
- **Plans rule proposed** for Q3: the diary stays with its history, open product work moves. That moves 07, 09, 13, 14 and 19, and splits 23.
- **Nothing in the brainstorm turned out wrong.** The questions below are what the table could not settle alone.
