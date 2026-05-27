# Phase 04 - Core Systems

Build the critical backend systems in isolation. A fake inference engine
enables full conversation loop development without waiting for real model integration.

## Goal

Three independent, testable systems: inference (with fake and real backends),
structured output validation, and conversation persistence.

## Planned contents

| File | Produces |
|------|----------|
| 00_inference_interface.md | InferenceEngine abstract interface |
| 01_fake_inference_engine.md | FakeInferenceEngine (pre-loaded responses) |
| 02_flutter_gemma_engine.md | FlutterGemmaEngine (real on-device inference) |
| 03_structured_output.md | Schema validation pipeline + constrained decoding config |
| 04_conversation_repository.md | Hive-backed persistence layer |
| 05_model_manager.md | Model download, cache, and compatibility logic |
| 06_prompt_manager.md | Versioned prompt loading from assets |

## Dependencies

Requires Phase 03 (project must exist and build).

## Key design decision

The fake engine (01) is built immediately after the interface (00) so that
Phase 05 UI/flow work can begin in parallel with real engine integration (02).
