---
status: done
---

# Phase 03 - Clean up before duplicating

## Overview

The audit found code with no users, dependencies nothing imports, a doc naming the wrong logger, and two couplings in code meant to be generic.
Q9 and Q10 say to fix them here, before phase 04 copies them into a second repo. Added after the audit, so the later phases moved up by one.

## Goals

1. Delete `lib/utils/logger.dart`, `lib/services/debug/debug_monitor.dart`, `lib/config/error_messages.dart`, `lib/widgets/error_boundary.dart`. None is a gallery item worth keeping (`00_start.md` Q9).
2. Drop `logger`, `riverpod_annotation`, `riverpod_generator` and `mockito` from `pubspec.yaml`, and refresh the lock file with `flutter pub get`.
3. `docs/coding-standards.md` names `AppLogger` as the project logger.
4. `OpenAiInferenceEngine` takes its schema and schema name as required parameters and no longer imports the tutor schema; the composition point passes it.
5. `engine_registry.dart` no longer imports a provider: `EngineFactory` moves into the service layer.

## Out of scope

- Anything the audit marked `fala` or `guide`: nothing moves in this phase.
- The `applicationId` (phase 05, Q7).

## Done when

- `grep` finds no reference to the removed files or packages outside `plans/`.
- No file under `lib/services/` imports from `lib/providers/`.
- `scripts/check.sh` passes.

## What the implementation found

- **All four files went, none kept for the gallery.** `ErrorBoundary` looked like a component candidate, but nothing ever assigns its `_error`, so it cannot catch anything; a gallery item showing error handling is better written against `FlutterError.onError` when phase 05 builds the gallery.
- **All four dependencies went**, and `flutter pub get` removed five packages from the lock file.
- **The structure doc listed `lib/utils/` and `lib/widgets/` as layers.** With both folders gone it now says screen-local widgets live under the screen, and that a shared folder is created when a second screen needs it. Its layer table also now says services may not depend on providers, which is the rule the registry broke.
- **The OpenAI engine already took the schema as a parameter**; only its defaults named the tutor. The defaults are gone and the parameters required, so the registry, which wires the app, is the one place that names `tutorResponseJsonSchema`. In the guide it will pass the guide's schema.
- **`EngineFactory` moved into `engine_registry.dart`**, the file that builds engines. The provider already imported the registry, so nothing else changed.
- **Test seen failing:** the new test sends a non-tutor schema and checks the request body. With the engine hard-coding the name `tutor_response` it failed with `Expected: 'test_reply' Actual: 'tutor_response'`; restored, it passes.
- **Checked:** `grep` finds no reference to the removed files or packages outside `plans/` (one comment in `.gitignore` names `riverpod_generator` among generators; left, since it describes the pattern ignored). No file under `lib/services/` imports from `lib/providers/`. `scripts/check.sh` passes, 168 tests.
- **Not fixed, noted:** `dart format --set-exit-if-changed` reports about a dozen files it would reformat, on `main` as well as here. Formatting is not one of the gates, and reformatting those files is its own change.
