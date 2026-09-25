# Core systems - implementation tracking

The engine-agnostic core: the InferenceEngine interface, the fake engine every test uses, the
flutter_gemma engine, the structured-output parser, Hive persistence, the model manager and
the versioned prompt loader.

This folder ran before `tracking.md` was the convention, so this file was written during the
normalisation pass in
[`../21_plans_query_skill/02_normalisation.md`](../21_plans_query_skill/02_normalisation.md). The table
is the phase files as they stand; the log is what `plans/00_tracking.md` recorded before it was deleted.

Analysis and decisions in [`00_start.md`](00_start.md).

## Phases

| #  | Phase | Plan | Status |
| -- | ----------------------------------------------------- | ---------------------------------------------------------------------- | ------ |
| 00 | Plan: InferenceEngine Abstract Interface              | [`00_inference_interface.md`](00_inference_interface.md)               | done |
| 01 | Plan: FakeInferenceEngine                             | [`01_fake_inference_engine.md`](01_fake_inference_engine.md)           | done |
| 02 | Plan: FlutterGemmaEngine                              | [`02_flutter_gemma_engine.md`](02_flutter_gemma_engine.md)             | done |
| 03 | Plan: Structured Output Pipeline                      | [`03_structured_output.md`](03_structured_output.md)                   | done |
| 04 | Plan: Conversation Repository                         | [`04_conversation_repository.md`](04_conversation_repository.md)       | done |
| 05 | Plan: Model Manager                                   | [`05_model_manager.md`](05_model_manager.md)                           | done |
| 06 | Plan: Prompt Manager                                  | [`06_prompt_manager.md`](06_prompt_manager.md)                         | done |
| 07 | Plan: Decouple Structured Output from InferenceEngine | [`07_decouple_structured_output.md`](07_decouple_structured_output.md) | done |

Status values: draft / planned / in progress / done / superseded / discarded.

## Log

Append-only. Newest at the bottom.

- 2026-07-07 : 8/8 plans executed.
- 2026-07-08 : phase 07 split the generic parser out of the gemma engine, which is what let a second engine exist at all.
