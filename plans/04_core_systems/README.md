# Phase 04 - Core Systems

Build the critical backend systems in isolation. A fake inference engine
enables full conversation loop development without waiting for real model integration.

## Goal

Three independent, testable systems: inference (with fake and real backends),
structured output validation, and conversation persistence.

## Plans (all written, not yet executed)

| File | Produces |
|------|----------|
| [00_inference_interface.md](00_inference_interface.md) | InferenceEngine abstract interface |
| [01_fake_inference_engine.md](01_fake_inference_engine.md) | FakeInferenceEngine (pre-loaded responses) |
| [02_flutter_gemma_engine.md](02_flutter_gemma_engine.md) | FlutterGemmaEngine (real on-device inference) |
| [03_structured_output.md](03_structured_output.md) | Schema validation pipeline + constrained decoding config |
| [04_conversation_repository.md](04_conversation_repository.md) | Hive-backed persistence layer |
| [05_model_manager.md](05_model_manager.md) | Model download, cache, and compatibility logic |
| [06_prompt_manager.md](06_prompt_manager.md) | Versioned prompt loading from assets |

## Prerequisites

- Phase 03 complete (project builds and runs)
- Freezed models exist and generate correctly

## Execution order

00 -> 01 (unblocks Phase 05 UI work) -> 03, 04, 05, 06 (parallel) -> 02 (last, needs real model)

## Key design decision

The fake engine (01) is built immediately after the interface (00) so that
Phase 05 UI/flow work can begin in parallel with real engine integration (02).
