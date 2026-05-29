# fala — LLM Integration Report

_Analysis of the `flutter-setup-project-main` codebase, May 2026_

---

## Executive Summary

The project has a surprisingly mature architecture for something whose README says "no code exists yet." The inference abstraction layer, structured output pipeline, persistence, navigation, and all three screens are implemented and wired. The **only missing piece for on-device Gemma** is uncommenting about 10 lines of SDK calls, adding one package to `pubspec.yaml`, and fixing three wiring gaps. Migrating to an external API provider is architecturally trivial (the interface was designed for exactly this) but has a meaningful key-distribution problem that needs a deliberate decision.

---

## 1. Current State

### What is actually built

The architecture has been fully realised ahead of the plans' stated statuses (most plans still say `not-started` but the code disagrees):

| Component | Status | Notes |
|---|---|---|
| `InferenceEngine` interface | ✅ Complete | Text-in / text-out sealed result types |
| `FakeInferenceEngine` | ✅ Complete | Fixture-based, cycles through `tutor_responses.json` |
| `FlutterGemmaEngine` | ⚠️ Stub | Class exists, SDK calls are all `// TODO` comments |
| `StructuredInferenceEngine<T>` | ✅ Complete | Composes engine + parser, timeout, 3-state result |
| `StructuredOutputParser<T>` | ✅ Complete | Generic, `fromJson` factory, delegates to `JsonExtractor` |
| `JsonExtractor` | ✅ Complete | Three fallback strategies (direct, code block, substring) |
| `ModelManager` | ✅ Complete | Download with streaming progress, cleanup on failure |
| `ConversationController` | ✅ Complete | Full conversation loop, history trimming, 3-state switch |
| `AppController` | ✅ Complete | App lifecycle, model check, engine init, state stream |
| All three screens | ✅ Complete | Welcome, ModelDownload, Conversation |
| GoRouter + redirects | ✅ Complete | State-driven routing in `app.dart` |
| Hive persistence | ✅ Complete | `ConversationRepository` with `initialize()` |
| Prompt system | ✅ Complete | Template v1 with variable interpolation |
| `TutorResponse` schema | ✅ Complete | JSON schema file + Dart model |

### What is genuinely missing

1. `flutter_gemma` is **not in `pubspec.yaml`** — the package has never been added.
2. `FlutterGemmaEngine.initialize()` and `generate()` contain commented-out SDK calls.
3. `model_download_screen.dart` uses `'https://placeholder.example.com/gemma3-1b-it.task'` — a dead URL.
4. `main.dart` hardcodes `FakeInferenceEngine` as the override; no production override exists.
5. `INTERNET` permission is missing from `AndroidManifest.xml` — required for model download.
6. A **provider wiring gap** exists between `AppController` (knows model path after detection) and `FlutterGemmaEngine` (needs model path at construction time).

---

## 2. Getting Gemma Working — Precisely

The work splits into six focused steps. In order:

### Step 1 — Add the package

```yaml
# pubspec.yaml, under dependencies:
flutter_gemma: ^0.2.3   # check pub.dev for latest
```

```bash
flutter pub get
```

### Step 2 — Add INTERNET permission

```xml
<!-- android/app/src/main/AndroidManifest.xml, inside <manifest> -->
<uses-permission android:name="android.permission.INTERNET"/>
```

Without this, both the model download and any future remote calls will silently fail on Android.

### Step 3 — Fix the model download URL

`model_download_screen.dart` uses a placeholder URL. Change it to use the constant that already exists in `model_config.dart`:

```dart
// lib/screens/model_download/model_download_screen.dart
// BEFORE:
await modelManager.downloadModel(
  url: 'https://placeholder.example.com/gemma3-1b-it.task',
  fileName: 'gemma3-1b-it.task',
);

// AFTER:
await modelManager.downloadModel(
  url: ModelConfig.defaultModel.downloadUrl,
  fileName: ModelConfig.defaultModel.fileName,
);
```

`ModelConfig.defaultModel` already points to the correct HuggingFace URL:
`https://huggingface.co/litert-community/Gemma3-1B-IT/resolve/main/model.task`

### Step 4 — Implement `FlutterGemmaEngine`

The current flutter_gemma API (v0.2+) differs slightly from the commented-out stub. Here is the correct implementation:

