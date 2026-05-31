# OpenAI integration

## Context

The rest of the codebase uses on-device LLMs (`flutter_gemma` + Qwen3 0.6B) behind
the `InferenceEngine` abstraction in
[`lib/services/inference/inference_engine.dart`](../../lib/services/inference/inference_engine.dart).
This plan covers a parallel cloud path: an `OpenAiInferenceEngine` that satisfies the
same interface so the rest of the app (`StructuredInferenceEngine<T>`, providers, UI)
stays untouched.

The architectural feasibility was already established in earlier reports:

- [`00.2_llm_integration_report.md` (Section 3)](00.2_llm_integration_report.md) -
  estimated 2-4 hours of Dart work, identifies key distribution as the real problem.
- [`00_coalesced_plan.md` (Deferred decision B)](00_coalesced_plan.md) - summary
  table of key-distribution options.

This file picks one concrete Dart integration approach and one key-distribution
approach for the internal-alpha APK, and defers production-grade key handling to
[`04_api_key_distribution_production.md`](04_api_key_distribution_production.md).

---

## Goal for this phase

- Add `OpenAiInferenceEngine` alongside `FlutterGemmaEngine` and `FakeInferenceEngine`.
- Keep the existing `StructuredInferenceEngine<T>` parser path working unchanged.
- Use the simplest viable key-distribution model: user enters the key once in a
  Settings screen, stored in Android Keystore via `flutter_secure_storage`.
- Internal/alpha distribution only. No production hardening.

Non-goals: backend proxy, Play Integrity, key rotation, billing/quotas.

---

## OpenAI integration options (Flutter / Dart)

Research date: 2026-05-31. Pub.dev was queried for active OpenAI Dart packages and
their structured-output support.

### Option A - `openai_dart` (recommended)

