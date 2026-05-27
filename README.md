# flutter-setup-project

A mobile language-tutoring app that runs a small LLM entirely on-device (Android).
The user types messages in their target language and receives structured corrections,
explanations, and conversational replies - all without network access after initial model download.

The repo is called `flutter-setup-project` because the initial focus is on setting up a clean, well-structured Flutter codebase and development environment, along with comprehensive documentation and AI development guidelines. The actual tutoring features and LLM integration will be built on top of this foundation in subsequent phases, and possibly in a different repo.

## Current state

The project is in the planning phase. No code exists yet.
All work so far lives in the `plans/` folder as structured blueprints.

## Navigation

| Location | Purpose |
|----------|---------|
| [plans/01_plan_polishing/00_start.md](plans/01_plan_polishing/00_start.md) | Master plan: gap analysis, phase breakdown, execution order |
| [plans/00_drafts/](plans/00_drafts/) | Raw research notes (architecture draft, LLM SDK options) |
| [docs/](docs/) | Polished documentation (empty until Phase 02 executes) |
| [.github/copilot-instructions.md](.github/copilot-instructions.md) | AI assistant configuration (skeleton, updated each phase) |

## Phases

| # | Phase | Goal |
|---|-------|------|
| 00 | [Drafts](plans/00_drafts/README.md) | Raw research material (architecture, LLM SDK options) |
| 01 | [Plan Polishing](plans/01_plan_polishing/README.md) | Meta-plan, gap analysis, execution order |
| 02 | [Foundation](plans/02_foundation/README.md) | All documentation before any code (spec, standards, AI playbook) |
| 03 | [Scaffold](plans/03_scaffold/README.md) | Create Flutter project, configure deps, validate it runs |
| 04 | [Core Systems](plans/04_core_systems/README.md) | Inference interface, fake provider, structured output, persistence |
| 05 | [Conversation Loop](plans/05_conversation_loop/README.md) | End-to-end tutoring interaction wired together |
| 06 | [Stabilization](plans/06_stabilization/README.md) | Error handling, tests, performance validation |
| 07 | [Release](plans/07_release/README.md) | Signed APK, Google Play private alpha |

See [plans/01_plan_polishing/00_start.md](plans/01_plan_polishing/00_start.md) for the full breakdown.

## Tech stack (planned)

- Flutter (Dart), Android only
- Riverpod (state management)
- GoRouter (navigation)
- Hive (local persistence)
- flutter_gemma (on-device LLM inference, swappable)
- freezed + json_serializable (typed models, codegen)

## Development environment

Linux. Flutter SDK not yet installed.
Setup instructions will be written in Phase 02 ([plans/02_foundation/00_dev_environment.md](plans/02_foundation/00_dev_environment.md)).