```dart
// lib/services/inference/flutter_gemma_engine.dart
import 'dart:async';

import 'package:flutter_gemma/flutter_gemma.dart';

import '../../models/inference_status.dart';
import 'inference_engine.dart';

class FlutterGemmaEngine implements InferenceEngine {
  FlutterGemmaEngine({required this.modelPath});

  final String modelPath;
  final _statusController = StreamController<InferenceStatus>.broadcast();
  InferenceStatus _status = const InferenceStatus.uninitialized();

  @override
  InferenceStatus get status => _status;

  @override
  Stream<InferenceStatus> get statusStream => _statusController.stream;

  @override
  bool get isReady => _status == const InferenceStatus.ready();

  @override
  Future<void> initialize() async {
    _setStatus(const InferenceStatus.loading());
    try {
      await FlutterGemmaPlugin.instance.init(
        modelPath: modelPath,
        maxTokens: 1024,
        temperature: 0.7,
        topK: 40,
      );
      _setStatus(const InferenceStatus.ready());
    } on Exception catch (e) {
      _setStatus(InferenceStatus.error(e.toString()));
    }
  }

  @override
  Future<InferenceResult> generate(InferenceRequest request) async {
    if (!isReady) {
      return const InferenceFailure(error: 'Engine not initialized');
    }

    _setStatus(const InferenceStatus.generating());
    try {
      // flutter_gemma returns a stream of token strings; collect them.
      final buffer = StringBuffer();
      await for (final token in FlutterGemmaPlugin.instance
          .getResponseAsync(prompt: request.prompt)) {
        if (token != null) buffer.write(token);
      }
      _setStatus(const InferenceStatus.ready());
      return InferenceSuccess(rawText: buffer.toString());
    } on Exception catch (e) {
      _setStatus(const InferenceStatus.ready());
      return InferenceFailure(error: e.toString());
    }
  }

  @override
  Future<void> dispose() async {
    await FlutterGemmaPlugin.instance.close();
    _setStatus(const InferenceStatus.disposed());
    await _statusController.close();
  }

  void _setStatus(InferenceStatus s) {
    _status = s;
    _statusController.add(s);
  }
}
```

> **API note:** `flutter_gemma` has been changing rapidly. The exact method names (`init`, `getResponseAsync`) should be verified against the version you install. The streaming approach above is the pattern for v0.2+; older versions used `getResponse` (non-streaming). Check the package changelog on pub.dev after adding it.

### Step 5 — Fix the provider wiring gap

This is the subtlest problem. `FlutterGemmaEngine` needs a `modelPath` at construction time, but that path only exists after `ModelManager` has confirmed the file. The current `AppController` holds both `modelManager` and `engine`, but `engine` is injected from outside — meaning the Riverpod override in `main.dart` would need to know the path before the app starts, which it can't.

The clean fix: make `AppController` responsible for creating `FlutterGemmaEngine` **after** detecting the model path. This changes the provider pattern from injecting a ready-made engine to injecting a factory:

```dart
// lib/providers/service_providers.dart — add:
final flutterGemmaEngineFactoryProvider =
    Provider<FlutterGemmaEngine Function(String)>((ref) {
  return (modelPath) => FlutterGemmaEngine(modelPath: modelPath);
});
```

Then in `AppController.initialize()`:

```dart
// After confirming model exists:
final engine = engineFactory(modelInfo.filePath);
await engine.initialize().timeout(const Duration(seconds: 10));
```