- Pub: [`openai_dart` ^6.0.0](https://pub.dev/packages/openai_dart),
  publisher `davidmiguel.com`, MIT, 23.8k downloads, 127 likes, last release 6 days
  ago. Source: [`davidmigloz/ai_clients_dart`](https://github.com/davidmigloz/ai_clients_dart/tree/main/packages/openai_dart).
- Pure Dart, no Flutter dependency. Works on Android.
- Type-safe request/response models, generated from OpenAPI specs.
- Covers Chat Completions, Responses API, streaming, tool calling, embeddings,
  images, audio, realtime (WebSocket/WebRTC).
- **Structured output supported on both Chat Completions and Responses API**
  via `response_format: json_schema` (the OpenAI-native strict JSON Schema mode).
- Built-in retries, interceptors, error handling.
- Same author/quality bar as `langchain_dart` and `ollama_dart`.

How it slots in (sketch, not for commit):

```dart
final client = OpenAIClient(apiKey: userKey); // key from secure storage

final response = await client.createChatCompletion(
  request: CreateChatCompletionRequest(
    model: ChatCompletionModel.modelId('gpt-4o-mini'),
    messages: [
      ChatCompletionMessage.system(content: systemPrompt),
      ChatCompletionMessage.user(
        content: ChatCompletionUserMessageContent.string(userPrompt),
      ),
    ],
    responseFormat: ResponseFormat.jsonSchema(
      jsonSchema: JsonSchemaObject(
        name: 'correction',
        strict: true,
        schema: correctionJsonSchema, // same map shape used for Qwen3 tool calling
      ),
    ),
  ),
);

final raw = response.choices.first.message.content ?? '';
return InferenceSuccess(rawText: raw);
```

The schema map is identical in shape to the one already used for `Tool.parameters`
in [`02_tool_calling.md`](02_tool_calling.md), so `StructuredOutputParser` keeps
working unchanged.

### Option B - `dart_openai`

- Pub: [`dart_openai` ^6.1.1](https://pub.dev/packages/dart_openai), MIT,
  22.5k downloads, 574 likes, last release ~6 months ago.
- Older and more popular than `openai_dart` but maintenance has slowed.
- Supports Chat Completions, streaming, function calling.
- Supports basic `response_format: json_object` but not the strict
  `json_schema` mode as a first-class field at the time of writing.
- Static-singleton API (`OpenAI.instance...`) which is harder to test and to
  inject behind `InferenceEngine`.

Slot-in cost: similar surface, but we lose strict schema enforcement and need
post-hoc JSON repair more often. Not preferred.

### Option C - `langchain_dart` + `langchain_openai`

- Pub: [`langchain`](https://pub.dev/packages/langchain) +
  [`langchain_openai`](https://pub.dev/packages/langchain_openai), same author
  as `openai_dart`.
- Adds prompt templating, chains, output parsers, agents on top of `openai_dart`.
- Brings transitive surface area (chains, memory, retrievers) we do not need.
- For a single structured call per turn, this is overkill. The app already has
  its own `StructuredInferenceEngine<T>` and prompt assembly.

Not recommended unless we later adopt a richer LangChain-style pipeline.

### Option D - Raw `http` client against OpenAI REST

- Zero dependency cost; ~80 lines of code.
- Full control over wire format, easy to mock for tests.
- We hand-roll request/response models (with `freezed`/`json_serializable`) and
  re-implement retries, streaming parsing, error mapping.
- Only attractive if we want to minimise dependencies and pin the wire format
  ourselves. Adds maintenance for no clear win versus `openai_dart`.

Fallback option, not the default.

### Option E - `llm_dart`

- Pub: [`llm_dart`](https://pub.dev/packages/llm_dart), MIT.
- Unified facade across OpenAI, Anthropic, Google, Ollama, Groq, DeepSeek, xAI.
- Useful if we want to swap providers behind one API without re-implementing the
  engine each time. But `InferenceEngine` already gives us that abstraction at
  the project level, and a multi-provider facade adds a second layer of
  indirection on top.

Reconsider only if we plan to ship more than one cloud provider concurrently.

### Recommendation

Use **Option A (`openai_dart`)**:

- Actively maintained, type-safe, pure Dart, MIT.
- First-class `response_format: json_schema` strict mode, which matches the
  guarantee level we currently get from `ToolChoice.required` on Qwen3.
- Same author as `langchain_dart`, so we can graduate to chains later without
  changing the OpenAI client.
- Adds one dependency (`openai_dart`), no transitive Flutter coupling.

This requires explicit approval per the "No new dependencies without explicit
approval" hard rule.

---

## Proposed implementation outline

This is the plan; no code changes yet. Files listed are reference only.

### Decisions locked in

- Dependencies approved: `openai_dart: ^6.0.0` and `flutter_secure_storage`.
- Default OpenAI model: `gpt-4o-mini`, user-editable in Settings.
- Engines coexist. Settings exposes an **engine selector** with at least
  `fake`, `gemma` (local Qwen3/Gemma via `flutter_gemma`), and `openai`.
  Selector is a plain `enum EngineKind { fake, gemma, openai }` plus a
  registry map keyed by it - adding a future engine = new enum value +
  new registry entry, no edits at call sites.
- Persistence: non-secret settings (engine choice, model name) live in
  **Hive** (the project already uses it - no new storage layer).
  `flutter_secure_storage` (Android Keystore) is used **only** for the
  OpenAI API key.
- Key validation: **trust the user on Save**. No pre-flight call. The
  first `generate()` surfaces a clear `InferenceFailure` if the key is
  missing or rejected.
- Settings location: **new top-level Settings screen**, reachable from
  the app bar on the conversation screen.
- No streaming this phase. `InferenceEngine.generate()` stays
  `Future<InferenceResult>`. OpenAI streaming is a follow-up.

### Steps

1. **Add dependencies** in [`pubspec.yaml`](../../pubspec.yaml):
   `openai_dart`, `flutter_secure_storage`.
2. **Engine kind enum** in
   `lib/services/inference/engine_kind.dart`:

   ```dart
   enum EngineKind { fake, gemma, openai }
   ```

   Plus a `displayName` extension for the Settings UI. Adding a new kind
   later is one enum value + one factory registration.
3. **Engine registry / factory** in
   `lib/services/inference/engine_registry.dart`. Map
   `EngineKind -> InferenceEngine Function()`. The existing engine-factory
   pattern from [`00_coalesced_plan.md` Step 6](00_coalesced_plan.md) is
   extended from "single factory" to "keyed registry" so additional engines
   slot in without modifying selection code.
4. **`OpenAiInferenceEngine`** in
   `lib/services/inference/openai_inference_engine.dart`. Implements
   `InferenceEngine`. Constructor takes an `OpenAIClient` (or a key-loader
   callback) and the selected model name. `generate()` issues one Chat
   Completion with `ResponseFormat.jsonSchema(strict: true)` and returns
   `InferenceSuccess` with the raw JSON text. `StructuredOutputParser`
   stays unchanged.
5. **Secure key storage** wrapper in
   `lib/services/settings/api_key_store.dart` over `FlutterSecureStorage`.
   Methods: `read()`, `write(String key)`, `clear()`. No plaintext on disk.
   This wrapper holds **only** the OpenAI key.
6. **Non-secret settings store** in
   `lib/services/settings/app_settings_repository.dart` over Hive. Holds
   `EngineKind` and the OpenAI model name. Reuses the existing Hive setup
   from the conversation repository; no new storage layer is introduced.
7. **Settings screen** as a new top-level route
   (`lib/screens/settings/settings_screen.dart`), reachable from the
   conversation screen app bar:
   - **Engine selector** dropdown bound to `EngineKind`, persisted via
     the Hive settings repository.
   - **OpenAI section** (visible when `EngineKind.openai` selected):
     obscured API key field (Save / Clear via `ApiKeyStore`, no
     pre-flight validation), model name field defaulting to
     `gpt-4o-mini` (persisted in Hive).
   - Switching engines hot-swaps the active `InferenceEngine` via the
     Riverpod provider; current generation, if any, is cancelled cleanly.
8. **Tests** with a fake `OpenAIClient` (per the "Use FakeInferenceEngine
   for all tests" rule, we never hit the real network in CI). Cover:
   missing key, 401, network timeout, malformed JSON, happy path, and the
   engine-switch flow in the registry.
9. **Logging**: use the project logger. Log model name, latency, prompt
   length, token usage; never the key, never the user prompt at info level.

Estimated Dart work: ~half a day plus tests.

### Commit split

Implementation lands in two commits, each with its own sub-plan:

1. [`03.1_registry_and_settings_shell.md`](03.1_registry_and_settings_shell.md) -
   `EngineKind` enum, registry, Hive-backed `AppSettingsRepository`,
   `ApiKeyStore` wrapper, new Settings screen with engine selector
   (`fake` / `gemma` only; `openai` disabled). Adds `flutter_secure_storage`.
2. [`03.2_openai_engine.md`](03.2_openai_engine.md) - `OpenAiInferenceEngine`,
   activate the OpenAI section in Settings (key + model fields), register
   `EngineKind.openai` in the registry. Adds `openai_dart`.

The `fake` engine stays in the production Settings selector for manual
on-device UI testing.

---

## API key distribution

### Internal alpha (this phase)

Approach: **user-supplied key, stored in Android Keystore via
`flutter_secure_storage`**. This matches "Option A" from
[`00.2_llm_integration_report.md` Section 3](00.2_llm_integration_report.md)
and the "User-supplied API key" row in
[`00_coalesced_plan.md` Deferred B](00_coalesced_plan.md).

Why this is acceptable for internal-only APK:

- Distribution is to known testers, not the public Play Store.
- The key is the tester's own; cost and abuse risk land on them, not on us.
- Nothing sensitive is shipped inside the APK.
- Android Keystore protects the key at rest from other apps and from
  filesystem inspection on non-rooted devices.

What we still must not do, even in alpha:

- **No `--dart-define` defaults containing a real key.** A
  `--dart-define`-injected string ends up as a compile-time constant in
  `libapp.so` and is recoverable from the APK.
- **No `.env` shipped in `assets/`**. Asset bundles are plain files inside
  the APK ZIP.
- **No key in source control**, including example/fixture files.
- **No logging of the key**, including stack traces or error toasts.

Operational steps for a tester:

1. Install the alpha APK.
2. Open Settings, paste their personal OpenAI key, save.
3. App stores it via `FlutterSecureStorage`.
4. Switch the engine selector to "OpenAI".

If the key is missing or invalid, the engine surfaces an `InferenceFailure`
with a user-readable message ("OpenAI key missing or rejected. Open Settings
to update.") and the UI offers a deep link back to the Settings screen.

### Production (deferred)

A full design for public-distribution key handling lives in
[`04_api_key_distribution_production.md`](04_api_key_distribution_production.md).
That document is a plan only; nothing in it is in scope for this phase.

---

## Resolved decisions

1. **Dependencies approved**: `openai_dart` and `flutter_secure_storage`.
2. **Model**: default `gpt-4o-mini`, user-editable in Settings.
3. **Engine coexistence**: all engines coexist behind a Settings selector;
   architecture must remain extensible for future engines (Anthropic, Gemini
   cloud, additional local models).
4. **Streaming**: out of scope for this phase. `InferenceEngine.generate()`
   stays `Future<InferenceResult>`. Streaming is a follow-up that will
   require widening the interface.

Production-grade key distribution remains deferred - see
[`04_api_key_distribution_production.md`](04_api_key_distribution_production.md).
