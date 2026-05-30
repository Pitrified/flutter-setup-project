---
status: complete
depends_on: [03_scaffold/02_generated_models.md]
produces: [lib/services/inference/inference_engine.dart]
---

# Plan: InferenceEngine Abstract Interface

## Goal

Define the abstract contract that all LLM inference backends must satisfy.
This interface is the stable boundary between app logic and the underlying SDK.
Designed to be minimal (common denominator) so that swapping from flutter_gemma
to MLC-LLM or LiteRT-LM requires only a new implementation, not app changes.

## Interface design

`lib/services/inference/inference_engine.dart`:

```dart
import '../../models/inference_status.dart';
import '../../models/tutor_response.dart';

/// Configuration for a single inference call.
class InferenceRequest {
  const InferenceRequest({
    required this.prompt,
    this.maxTokens = 512,
    this.temperature = 0.7,
    this.topK = 40,
  });

  final String prompt;
  final int maxTokens;
  final double temperature;
  final int topK;
}

/// Result of an inference call.
sealed class InferenceResult {
  const InferenceResult();
}

class InferenceSuccess extends InferenceResult {
  const InferenceSuccess({required this.rawText, this.tutorResponse});

  final String rawText;
  final TutorResponse? tutorResponse;
}

class InferenceFailure extends InferenceResult {
  const InferenceFailure({required this.error});

  final String error;
}

/// Abstract interface for on-device LLM inference.
///
/// All backends (FakeInferenceEngine, FlutterGemmaEngine, etc.) implement this.
/// App code interacts only with this interface via Riverpod providers.
abstract class InferenceEngine {
  /// Current status of the engine.
  InferenceStatus get status;

  /// Stream of status changes for reactive UI updates.
  Stream<InferenceStatus> get statusStream;

  /// Initialize the engine (load model weights, warm up).
  ///
  /// Must be called before [generate]. Can be called only once.
  /// Transitions status: uninitialized -> loading -> ready (or error).
  Future<void> initialize();

  /// Generate a response given a prompt.
  ///
  /// Returns structured output if parsing succeeds, raw text otherwise.
  /// Transitions status: ready -> generating -> ready.
  Future<InferenceResult> generate(InferenceRequest request);

  /// Whether the engine is ready to accept inference requests.
  bool get isReady;

  /// Release all resources (model memory, GPU handles).
  ///
  /// After dispose, the engine cannot be reused.
  Future<void> dispose();
}
```

## Design decisions

- **Sealed result type**: `InferenceResult` uses sealed class for exhaustive matching
  (success with optional parsed response, or failure with error message).
- **Status stream**: enables reactive UI without polling.
- **No `predictStructured` method**: structured output is handled by the validation
  pipeline (Plan 03_structured_output.md), not the engine itself. The engine returns
  raw text; the pipeline parses it. This keeps engine implementations simple.
- **No streaming**: initial version returns complete response. Streaming can be added
  later as an optional method without breaking existing code.
- **Temperature/topK in request**: per-call configuration, not per-engine.

## Provider setup

```dart
// lib/providers/inference_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/inference/inference_engine.dart';

/// Provider for the active inference engine.
///
/// Override this in tests with FakeInferenceEngine.
/// Override in production with FlutterGemmaEngine.
final inferenceEngineProvider = Provider<InferenceEngine>((ref) {
  throw UnimplementedError(
    'inferenceEngineProvider must be overridden with a concrete implementation',
  );
});
```

## Tests

- Verify the interface compiles (trivial, but validates the sealed class pattern).
- No logic to test at this stage - tests will be in the concrete implementations.

## Acceptance criteria

- [ ] `InferenceEngine` abstract class exists at the specified path
- [ ] `InferenceRequest`, `InferenceResult` (sealed), `InferenceSuccess`, `InferenceFailure` defined
- [ ] `inferenceEngineProvider` exists and throws if not overridden
- [ ] `flutter analyze` passes
- [ ] No imports of any concrete SDK (flutter_gemma, etc.) in this file
