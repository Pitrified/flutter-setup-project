# Polish plans for flutter-setup-project

## Overview

1. read `flutter-setup-project/plans/00_drafts/00_flutter_structure.md` to understand the project
1. read `flutter-setup-project/plans/00_drafts/01_llm_local_integration.md` to understand the main technical challenge of running an LLM locally on mobile
1. skim `unity-setup-project/docs/README.md` and other files in `unity-setup-project` as needed, to understand the documentation and planning structure and style, which is something we did in the unity-setup-project and will be reusing for flutter-setup-project
1. read `lang-tools/docs/library/exercises.md` and other files in `lang-tools`, looking specifically for the conversational tutoring related models and LLM services, since those are the most relevant to the core gameplay loop of flutter-setup-project. no broader exercise framework, no webapp, no word ingestion pipelines, etc.

compute gaps between the current state of the `flutter-setup-project` documentation and the ideal state as exemplified by `unity-setup-project` and `lang-tools`, and create a plan for filling those gaps. prioritize based on what will unblock development the most, and what is most critical to have in place before we start building.

remember that the user is a complete flutter novice, so the documentation should start from zero, which is installing the dev environment and needed dependencies, to creating a new flutter project, to publishing the first playable demo

include a portion of meta-optimization, where we keep in mind that the main implementer of the code will be an AI assistant, so keep files like `.github/copilot-instructions.md` updated with a clean instruction set, to navigate the rest of the documentation and the codebase we are building.

plan out the documentation structure, the plans to create in `plans` folder, with a oneliner of what each file would contain, and the order in which they should be tackled
group plans in the `plans/NN_plan_name` folder as needed, creating new folders for each major phase of the project

## Gap Analysis

### What unity-setup-project has that flutter-setup-project lacks

| Concern | unity-setup-project | flutter-setup-project |
|---------|--------------------|-----------------------|
| Functional spec (locked scope) | functional-specs.md with 14 sections, explicit out-of-scope | Scattered draft notes only |
| Project structure | project-structure.md with folder tree + asmdef boundaries | Nothing |
| Coding standards | coding-standards.md (9 sections, naming, idioms, logging) | Nothing |
| System specs | 10 individual system docs following identical template | Draft in 00_flutter_structure.md (outline only) |
| AI development playbook | 10-section playbook with prompting patterns, review checklist, forbidden actions | Nothing |
| Dev environment setup | dev-environment-setup.md (local toolchain) | Nothing (user is Flutter novice) |
| Tracking/roadmap | tracking.md with phased checklist, HUMAN:/AI: labels | Nothing |
| Build and release | build-and-release.md + google-play-private-alpha.md | Nothing |
| Copilot instructions | Detailed .github/copilot-instructions.md with stack, constraints, file boundaries | Skeleton only |
| Git workflow | git-workflow.md | Nothing |
| Testing strategy | testing-strategy.md | Nothing |
| Docs README (index) | docs/README.md with reading order, mental model table, workflow loop | Empty file |

### What lang-tools teaches us for the core loop

| Pattern | Relevance to flutter-setup-project |
|---------|-------------------------------------|
| TutorMessage model (role, content, translation, correction) | Direct port needed for conversation data model |
| Structured LLM output (CorrectionBlock, ConversationBlock, ErrorDetail) | Maps to StructuredTutorResponse in the Flutter draft |
| Chain pattern (build_tutor_chain factory returning typed callable) | RuntimeAdapter.generateStructured() must mirror this |
| Pydantic schema validation on LLM output | Maps to freezed + json_serializable validation pipeline |
| Prompt templates (Jinja with context/task/constraints) | On-device prompts need same structure but smaller |
| Exercise base interface (start/submit/finish) | ConversationController lifecycle matches this |

### Transferable principles from llm-core

These are architectural principles borrowed from `llm-core` that apply to our context.
We are NOT building a Dart port of llm-core or connecting to it. These are design patterns only.

