# Phase 08 - LLM Integration (Coalesced Plan)

_Consolidated from reports 01, 02, and 03. Single source of truth._

---

## Decision: Use Qwen3 0.6B as proof-of-concept model

Qwen3 0.6B is the initial model for the following reasons:

- Apache 2.0 license - no auth gate, no HuggingFace token required
- Scores 0.880 on structured output benchmarks (vs Gemma 3 1B at 0.600)
- Smaller model (~400 MB quantized vs ~1.5 GB for Gemma 3 1B)
- Supported by `flutter_gemma` plugin
- Zero onboarding friction for download

This is a proof-of-concept choice. The `InferenceEngine` interface means switching models later is a config change, not an architectural one.

---

## Deferred decisions (documented, not blocking)

### A. Gemma license gate (deferred)

**Problem:** All Gemma models (including `litert-community/Gemma3-1B-IT`) are gated on HuggingFace under the Gemma license. Downloading requires:

1. A HuggingFace account
2. Accepting the Gemma license on the model page
3. A HF access token with read permissions

This creates onboarding friction for users. The `ModelConfig.defaultModel` URL currently points to a gated repo that returns `401 Access Restricted` without auth.

**Options to revisit later:**

| Option | Tradeoff |
|--------|----------|
| User supplies HF token | Works for alpha/technical users; friction for consumers |
| Find ungated community mirror | Fragile; can disappear or be DMCA'd |
| Bundle model in APK/app bundle | 1.5 GB APK; Play Store limits apply |
| Use Gemma 3n E2B (newer, possibly different licensing) | Check when available |

**Resolution path:** Once Qwen3 0.6B proves the pipeline works end-to-end, revisit Gemma if its structured output quality or Google ecosystem integration (constrained decoding) justifies the auth complexity.

---

### B. External API inference (deferred)

**Problem:** Adding a cloud API fallback (Gemini, OpenAI, Groq) is architecturally trivial thanks to `InferenceEngine`, but key distribution is the hard part.

**Key distribution options:**

| Approach | Security | Complexity | Best for |
|----------|----------|------------|----------|
| User-supplied API key | Safe | Low | Alpha, technical users |
| Backend proxy (FastAPI) | Safe | Medium | Production consumer app |
| Proxy + Play Integrity attestation | Strong | High | Public release |
| Hardcoded/build-time key | Unsafe | Low | Never for distribution |

**What NOT to do:** Embed keys in APK via `--dart-define`, `.env`, or assets. All are extractable.

**Resolution path:** After on-device pipeline works, implement `RemoteInferenceEngine` (~80 lines) with user-supplied key for alpha. Backend proxy for production later.

---

## Implementation plan

### Step 1 - Add `flutter_gemma` to pubspec.yaml

Add the dependency and run `flutter pub get`. Read the CHANGELOG for the installed version before writing any SDK calls.

```yaml
dependencies:
  flutter_gemma:   # latest from pub.dev
```

**Files:** `pubspec.yaml`

---

### Step 2 - Add INTERNET permission

Required for model download (regardless of whether we use ModelManager or plugin download).

```xml
<!-- android/app/src/main/AndroidManifest.xml, inside <manifest> -->
<uses-permission android:name="android.permission.INTERNET"/>
```

**Files:** `android/app/src/main/AndroidManifest.xml`

---

### Step 3 - Update ModelConfig for Qwen3 0.6B

Replace the gated Gemma URL with the ungated Qwen3 0.6B model.

**Confirmed model URL (Apache 2.0, no auth required):**

```
https://huggingface.co/litert-community/Qwen3-0.6B/resolve/main/Qwen3-0.6B.litertlm
```

- Repo: `litert-community/Qwen3-0.6B` (official LiteRT community)
- File: `Qwen3-0.6B.litertlm` (614 MB, GPU-accelerated via LiteRT-LM)
- Format: `.litertlm` (NOT `.task` - this matters for engine selection in flutter_gemma)
- License: Apache 2.0, ungated

```dart
static const defaultModel = ModelConfig(
  downloadUrl:
      'https://huggingface.co/litert-community/Qwen3-0.6B/resolve/main/Qwen3-0.6B.litertlm',
  fileName: 'Qwen3-0.6B.litertlm',
  fileSizeBytes: 614000000,  // ~614 MB
);
```

