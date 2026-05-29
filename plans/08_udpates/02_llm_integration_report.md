# LLM Integration Report — fala

> **Date:** 2026-05-29  
> **Scope:** On-device Gemma integration; external API key migration analysis

---

## 1. Current State

### Architecture

The project has a clean, well-designed inference abstraction that is largely code-complete. The
layer stack is:

```
main.dart
  └── ProviderScope (overrides inferenceEngineProvider)
        └── AppController (checks model file, calls engine.initialize)
              └── StructuredInferenceEngine<TutorResponse>
                    ├── InferenceEngine (abstract interface)
                    │     ├── FakeInferenceEngine  ← current runtime
                    │     └── FlutterGemmaEngine   ← TODO stub
                    └── StructuredOutputParser<TutorResponse>
                          └── JsonExtractor (3-strategy JSON extraction)
```

Every layer from the interface inward is fully implemented and tested. The
`InferenceEngine` contract is deliberately minimal (string prompt → string
response), and the structured output pipeline on top of it is generic and
decoupled.

### What is actually working

| Component | Status | Notes |
|-----------|--------|-------|
| `InferenceEngine` interface | ✅ Complete | Sealed result types, status stream |
| `FakeInferenceEngine` | ✅ Complete | Used in all tests and current `main.dart` |
| `StructuredInferenceEngine<T>` | ✅ Complete | Timeout, logging, three-state result |
| `StructuredOutputParser<T>` | ✅ Complete | Generic, works with any `fromJson` |
| `JsonExtractor` | ✅ Complete | 3 strategies: pure JSON, code block, substring |
| `ModelManager` | ✅ Complete | Download, progress, cleanup, path resolution |
| `ModelConfig.defaultModel` | ✅ Complete | Points to Gemma 3 1B `.task` on Hugging Face |
| `FlutterGemmaEngine` | ⚠️ Stub | File exists, all SDK calls are `// TODO` comments |
| `flutter_gemma` dependency | ❌ Missing | Not in `pubspec.yaml` or `pubspec.lock` |
| `INTERNET` permission (release) | ❌ Missing | Only declared in `debug/AndroidManifest.xml` |
| `main.dart` production override | ❌ Missing | Still wires `FakeInferenceEngine` unconditionally |

### Discrepancy between tracking and code

`plans/00_tracking.md` marks `04_core_systems/02_flutter_gemma_engine.md` as **complete**, but the
actual file `lib/services/inference/flutter_gemma_engine.dart` contains only stub code with every
SDK call commented out. The plan was executed at the *scaffold/interface* level, not at the
*integration* level. This is the main outstanding gap.

---

## 2. Getting Gemma Working — Precise Steps

### Step 1 — Add `flutter_gemma` to `pubspec.yaml`

```yaml
dependencies:
  flutter_gemma:   # add this line
```

Then run:

```bash
flutter pub get
```

As of May 2026, `flutter_gemma` supports `.task` (MediaPipe format) and `.litertlm` (LiteRT-LM
format). The current `ModelConfig.defaultModel` points to a `.task` file, which is compatible.

> **Model choice note:** The plan docs discuss both `Gemma 3 1B` and `Qwen3 0.6B` as candidates.
> `flutter_gemma` supports both. The default config is set to Gemma 3 1B — stick with this for the
> smoothest integration since Google controls both the model format and the inference runtime.
> Switching to Qwen3 0.6B later is a one-line change in `ModelConfig`.

### Step 2 — Wire real SDK calls in `FlutterGemmaEngine`

Replace the TODO stubs in `lib/services/inference/flutter_gemma_engine.dart`:

```dart
import 'package:flutter_gemma/flutter_gemma.dart';   // add this import

// In initialize():
await FlutterGemmaPlugin.instance.init(
  maxTokens: 1024,
  modelPath: modelPath,
  // temperature: 0.7,  // optional
);

// In generate():
final response = await FlutterGemmaPlugin.instance.getResponse(
  prompt: request.prompt,
);

// In dispose():
await FlutterGemmaPlugin.instance.close();
```

> **API caveat:** `flutter_gemma`'s Dart API surface has evolved across versions. The exact method
> names above reflect the `0.x` API as documented in the package README — verify against the
> version you resolve in `pub get`. The general shape (init, getResponse/generateAsync, close) is
> stable.

### Step 3 — Add `INTERNET` permission to the main `AndroidManifest.xml`

`android/app/src/main/AndroidManifest.xml` currently has no `INTERNET` permission. The model
download (`ModelManager.downloadModel`) requires it. Add inside `<manifest>`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

