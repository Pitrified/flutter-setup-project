---
status: in progress
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