**Also update:** Remove all hardcoded `'gemma3-1b-it.task'` references. See risk section below.

**Files:** `lib/config/model_config.dart`

---

### Step 4 - Delegate download to plugin (retire custom ModelManager for download)

The `flutter_gemma` plugin has built-in download with:
- Android Foreground Service (prevents OS kill after 9 min for large downloads)
- Progress callbacks
- Retry logic

The current `ModelManager` uses raw `HttpClient` which will be killed by Android for background downloads > 9 minutes.

**Strategy:** Use the plugin's `installModel().fromNetwork(url).install()` for download. Keep `ModelManager` only for checking if a model is already downloaded (path resolution). The `ModelDownloadScreen` adapts to use plugin download callbacks instead of `ModelManager.downloadModel()`.

**Files:** `lib/services/model/model_manager.dart`, `lib/screens/model_download/model_download_screen.dart`

---

### Step 5 - Implement FlutterGemmaEngine against current API

The stub uses a deprecated API. The current `flutter_gemma` is at **v0.16.2** (May 2026). Key changes since the stub was written:

- v0.5.0: Replaced `FlutterGemma` singleton with `ModelManager` + `InferenceModel`
- v0.11.4: Fluent builder API (`installModel().fromNetwork()`)
- v0.11.10: **BREAKING** - Requires `await FlutterGemma.initialize()` in main()
- v0.12.3: Automatic engine selection (`.litertlm` -> LiteRT-LM, `.task/.bin` -> MediaPipe)
- v0.13.6: Added `ModelType.qwen3` with thinking support
- v0.14.0: Desktop FFI rewrite; Android `.litertlm` via Dart FFI (no Kotlin AAR)
- v0.16.0: Native vector store (qdrant-edge)

The current pattern (v0.14+):

```dart
// App initialization (once, in main):
await FlutterGemma.initialize();

// Model install (fluent builder):
await FlutterGemma.installModel(modelType: ModelType.qwen3)
    .fromNetwork(url)
    .install();

// Load model into memory:
final model = await FlutterGemma.getActiveModel(maxTokens: 1024);

// Create chat session:
final chat = await model.createChat(
  systemInstruction: 'You are a Portuguese tutor...',
  isThinking: false,  // disable Qwen3 thinking mode for structured output
);

// Or simpler session-based (no system instruction):
final session = await model.createSession();
await session.addQueryChunk(Message.text('...'));
final response = session.getResponseAsync(); // Stream<String?>
```

**Key notes for Qwen3:**
- Use `ModelType.qwen3` (added v0.13.6)
- Set `isThinking: false` for structured JSON output (avoids `<think>` tags)
- `.litertlm` files auto-route to LiteRT-LM engine on Android (v0.12.3+)
- GPU backend selected by default; CPU fallback available

**Files:** `lib/services/inference/flutter_gemma_engine.dart`

---

### Step 6 - Fix provider wiring gap (engine factory pattern)

**The problem:**

```
main.dart (ProviderScope)
  └── inferenceEngineProvider ← needs engine at startup
        └── appControllerProvider ← uses engine
              └── AppController.initialize() ← only here do we know model path
```

`FlutterGemmaEngine` needs either a model path or URL at construction time, but the path is only confirmed after `ModelManager` checks the filesystem inside `AppController.initialize()`. The Riverpod override happens before this.

**The solution: Engine Factory pattern**

Do NOT inject a ready-made engine. Inject a factory that `AppController` calls after confirming the model exists.

```dart
// Provider that supplies an engine factory, not an engine instance
typedef EngineFactory = InferenceEngine Function(String modelPath);

final engineFactoryProvider = Provider<EngineFactory>((ref) {
  throw UnimplementedError('Must be overridden');
});
```

`AppController` changes from:

```dart
AppController({required this.engine, ...})
```

To:

```dart
AppController({required this.engineFactory, ...}) {
  // engine created inside initialize() after model path is known
}
```

**Why this preserves swappability:**

- For `FakeInferenceEngine`: factory ignores the path, returns `FakeInferenceEngine()`
- For `FlutterGemmaEngine`: factory uses the path to construct the real engine
- For future `RemoteInferenceEngine`: factory ignores the path, returns API engine
- The `StructuredInferenceEngine<TutorResponse>` layer is unchanged
- `ConversationController` is unchanged - it still watches `structuredInferenceEngineProvider`