Without this, the app will silently fail on release builds when the user tries to download the
model (the permission is only present in the debug manifest).

### Step 4 — Replace `FakeInferenceEngine` in `main.dart`

`main.dart` currently hard-wires the fake engine:

```dart
// Current (line ~22):
inferenceEngineProvider.overrideWithValue(FakeInferenceEngine()),
```

This needs to become a conditional that checks whether the model is already on disk:

```dart
import 'services/inference/flutter_gemma_engine.dart';

// In main():
final modelManager = ModelManager();
final existingModel = await modelManager.getDownloadedModel(
  ModelConfig.defaultModel.fileName,
);

final engine = existingModel != null
    ? FlutterGemmaEngine(modelPath: existingModel.filePath)
    : FakeInferenceEngine(); // AppController will redirect to download screen anyway
```

Then pass `engine` into the `ProviderScope` override as before. When `AppController.initialize()`
runs, it will call `engine.initialize()`, which triggers LiteRT model loading.

> `AppController` already handles the `AppNeedsModel` → redirect-to-download-screen flow.
> `skipModelCheck` is correctly set to `true` only when `engine is FakeInferenceEngine`, so the
> routing logic does not need changes.

### Step 5 — Verify checksum (recommended, not blocking)

`ModelManager.downloadModel` has a `// TODO: Verify checksum if provided` comment. The
`ModelConfig.defaultModel` does not set `expectedChecksum`. For a Play Store alpha, this is
acceptable. Before a public release, add the SHA-256 of the `.task` file from Hugging Face and
wire the verification — a corrupted 1.5 GB download is a bad first-launch experience.

### Step 6 — Smoke test on a physical device

Automated tests cannot run with a real model. The acceptance path is:

1. Install on a device with ≥ 8 GB RAM (Snapdragon 8 Gen 1 or newer).
2. Confirm model downloads and `ModelManager` emits `DownloadComplete`.
3. Confirm `FlutterGemmaEngine.initialize()` transitions to `InferenceStatus.ready()`.
4. Send a Portuguese message; confirm a valid `TutorResponse` JSON is parsed.
5. Send a deliberately malformed prompt; confirm `StructuredParseFailure` surfaces gracefully.

### Summary of blockers

| # | What | Where | Effort |
|---|------|-------|--------|
| 1 | Add `flutter_gemma` to `pubspec.yaml` | `pubspec.yaml` | 5 min |
| 2 | Implement SDK calls in `FlutterGemmaEngine` | `flutter_gemma_engine.dart` | ~1 h |
| 3 | Add `INTERNET` permission to release manifest | `AndroidManifest.xml` | 5 min |
| 4 | Wire `FlutterGemmaEngine` in `main.dart` | `main.dart` | ~30 min |
| 5 | Physical device smoke test | — | ~2 h |

Total to a running Gemma on a real device: **roughly half a day of work**, assuming no SDK API
surprises.

---

## 3. Migrating to an External API Provider

### Effort assessment

**Difficulty: Low on the Dart side; the real challenge is key distribution.**

The `InferenceEngine` interface was explicitly designed for this. Adding an
`ApiInferenceEngine` is mechanical: implement three methods (`initialize`, `generate`, `dispose`),
make HTTP calls to the provider's endpoint, parse the response into `InferenceSuccess`. The
`StructuredInferenceEngine<T>` layer, the `StructuredOutputParser`, the routing, the screens —
none of that changes.