| Principle | How it applies |
|-----------|----------------|
| Eager input validation at construction | Validate prompt variables match input model fields before inference runs. Catch schema mismatches at zero cost. |
| Schema-enforced structured output | Define output as strongly-typed Dart class with fromJson/toJson. Parse model output, validate against schema, fail fast on invalid. |
| Versioned prompt management | Store prompts as versioned files bundled in app assets. Never edit existing version, create vN+1 instead. PromptLoader auto-selects latest. |
| Provider abstraction via factory | Define InferenceEngine interface. Concrete implementations: FlutterGemmaEngine, FakeInferenceEngine. Swap backends without changing app code. |
| Lazy initialization of expensive resources | Model weights loaded on first inference call, not at app startup. Cache in memory for subsequent calls. |
| Config vs loading separation | Data shape (typed config classes) separate from data loading (initialization layer reads from disk/prefs). Makes testing trivial. |
| Deterministic mock backends | FakeInferenceEngine returns pre-loaded responses in sequence. Unit tests run without loading a real model. |

### Critical differences (mobile-local vs server-side)

- No retry over network; constrained decoding replaces server-side retries
- Model is 0.6B-3B, not GPT-4; prompts must be minimal
- Schema validation happens at token generation time (FSM), not after
- No streaming needed initially; output arrives in one shot

### LLM SDK choice

flutter_gemma is the initial SDK, but NOT a hard lock. The InferenceEngine interface
must be designed so the SDK is swappable (e.g., to MLC-LLM or a future LiteRT-LM package).

Complexity assessment of keeping this open:
- The InferenceEngine abstract interface already isolates app code from the SDK.
- The main friction points between SDKs: initialization API, constrained decoding support,
  model file format (.task vs .gguf vs .litertlm), and available configuration knobs.
- Strategy: define the interface based on the MINIMAL common surface (initialize, predict,
  predictStructured, dispose, isAvailable). SDK-specific options live in the concrete
  implementation's config, not in the interface.
- Constrained decoding is the biggest divergence. If an SDK lacks it, the fallback is
  prompt-only schema enforcement + post-hoc validation (less reliable but functional).
- Model file format differences are handled by the ModelManager, not the InferenceEngine.
- Cost of keeping it open: one extra layer of indirection (the interface), which we already
  need for the FakeInferenceEngine anyway. Net cost is near zero.

---

## Decisions (from user feedback)

- **OS**: Linux (no macOS/Xcode needed)
- **Target platform**: Android only (no iOS/TestFlight plans)
- **Model strategy**: Download on first launch (smaller APK, needs internet once)

---

## Coordination and Tracking

### Status boxes

Every plan file starts with a YAML-style status header:

```markdown
---
status: draft | in-progress | complete
depends_on: [list of plan files this depends on]
produces: [list of docs/code files this plan creates]
---
```

### Overarching tracker

A top-level `plans/00_tracking.md` file tracks the status of every plan file across all phases.
Updated after each plan is completed. Contains a table with: phase, file, status, produced artifacts.

---

## Documentation Structure

Following the `guides/library` pattern from `lang-tools`:

```
docs/
  README.md                           # Index, reading order, mental model, workflow loop
  getting-started.md                  # Dev environment setup (Flutter novice path)
  functional-specs.md                 # Locked scope (source of truth)
  project-structure.md                # Folder layout + package boundaries
  coding-standards.md                 # Dart style, naming, state management
  ai-development-playbook.md          # AI collaboration model, prompting, review
  git-workflow.md                     # Branches, commits, .gitignore
  testing-strategy.md                 # Unit/widget/integration test approach
  guides/
    prompts.md                        # On-device prompt engineering guide
    model-management.md               # Download, cache, validate model files
    structured-output.md              # Schema validation pipeline
  library/
    app-controller.md                 # System spec: AppController
    llm-runtime-adapter.md            # System spec: LLMRuntimeAdapter
    conversation-controller.md        # System spec: ConversationController
    structured-output-system.md       # System spec: StructuredOutputSystem
    conversation-repository.md        # System spec: ConversationRepository
    runtime-model-manager.md          # System spec: RuntimeModelManager
    generated-models.md               # System spec: Data models (freezed)
  build/
    build-and-release.md              # Release build config
    google-play-alpha.md              # Play Store private alpha
```