The `structuredInferenceEngineProvider` becomes a `StateProvider` or `AsyncNotifierProvider` that starts null and is populated by `AppController` after engine creation.

**Alternative (simpler, slightly less pure):** Keep `inferenceEngineProvider` but make it a `StateProvider<InferenceEngine?>` that `AppController` sets after initialization. Downstream providers watch it and handle the null/loading state.

**Key principle:** The engine strategy is a runtime decision, not a compile-time one. The provider graph should not force a specific engine at ProviderScope creation time.

**Files:** `lib/providers/inference_provider.dart`, `lib/providers/app_provider.dart`, `lib/services/app/app_controller.dart`, `lib/main.dart`

---

### Step 7 - Wire production mode in main.dart

```dart
const bool kUseFakeEngine = bool.fromEnvironment('FAKE_ENGINE', defaultValue: false);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  final repo = ConversationRepository();
  await repo.initialize();

  // One-time plugin initialization
  if (!kUseFakeEngine) {
    FlutterGemma.initialize();
  }

  runApp(
    ProviderScope(
      overrides: [
        engineFactoryProvider.overrideWithValue(
          kUseFakeEngine
              ? (_) => FakeInferenceEngine()
              : (path) => FlutterGemmaEngine(modelPath: path),
        ),
        conversationRepositoryProvider.overrideWithValue(repo),
      ],
      child: const FalaApp(),
    ),
  );
}
```

Build commands:
- Dev/test: `flutter run --dart-define=FAKE_ENGINE=true`
- Real device: `flutter run`

**Files:** `lib/main.dart`

---

### Step 8 - Smoke test on physical device

1. Install on device with >= 4 GB RAM (Qwen3 0.6B is smaller than Gemma)
2. Confirm model downloads via plugin (progress shows in UI)
3. Confirm `FlutterGemmaEngine.initialize()` transitions to `InferenceStatus.ready()`
4. Send a Portuguese message; confirm valid `TutorResponse` JSON is parsed
5. Send malformed prompt; confirm `StructuredParseFailure` surfaces gracefully

---

## File change summary

| File | Change |
|------|--------|
| `pubspec.yaml` | Add `flutter_gemma` |
| `AndroidManifest.xml` | Add `INTERNET` permission |
| `lib/config/model_config.dart` | Qwen3 0.6B URL and metadata |
| `lib/services/inference/flutter_gemma_engine.dart` | Full rewrite against current API |
| `lib/services/model/model_manager.dart` | Reduce scope; delegate download to plugin |
| `lib/screens/model_download/model_download_screen.dart` | Use plugin download callbacks |
| `lib/providers/inference_provider.dart` | Engine factory pattern |
| `lib/providers/app_provider.dart` | Wire factory into AppController |
| `lib/services/app/app_controller.dart` | Create engine internally via factory |
| `lib/main.dart` | Production/fake toggle via `--dart-define` |

---

## Architecture after changes

```
main.dart (ProviderScope)
  └── engineFactoryProvider: (path) => FlutterGemmaEngine | FakeEngine | RemoteEngine
        └── appControllerProvider
              └── AppController.initialize()
                    ├── ModelManager.getDownloadedModel() → path
                    ├── engineFactory(path) → engine instance
                    ├── engine.initialize()
                    └── sets structuredInferenceEngineProvider
                          └── ConversationController (watches this)
                                └── ConversationScreen
```

**Engine swappability preserved:** Adding a new engine (e.g., `RemoteInferenceEngine`, `MlcLlmEngine`) requires:
1. Implement `InferenceEngine` interface (~80 lines)
2. Add a new factory variant in `main.dart`
3. No changes to controllers, screens, or structured output pipeline

---

## Risk analysis (sanity check)

### Hardcoded model references that WILL BREAK

| File | Line | What | Fix |
|------|------|------|-----|
| `lib/services/app/app_controller.dart` | 38 | Default `modelName = 'gemma3-1b-it.task'` | Read from `ModelConfig.defaultModel.fileName` |
| `lib/screens/model_download/model_download_screen.dart` | 30-31 | Hardcoded placeholder URL + filename | Read from `ModelConfig.defaultModel` |
| `test/services/app_controller_test.dart` | 81, 95, 123 | Three `ModelMetadata(name: 'gemma3-1b-it.task')` fixtures | Use test constant or `ModelConfig.defaultModel.fileName` |