Alternatively (simpler if you don't need the engine in the provider graph): just instantiate `FlutterGemmaEngine` directly inside `AppController.initialize()` and store it as a field, removing the injected `engine` parameter entirely.

### Step 6 — Wire production mode in `main.dart`

Currently `main.dart` always uses `FakeInferenceEngine`. For a real build, either use a compile-time flag or a simple const:

```dart
// Option A: compile-time constant
const bool kUseFakeEngine = bool.fromEnvironment('FAKE_ENGINE', defaultValue: false);

runApp(
  ProviderScope(
    overrides: [
      if (kUseFakeEngine)
        inferenceEngineProvider.overrideWithValue(FakeInferenceEngine()),
      // FlutterGemmaEngine is now created inside AppController,
      // so no override needed here for the real path.
      conversationRepositoryProvider.overrideWithValue(repo),
    ],
    child: const FalaApp(),
  ),
);
```

Build with fake engine: `flutter run --dart-define=FAKE_ENGINE=true`  
Build for real: `flutter run` (no flag)

### Summary of changes

| File | Change |
|---|---|
| `pubspec.yaml` | Add `flutter_gemma` |
| `AndroidManifest.xml` | Add `INTERNET` permission |
| `model_download_screen.dart` | Use `ModelConfig.defaultModel` URL |
| `flutter_gemma_engine.dart` | Implement `initialize()`, `generate()`, `dispose()` |
| `service_providers.dart` | Add engine factory provider (or restructure AppController) |
| `main.dart` | Remove hardcoded FakeInferenceEngine for production builds |

---

## 3. Migrating to an External API Provider

### Architectural effort: low

The `InferenceEngine` interface is the exact right seam for this. A `RemoteInferenceEngine` implementing the interface would be ~80 lines of Dart:

```dart
class RemoteInferenceEngine implements InferenceEngine {
  RemoteInferenceEngine({required this.apiKey, required this.baseUrl});

  final String apiKey;
  final String baseUrl;
  // ...

  @override
  Future<InferenceResult> generate(InferenceRequest request) async {
    final response = await http.post(
      Uri.parse('$baseUrl/v1/chat/completions'),
      headers: {'Authorization': 'Bearer $apiKey', 'Content-Type': 'application/json'},
      body: jsonEncode({/* provider-specific payload */}),
    );
    // parse response → InferenceSuccess / InferenceFailure
  }
}
```

What you would also remove: `ModelManager`, the model download screen, and the `AppNeedsModel` state — the app would start immediately without any local model. The rest of the stack (`StructuredInferenceEngine`, `ConversationController`, `JsonExtractor`, `PromptManager`) stays completely unchanged.

You'd add: the `http` or `dio` package, streaming support (most providers stream tokens), and error handling for rate limits and network failures.

**Effort estimate:** 1–2 days for a working implementation, 1 extra day for streaming UX.

### The hard problem: key distribution

This is where it gets genuinely difficult. An API key embedded in an Android APK is extractable — APKs are zip files, and with a disassembler or string search on the native binary you can pull it out. Obfuscation (`isMinifyEnabled = true` is already set) slows this down but does not prevent it.

There are four realistic options:

---

#### Option A — User supplies their own key (recommended for alpha)

The user pastes their own Gemini/OpenAI/Groq API key into the app settings. You never touch a key.

**Pros:** Zero cost to you. No secret to protect. No backend to run. Trivially secure because each key is the user's own property.

**Cons:** Significant onboarding friction. Only works for a technically-literate audience willing to create an API account.

**Implementation:** Add a settings screen with a `SecureStorage` field (using `flutter_secure_storage`, which uses Android Keystore). Read the key in `RemoteInferenceEngine`.

**When to use:** Private alpha, developer testing, power-user products.

---

#### Option B — Your own proxy backend (recommended for production)

You run a small backend (a single FastAPI endpoint on your homelab or a cheap VPS). The app sends prompts to *your* endpoint, which forwards them to the real provider using your key stored server-side. You authenticate app→backend separately (e.g., a static app-level token, Firebase Auth, or anonymous attestation).

```
[fala app] → POST /v1/generate (with app token) → [your proxy] → [Gemini/OpenAI API]
```

**Pros:** Your API key never leaves the server. Full control over rate limiting, logging, cost caps, abuse prevention.

**Cons:** You pay for all inference. You now have a backend to maintain. App is no longer fully offline. Need to authenticate the app→proxy hop somehow.

**For key distribution of the app→proxy token:** A static token embedded in the app is still extractable, but it's your token to a proxy you control — you can rotate it, rate-limit by device, or invalidate it without touching the upstream provider key. This is materially better than embedding a direct provider key.

**When to use:** When you're paying for inference centrally and distributing to many users. Essentially the SaaS model.

---

#### Option C — App Attestation (best security, highest complexity)

Google Play Integrity API (Android) lets your backend verify that a request comes from a genuine, unmodified copy of your app. Combined with a proxy backend, this prevents even an extracted proxy token from being reused outside of the real app.

**Pros:** Meaningfully harder to abuse.  
**Cons:** Requires a proper backend, Google Cloud setup, and significant implementation effort. Overkill for alpha.

---

#### Option D — Hardcoded/build-time key (not recommended)

Embed the key as a `--dart-define` build secret. It ends up in the binary. Obfuscation slows extraction but doesn't prevent it for a motivated person.

**Acceptable for:** Internal testing builds where the app is never distributed.  
**Not acceptable for:** Any public Play Store release, even internal track — the APK is downloadable.

---

### Decision matrix

| Scenario | Recommended approach |
|---|---|
| Private alpha, technical users | Option A (user-supplied key) |
| Private alpha, non-technical users | Option B (proxy, static app token) |
| Public release you're paying for | Option B + Option C (proxy + attestation) |
| You never want a backend | Option A only |

---

### What stays the same

Everything above `InferenceEngine` is backend-agnostic. `StructuredOutputParser`, `ConversationController`, `PromptManager`, the screens, and the Riverpod graph all work identically whether the engine is on-device Gemma or a remote API call. The architectural investment in the interface pays off completely here — you swap the provider override in `main.dart` and nothing else changes.

---

## 4. Recommended Next Steps

In order of priority:

1. **Add `flutter_gemma` to pubspec.yaml** and run `pub get`. This unblocks everything else.
2. **Add `INTERNET` permission** to the manifest — needed for the model download that already exists.
3. **Fix the placeholder URL** in `model_download_screen.dart`.
4. **Implement `FlutterGemmaEngine`** (Step 4 above) and verify on a physical device with the Gemma 3 1B model.
5. **Decide on external provider strategy** before any public distribution — Option A is zero-effort for alpha, Option B is the right long-term answer if you're ever paying for inference centrally.
6. **Update plan statuses** — many plans say `not-started` but the code is done; the `07_decouple_structured_output.md` has it right (marked `complete`). Keeping statuses accurate helps with AI-assisted development.