---

## Plan Structure

Plans are grouped by phase. Each folder represents a major milestone.
Within a folder, files are numbered in execution order.
Each folder contains a `README.md` with a high-level overview of that phase's goals and contents.

```
plans/
  00_drafts/README.md                 (raw research material index)
  00_tracking.md                      (overarching status tracker)
  01_plan_polishing/README.md         (this meta-plan phase)
  02_foundation/README.md             (docs + env before any code)
  03_scaffold/README.md               (project creation + deps)
  04_core_systems/README.md           (runtime, fake provider, structured output, persistence)
  05_conversation_loop/README.md      (tutor integration end-to-end)
  06_stabilization/README.md          (UX polish, error handling, testing)
  07_release/README.md                (build, sign, publish to Play Store)
```

---

## Phase 02 - Foundation (docs + environment)

Goal: produce all documentation needed to unblock AI-assisted development.
No code written yet; only docs and config.

| File | Content |
|------|---------|
| `02_foundation/00_dev_environment.md` | Install Flutter SDK on Linux, Android Studio, VS Code extensions, create Android emulator, verify `flutter doctor` passes. Step-by-step novice path. |
| `02_foundation/01_functional_spec.md` | Locked scope definition: what the app does, Android-only constraints, core technical decisions (Riverpod, GoRouter, Hive, flutter_gemma), screen inventory, out-of-scope list. Follows unity 14-section template. Other sections can be added if needed, or removed if irrelevant. |
| `02_foundation/02_project_structure.md` | Target folder layout, package/layer boundaries for a Flutter/Riverpod/GoRouter app. Where services, models, screens, prompts live. |
| `02_foundation/03_coding_standards.md` | Dart style, naming, state management rules (Riverpod patterns), widget decomposition, logging, error handling conventions. |
| `02_foundation/04_ai_development_playbook.md` | AI usage levels, prompting pattern (Context/Task/Constraints), review checklist, forbidden actions, Copilot config. Flutter-specific. |
| `02_foundation/05_system_specs_template.md` | Reusable template for docs/library/ system docs (Overview, Responsibilities, Lifetime, Interface, Interactions, Constraints, Failure Handling). |
| `02_foundation/06_copilot_instructions.md` | Full rewrite of `.github/copilot-instructions.md` with stack, reading order, hard rules, docs navigation. |
| `02_foundation/07_docs_readme.md` | Plan the docs/README.md index with reading order, mental model table, workflow loop. |

---

## Phase 03 - Scaffold (project creation + configuration)

Goal: create the Flutter project, configure dependencies, validate it builds and runs on Android emulator.

| File | Content |
|------|---------|
| `03_scaffold/00_create_project.md` | `flutter create`, initial pubspec.yaml with locked dependencies (riverpod, go_router, hive, freezed, flutter_gemma, json_serializable). Android-only config. |
| `03_scaffold/01_folder_structure.md` | Create the folder tree from project_structure.md, add placeholder files, configure analysis_options.yaml. |
| `03_scaffold/02_generated_models.md` | Define freezed models (ConversationMessage, StructuredTutorResponse, TutorCorrectionBlock), run build_runner, validate codegen works. |
| `03_scaffold/03_routing_and_providers.md` | GoRouter setup (Welcome, Conversation screens), Riverpod bootstrap, app entry point wiring. |
| `03_scaffold/04_git_workflow.md` | .gitignore for Flutter/Android, branch strategy, commit conventions. |

---

## Phase 04 - Core Systems (runtime + fake provider + structured output + persistence)

Goal: the critical backend systems work in isolation, with a fake LLM provider enabling
full conversation loop development without waiting for real model integration.