### Dead code / inconsistencies

| Issue | Location | Risk |
|-------|----------|------|
| `ModelConfig.defaultModel` is defined but **never used** | `lib/config/model_config.dart` | Low - but once fixed, it becomes the single source |
| `model_download_screen.dart` ignores `ModelConfig` entirely | Screen widget | Medium - bypasses the abstraction layer |
| `FlutterGemmaEngine` class name implies Gemma-only | `lib/services/inference/flutter_gemma_engine.dart` | Low - name is misleading but code is model-agnostic. Plugin is called flutter_gemma regardless of model |

### Format change: .task -> .litertlm

- flutter_gemma auto-selects engine based on extension (v0.12.3+): `.litertlm` -> LiteRT-LM, `.task` -> MediaPipe
- No code change needed beyond updating the filename string
- LiteRT-LM path supports GPU acceleration; MediaPipe (`.task`) does not support NPU
- GPU decode speed: 21 tokens/sec on Vivo X300 Pro (vs 9 tokens/sec CPU)

### Plugin version gap

- The stub was written against a pre-v0.5.0 API (`FlutterGemmaPlugin.instance.init(...)`)
- Current is v0.16.2 - completely different object hierarchy
- **All commented-out code in the stub is wrong and must be rewritten from scratch**
- The 3 reports each describe a different API variant (all partially outdated)

### Thinking mode risk (Qwen3-specific)

- Qwen3 models have a "thinking mode" that outputs `<think>...</think>` tags
- flutter_gemma strips these automatically (v0.13.5 fix)
- But for structured JSON output, it's safer to disable thinking: `isThinking: false`
- If thinking mode leaks `<think>` tags into the response, `JsonExtractor` would fail to parse
- Mitigation: Set `isThinking: false` explicitly in engine initialization

### ModelManager vs plugin download conflict

- Current `ModelManager` uses raw `HttpClient` for download
- flutter_gemma's built-in download uses `background_downloader` with Foreground Service
- Android kills background HTTP requests after ~9 minutes
- 614 MB download at typical mobile speed (~5 MB/s) = ~2 minutes -> safe either way
- But keeping both systems creates confusion about which manages the file
- **Recommendation:** Use plugin download, keep ModelManager only for file existence checks

### Provider graph restructuring

- Changing from `Provider<InferenceEngine>` to a factory/async pattern affects:
  - `app_provider.dart` (directly uses `inferenceEngineProvider`)
  - `inference_provider.dart` (defines the provider and `structuredInferenceEngineProvider`)
  - All tests that override `inferenceEngineProvider`
- `structuredInferenceEngineProvider` depends on `inferenceEngineProvider` - if the latter becomes async, the former must too
- **Safest approach:** Keep `inferenceEngineProvider` as `StateProvider<InferenceEngine?>`, let `AppController` set it after initialization, and make `structuredInferenceEngineProvider` handle the null case

### Functional specs alignment

- `docs/functional-specs.md` says: "flutter_gemma (swappable via InferenceEngine interface)"
- Model is described as "initial" and "to be evaluated" - not locked
- Switching to Qwen3 is **within spec**
- No spec violation

### Test impact

- `FakeInferenceEngine` and all tests above the engine layer: **unaffected**
- `app_controller_test.dart`: 3 fixtures need model name update (trivial)
- No tests exercise `FlutterGemmaEngine` directly (correct - on-device tests are manual)

---

## Execution order (dependencies)

```
Step 1 (add flutter_gemma) ← unblocks all other steps
Step 2 (INTERNET permission) ← independent
Step 3 (ModelConfig update) ← independent, but should happen before Step 4-7
Step 4 (plugin download) ← depends on Step 1, 3
Step 5 (FlutterGemmaEngine rewrite) ← depends on Step 1, 3
Step 6 (provider wiring) ← depends on Step 5
Step 7 (main.dart) ← depends on Step 6
Step 8 (smoke test) ← depends on all above
```

Steps 1-3 can be done in one commit. Steps 4-5 are independent of each other. Steps 6-7 depend on both.
