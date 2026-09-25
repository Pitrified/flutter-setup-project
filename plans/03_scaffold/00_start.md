# Phase 03 - Scaffold

Create the Flutter project, configure dependencies, and validate it builds
and runs on an Android emulator.

## Goal

A minimal Flutter app that launches, navigates between two screens,
and has codegen (freezed/json_serializable) working. No business logic yet.

## Plans (all written, not yet executed)

| File | Produces |
|------|----------|
| [00_create_project.md](00_create_project.md) | Flutter project + pubspec.yaml |
| [01_folder_structure.md](01_folder_structure.md) | Full folder tree + analysis_options.yaml |
| [02_generated_models.md](02_generated_models.md) | Freezed data models + build_runner validation |
| [03_routing_and_providers.md](03_routing_and_providers.md) | GoRouter + Riverpod bootstrap |
| [04_git_workflow.md](04_git_workflow.md) | .gitignore + docs/git-workflow.md |

## Prerequisites

- Phase 02 complete (all docs produced)
- Flutter SDK installed and `flutter doctor` passing
- Android emulator running API 36

## Execution order

Sequential (00 through 04). Each builds on the previous.