Estimated Dart implementation time: **2–4 hours** (plus whatever quirks the provider's SDK has).

The hard part is keeping the API key out of the APK.

### Why you cannot hardcode the key

A Flutter release APK is a ZIP archive. The compiled Dart code lives inside it in a binary
format (`libapp.so`), but strings — including API keys — are often recoverable via simple binary
search or decompilation tools. Even with `isMinifyEnabled = true` and ProGuard, a static key
embedded in source code is not safe to ship in a public binary.

### Option A — User-provided key (simplest, zero infrastructure)

The user enters their own API key for Gemini/OpenAI/etc. in a settings screen. The key is stored
in `flutter_secure_storage` (uses Android Keystore under the hood), never in Hive or plain
SharedPreferences.

```
User flow: Settings → "Enter your API key" → SecureStorage.write(key, value)
ApiInferenceEngine: reads key from SecureStorage at initialize()
```

**Pros:** no backend needed, no key distribution problem, you bear zero API cost.  
**Cons:** friction for non-technical users, support overhead when keys expire or are mistyped.  
**Best for:** a developer-facing or power-user product.

### Option B — Your own backend proxy (recommended for consumer app)

You host a thin API server (one FastAPI endpoint, given your stack). The app sends the prompt to
your server; your server forwards to the LLM provider using a server-side key; your server returns
the response. The app authenticates to *your* server, not to the LLM provider directly.

```
Flutter app  →  POST /infer (with app token)  →  your FastAPI
                                                    └→  Gemini/OpenAI API (server-side key)
```

App authentication options (weakest → strongest):

| Method | Description | Appropriate for |
|--------|-------------|-----------------|
| Shared secret | Hardcoded token in app, verified server-side | Internal/alpha only |
| Play Integrity API | Google-attested proof that the request comes from an unmodified Play Store build | Public release |
| Firebase App Check | Wraps Play Integrity + SafetyNet; integrates with Firebase | If already using Firebase |
| User accounts | Per-user tokens (JWT, OAuth) | If you have user accounts |

For a Play Store app with no user accounts, **Play Integrity API** is the right tool: it lets your
server reject requests that don't come from a genuine, unmodified install of your app, which
significantly raises the bar for key abuse.

**Pros:** you control costs, can add rate limiting, can add caching, key never leaves your server.  
**Cons:** you run infrastructure, you pay for API calls, you now have a backend to maintain.  
**Best for:** a production consumer app.

### Option C — Offline-first with API as fallback

Keep the on-device path as primary and add an API fallback for devices that fail the hardware
check (< 6 GB RAM). This is the best UX: most users get the offline experience; low-end users get
a degraded-but-functional cloud path.

```dart
final engine = deviceMeetsHardwareRequirements()
    ? FlutterGemmaEngine(modelPath: path)
    : ApiInferenceEngine(endpoint: 'https://api.yourserver.com/infer');
```

The `InferenceEngine` interface makes this a one-liner swap. The rest of the app is unaware.

### Implementation sketch for `ApiInferenceEngine`

```dart
class ApiInferenceEngine implements InferenceEngine {
  ApiInferenceEngine({required this.apiEndpoint, required this.authToken});

  final String apiEndpoint;
  final String authToken;
  // ... status stream boilerplate (same pattern as FlutterGemmaEngine) ...

  @override
  Future<void> initialize() async {
    // Validate connectivity, token, etc.
    _setStatus(const InferenceStatus.ready());
  }

  @override
  Future<InferenceResult> generate(InferenceRequest request) async {
    _setStatus(const InferenceStatus.generating());
    try {
      final response = await http.post(
        Uri.parse('$apiEndpoint/infer'),
        headers: {'Authorization': 'Bearer $authToken', 'Content-Type': 'application/json'},
        body: jsonEncode({'prompt': request.prompt, 'max_tokens': request.maxTokens}),
      );
      if (response.statusCode != 200) {
        return InferenceFailure(error: 'HTTP ${response.statusCode}');
      }
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      _setStatus(const InferenceStatus.ready());
      return InferenceSuccess(rawText: json['text'] as String);
    } on Exception catch (e) {
      _setStatus(const InferenceStatus.ready());
      return InferenceFailure(error: e.toString());
    }
  }
}
```

The `StructuredInferenceEngine<TutorResponse>` wrapping this is identical to the Gemma case —
zero changes needed above this layer.

### Key distribution: do not do these things

| Approach | Why not |
|----------|---------|
| Hardcode key in Dart source | Extractable from APK with minimal effort |
| Store in `assets/` folder | Plain text in the APK |
| Store in Hive or SharedPreferences | Readable on rooted devices |
| Obfuscate with base64 / ROT13 | Security through obscurity; trivially reversed |
| Store in `.env` via `flutter_dotenv` | `.env` is bundled in the APK's assets — same as `assets/` |

`flutter_secure_storage` (for user-provided keys) and a server-side proxy (for your own key) are
the two architecturally sound options.

---

## 4. Recommendation

For the immediate goal (Play Store alpha):

1. **Ship with on-device Gemma.** Complete the 5 steps in section 2. The architecture is nearly
   finished — the remaining work is purely mechanical wiring of the `flutter_gemma` SDK.

2. **Defer the external API question.** The `InferenceEngine` interface means this decision is
   reversible with no architectural cost. You are not locked in.

3. **If you later add an API path**, use the backend proxy model (Option B) with Play Integrity
   attestation for a consumer app, or user-provided keys (Option A) if targeting developers. Do
   not try to distribute a hardcoded key safely — there is no safe way to do it.