| File | Content |
|------|---------|
| `04_core_systems/00_inference_interface.md` | InferenceEngine abstract interface (initialize, predict, predictStructured, dispose, isAvailable). Clean contract that both real and fake backends satisfy. |
| `04_core_systems/01_fake_inference_engine.md` | FakeInferenceEngine implementation: returns pre-loaded structured responses from a JSON fixture file. Configurable via Riverpod provider override. Enables full UI/flow development without a real model. |
| `04_core_systems/02_flutter_gemma_engine.md` | FlutterGemmaEngine implementation: flutter_gemma backend, initialization lifecycle, model loading, constrained decoding config, dispose. |
| `04_core_systems/03_structured_output.md` | Schema definition (freezed), JSON extraction, validation pipeline, constrained decoding configuration in flutter_gemma, fallback for invalid output. |
| `04_core_systems/04_conversation_repository.md` | Hive-backed persistence, save/load/append/delete, message and metadata storage. |
| `04_core_systems/05_model_manager.md` | Model detection, download-on-first-launch flow, progress UI, compatibility check, cache location in app storage. |
| `04_core_systems/06_prompt_manager.md` | Versioned prompt files in assets/, PromptLoader utility, variable substitution, token budget awareness. |

---

## Phase 05 - Conversation Loop (end-to-end tutor)

Goal: user can type a message, get a structured tutor response, see correction + reply.
Initially wired to FakeInferenceEngine; swappable to real model via config.

| File | Content |
|------|---------|
| `05_conversation_loop/00_conversation_controller.md` | ConversationController state machine, message flow, prompt building from history, context window strategy (rolling subset). |
| `05_conversation_loop/01_prompt_engineering.md` | On-device prompt templates for the tutor: system prompt, schema instructions, few-shot examples, token budget constraints for 0.6B-3B models. |
| `05_conversation_loop/02_ui_screens.md` | Welcome screen (runtime status, start button) + Conversation screen (message list, input, send, loading indicator). Widget tree and Riverpod state bindings. |
| `05_conversation_loop/03_backend_swap.md` | Switching from FakeInferenceEngine to FlutterGemmaEngine. Environment-based provider configuration. Validation that the full flow works with both backends. |
| `05_conversation_loop/04_integration_test.md` | End-to-end flow validation: launch, init runtime, send message, receive structured response, persist. Uses fake engine for CI. |

---

## Phase 06 - Stabilization (UX + error handling + testing)

Goal: app handles all failure modes gracefully, tests pass, performance is acceptable on target devices.

| File | Content |
|------|---------|
| `06_stabilization/00_error_handling.md` | Failure taxonomy (runtime unavailable, model download fail, invalid output, storage corrupt), recovery UI for each. |
| `06_stabilization/01_loading_states.md` | Model download progress, inference generation indicator, skeleton screens, timeout handling. |
| `06_stabilization/02_testing_strategy.md` | Unit tests (models, validation), widget tests (screens), integration tests (full flow with fake engine). Test doubles strategy. |
| `06_stabilization/03_performance.md` | Memory budget, inference latency targets, cold start time, minimum Android device tier (Snapdragon 8 Gen 1, 8 GB RAM). |

---

## Phase 07 - Release (build + publish to Play Store)

Goal: signed APK on a real Android device, then private alpha on Google Play.

| File | Content |
|------|---------|
| `07_release/00_build_config.md` | Release build settings, signing keystore, ProGuard/R8, model download vs bundle final decision, APK size budget. |
| `07_release/01_play_store_alpha.md` | Google Play Console setup, internal testing track, listing metadata, content rating, compliance review. |
| `07_release/02_tracking_template.md` | Final tracking.md template with all phases as checklist items, HUMAN:/AI: labels, links back to relevant docs. |

---

## Execution Order and Priority

