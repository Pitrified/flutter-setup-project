---
status: complete
depends_on: [04_core_systems/00_inference_interface.md, 04_core_systems/05_model_manager.md]
produces: [lib/services/inference/flutter_gemma_engine.dart]
---

# Plan: FlutterGemmaEngine

## Goal

Implement the InferenceEngine interface using flutter_gemma (or the current best
on-device LLM package for Flutter/Android). This is the production backend that
loads a real model and performs inference on the device GPU/NPU.

## Implementation

`lib/services/inference/flutter_gemma_engine.dart`:

```dart
import 'dart:async';

import '../../models/inference_status.dart';
import '../../models/tutor_response.dart';
import 'inference_engine.dart';

/// Production inference engine using flutter_gemma.
///
/// Loads a real model file from device storage and performs on-device inference.
/// Requires a downloaded model file (see ModelManager).
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
      // TODO: Initialize flutter_gemma with model file
      // await FlutterGemmaPlugin.instance.init(
      //   maxTokens: 1024,
      //   modelPath: modelPath,
      // );
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
      // TODO: Call flutter_gemma inference
      // final response = await FlutterGemmaPlugin.instance.getResponse(
      //   prompt: request.prompt,
      // );
      const response = ''; // placeholder

      _setStatus(const InferenceStatus.ready());
      return InferenceSuccess(rawText: response);
    } on Exception catch (e) {
      _setStatus(const InferenceStatus.ready());
      return InferenceFailure(error: e.toString());
    }
  }

  @override
  Future<void> dispose() async {
    // TODO: Release flutter_gemma resources
    _setStatus(const InferenceStatus.disposed());
    await _statusController.close();
  }

  void _setStatus(InferenceStatus newStatus) {
    _status = newStatus;
    _statusController.add(newStatus);
  }
}
```

## Key considerations

### SDK selection

flutter_gemma is the initial target, but it may be replaced by:
- **google_generative_ai** (if it adds on-device support)
- **mediapipe_genai** (Dart bindings for MediaPipe LLM Inference)
- **litert_lm** (if/when a Flutter package emerges)

The interface isolates this decision completely.

### Model path

The engine receives the model file path from ModelManager (Plan 05).
It does NOT handle downloading or locating the model.

### Constrained decoding

If the SDK supports constrained decoding (grammar-guided generation):
- Configure it to output valid JSON matching TutorResponse schema
- This eliminates the need for post-hoc parsing in most cases

If not supported:
- Return raw text, let the structured output pipeline (Plan 03) parse it
- Accept higher failure rate on malformed output

### Memory management

- Model weights are ~500MB-2GB in RAM
- Engine should be initialized once and kept alive for the session
- dispose() must reliably free all GPU/NPU memory
- App lifecycle management (pause/resume) may need model unloading

### Error handling

- Model file not found -> InferenceStatus.error
- Out of memory -> InferenceStatus.error with descriptive message
- Inference timeout -> InferenceFailure result (not a status change)
- Corrupted model -> fail at initialize(), not at generate()

## Testing strategy

- Cannot unit test with a real model (too large, too slow)
- Integration test on a real device (manual) with a small model
- Verify initialize/dispose lifecycle without a model (mock the SDK)
- The FakeInferenceEngine handles all automated testing needs

## Acceptance criteria

- [ ] FlutterGemmaEngine implements InferenceEngine
- [ ] Compiles without errors (TODO comments for SDK calls)
- [ ] Status transitions match the contract
- [ ] Error handling covers all failure modes
- [ ] No direct SDK imports leak into other app code
- [ ] `flutter analyze` passes
- [ ] Documented as a TODO stub until real SDK is wired
