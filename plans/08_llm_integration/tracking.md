# Llm integration - implementation tracking

Real inference, in two waves: Qwen3-0.6B on device through flutter_gemma, then the OpenAI
cloud engine through openai_dart with a selector in Settings. Production key distribution was
deferred to folder 13.

This folder ran before `tracking.md` was the convention, so this file was written during the
normalisation pass in
[`../21_plans_query_skill/02_normalisation.md`](../21_plans_query_skill/02_normalisation.md). The table
is the phase files as they stand; the log is what `plans/00_tracking.md` recorded before it was deleted.

Analysis and decisions in [`00_start.md`](00_start.md).

## Phases

| #  | Phase | Plan | Status |
| -- | ------------------------------------------------------ | -------------------------------------------------------------------------------- | ------ |
| 01 | Constrained decoding                                   | [`01_structured_output_analysis.md`](01_structured_output_analysis.md)           | done |
| 02 | Tool Calling                                           | [`02_tool_calling.md`](02_tool_calling.md)                                       | done |
| 03 | OpenAI integration                                     | [`03_openai_integration.md`](03_openai_integration.md)                           | done |
| 04 | API key distribution - production hardening (deferred) | [`04_api_key_distribution_production.md`](04_api_key_distribution_production.md) | superseded |

Status values: draft / planned / in progress / done / superseded / discarded.

Side-documents, which belong to the phase they are numbered after and carry no status:

- [`00.1_llm_integration_report.md`](00.1_llm_integration_report.md)
- [`00.2_llm_integration_report.md`](00.2_llm_integration_report.md)
- [`00.3_llm_integration_report.md`](00.3_llm_integration_report.md)
- [`03.1_registry_and_settings_shell.md`](03.1_registry_and_settings_shell.md)
- [`03.2_openai_engine.md`](03.2_openai_engine.md)

## Log

Append-only. Newest at the bottom.

- 2026-07-09 : three analysis reports coalesced into one plan (the side-documents 00.1 to 00.3).
- 2026-07-10 : steps 1-3, deps and config: flutter_gemma, the INTERNET permission, the Qwen3 ModelConfig.
- 2026-07-10 : step 4, the download screen moved to FlutterGemma.installModel().
- 2026-07-11 : step 5, the engine rewritten against the v0.13.6 API.
- 2026-07-11 : step 6, provider wiring: NotifierProvider, EngineFactory, ModelChecker.
- 2026-07-11 : step 7, main.dart: the FAKE_ENGINE toggle and FlutterGemma.initialize().
- 2026-07-12 : step 8, on-device smoke test: download, init and inference all working.
- 2026-07-14 : the OpenAI engine landed through the two side-plans 03.1 and 03.2; the parent plan 03 is the design.
- 2026-07-14 : production key distribution deferred, and later superseded by folder 13.