1. **Phase 02 first** - documentation unblocks everything. Without functional-spec and copilot-instructions, AI cannot generate correct code.
2. **Phase 03 next** - a running empty app validates the environment and toolchain.
3. **Phase 04** - core systems built with fake engine first (01) enabling parallel UI work, then real engine (02) and supporting systems.
4. **Phase 05** - wires everything together; starts with fake backend, swaps to real at the end.
5. **Phase 06** - hardens what exists.
6. **Phase 07** - ships it.

Within Phase 02, priority order is:
1. `00_dev_environment.md` - user cannot do anything without a working Flutter install
2. `01_functional_spec.md` - defines what we are building (source of truth)
3. `06_copilot_instructions.md` - enables AI to work correctly on all subsequent tasks
4. `02_project_structure.md` - AI needs to know where files go
5. `03_coding_standards.md` - AI needs to know how to write Dart
6. `04_ai_development_playbook.md` - defines the collaboration model
7. `05_system_specs_template.md` - template for docs/library/ system docs
8. `07_docs_readme.md` - ties it all together

Within Phase 04, the fake engine (01) comes immediately after the interface (00) so that
Phase 05 UI/flow work can proceed in parallel with the real engine integration (02).

---

## Notes

- Each plan file is self-contained: it should contain enough context for an AI agent to execute it without reading other plans.
- Every plan file has a YAML status header (draft/in-progress/complete) and lists dependencies and produced artifacts.
- Plans reference the drafts in `00_drafts/` as source material but produce polished docs in `docs/`.
- The `.github/copilot-instructions.md` is updated at the end of Phase 02 and again after each major phase.
- The `plans/00_tracking.md` is the single source of truth for overall progress across all phases.
- The docs follow the `guides/library` structure from lang-tools: `docs/guides/` for tooling/conventions, `docs/library/` for system specs.
- The FakeInferenceEngine is a first-class citizen, not a testing afterthought. It enables full conversation loop development without a real model, and remains useful for CI and widget tests permanently.
- llm-core principles (provider abstraction, versioned prompts, eager validation, lazy loading) are applied as design patterns, not as a library dependency.
- Model download-on-first-launch is the chosen strategy (smaller APK, requires internet once).
- Target platform is Android only (Linux dev environment, no iOS/Xcode).
- The LLM SDK (flutter_gemma) is the initial choice but explicitly swappable. The InferenceEngine interface is the stable contract; the SDK is an implementation detail behind it.

---

## Plan-to-Docs Flow

Plans are detailed blueprints that may evolve during implementation. The flow is:

1. **Write plan** - detailed outline with section headers, key decisions, and expected content.
   Plan lives in `plans/NN_phase/MM_topic.md` with status `draft`.
2. **Execute plan** - implement the code/config described. Plan status moves to `in-progress`.
   During implementation, decisions may change; update the plan file to reflect reality.
3. **Update docs** - at the end of a phase (or when a significant system is complete),
   produce the polished documentation in `docs/` based on what was actually built.
   The plan is the blueprint; the doc reflects the final state.
4. **Mark complete** - plan status moves to `complete`. Update `plans/00_tracking.md`.
5. **Update copilot-instructions** - after each major phase, refresh `.github/copilot-instructions.md`
   to point to the new docs and reflect the current state of the codebase.

This ensures docs are always accurate (written from reality, not from plans that drifted),
while plans remain useful as historical records of intent and decisions made along the way.

### No-duplication rule

Documentation must never repeat information that exists elsewhere. Instead, link to it:

- If a concept is defined in a system spec, other docs link to it with a relative path
  (e.g., `see [LLMRuntimeAdapter](library/llm-runtime-adapter.md)`).
- If behavior is defined in code (interface, enum, config class), docs link to the source file
  or reference the code symbol - they do not restate the implementation.
- Cross-references use clickable markdown links with relative paths. Never use backtick-only
  file references when a link would work.
- The single source of truth for each concern is defined once and linked everywhere else.
  If two docs start saying the same thing, one of them is wrong - collapse into link.
