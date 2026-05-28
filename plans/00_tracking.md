# Project Tracking

Single source of truth for progress across all phases.

## Phase overview

| Phase | Status | Progress |
|-------|--------|----------|
| [00 Drafts](00_drafts/README.md) | complete | Reference material, not maintained |
| [01 Plan Polishing](01_plan_polishing/README.md) | complete | Master plan finalized |
| [02 Foundation](02_foundation/README.md) | complete | 8/8 plans drafted, docs produced |
| [03 Scaffold](03_scaffold/README.md) | complete | 5/5 plans executed |
| [04 Core Systems](04_core_systems/README.md) | complete | 8/8 plans executed |
| [05 Controllers](05_controllers/README.md) | complete | 6/6 plans executed |
| [06 Stabilization](06_stabilization/README.md) | complete | 4/4 plans executed |
| [07 Release](07_release/README.md) | in-progress | 3/3 plans written, 2/3 executed |

---

## Phase 02 - Foundation

| # | Plan file | Status | Produces |
|---|-----------|--------|----------|
| 00 | 00_dev_environment.md | complete | docs/getting-started.md |
| 01 | 01_functional_spec.md | complete | docs/functional-specs.md |
| 02 | 02_project_structure.md | complete | docs/project-structure.md |
| 03 | 03_coding_standards.md | complete | docs/coding-standards.md |
| 04 | 04_ai_development_playbook.md | complete | docs/ai-development-playbook.md |
| 05 | 05_system_specs_template.md | complete | Template for docs/library/*.md |
| 06 | 06_copilot_instructions.md | complete | .github/copilot-instructions.md |
| 07 | 07_docs_readme.md | complete | docs/README.md |

---

## Phase 03 - Scaffold

| # | Plan file | Status | Produces |
|---|-----------|--------|----------|
| 00 | 00_create_project.md | complete | Flutter project + pubspec.yaml |
| 01 | 01_folder_structure.md | complete | Folder tree + analysis_options.yaml |
| 02 | 02_generated_models.md | complete | Freezed models + build_runner |
| 03 | 03_routing_and_providers.md | complete | GoRouter + Riverpod bootstrap |
| 04 | 04_git_workflow.md | complete | .gitignore + docs/git-workflow.md |

---

## Phase 04 - Core Systems

| # | Plan file | Status | Produces |
|---|-----------|--------|----------|
| 00 | 00_inference_interface.md | complete | InferenceEngine abstract interface |
| 01 | 01_fake_inference_engine.md | complete | FakeInferenceEngine |
| 02 | 02_flutter_gemma_engine.md | complete | FlutterGemmaEngine |
| 03 | 03_structured_output.md | complete | Schema validation pipeline |
| 04 | 04_conversation_repository.md | complete | Hive persistence layer |
| 05 | 05_model_manager.md | complete | Model download/cache logic |
| 06 | 06_prompt_manager.md | complete | Versioned prompt loading |
| 07 | 07_decouple_structured_output.md | complete | Generic parser + StructuredInferenceEngine<T> |

---

## Phase 05 - Controllers and Screens

| # | Plan file | Status | Produces |
|---|-----------|--------|----------|
| 00 | 00_conversation_controller.md | complete | ConversationController + provider |
| 01 | 01_app_controller.md | complete | AppController + provider |
| 02 | 02_welcome_screen.md | complete | Welcome screen |
| 03 | 03_model_download_screen.md | complete | Model download screen |
| 04 | 04_conversation_screen.md | complete | Conversation screen + widgets |
| 05 | 05_integration.md | complete | End-to-end wiring, demo-ready |

---

## Phase 06 - Stabilization

| # | Plan file | Status | Produces |
|---|-----------|--------|----------|
| 00 | 00_error_handling.md | complete | Failure taxonomy + recovery UI |
| 01 | 01_loading_states.md | complete | Progress/loading indicators |
| 02 | 02_testing_strategy.md | complete | Test suite |
| 03 | 03_performance.md | complete | Budgets + device tier |

---

## Phase 07 - Release

| # | Plan file | Status | Produces |
|---|-----------|--------|----------|
| 00 | 00_build_config.md | complete | Release build + signing |
| 01 | 01_play_store_alpha.md | in-progress | Play Store listing (docs done, manual steps remain) |
| 02 | 02_tracking_template.md | complete | Final tracking.md |
