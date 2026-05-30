# InferenceEngine

> System spec for `lib/services/inference/inference_engine.dart`

## Purpose

Abstract interface for on-device LLM inference. All backends implement this
contract. App code interacts only with this interface via providers; the concrete
implementation is selected at startup through the engine factory.

## Interface definition

```dart
abstract class InferenceEngine {
  InferenceStatus get status;
  Stream<InferenceStatus> get statusStream;
  bool get isReady;
  Future<void> initialize();
  Future<InferenceResult> generate(InferenceRequest request);
  Future<void> dispose();
}
```

## Request model

`InferenceRequest` - configuration for a single inference call:

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `prompt` | `String` | required | The full prompt text |
| `maxTokens` | `int` | 512 | Max tokens to generate |
| `temperature` | `double` | 0.7 | Sampling temperature |
| `topK` | `int` | 40 | Top-K sampling |

## Result model

`InferenceResult` is a sealed class:

| Subtype | Fields | Meaning |
|---------|--------|---------|
| `InferenceSuccess` | `rawText: String` | Generation succeeded |
| `InferenceFailure` | `error: String` | Generation failed |

## Status lifecycle

```
uninitialized -> loading -> ready -> generating -> ready
                         -> error
                                                -> disposed
```

`InferenceStatus` (freezed union):
`uninitialized`, `loading`, `ready`, `generating`, `error(String)`, `disposed`

## Implementations

| Class | File | Use case |
|-------|------|----------|
| `FlutterGemmaEngine` | `flutter_gemma_engine.dart` | Production on-device inference |
| `FakeInferenceEngine` | `fake_inference_engine.dart` | Tests and dev builds |

## Provider

`inferenceEngineProvider` in `lib/providers/inference_provider.dart`:

- `NotifierProvider<InferenceEngineNotifier, InferenceEngine?>`
- Initially null; set by `AppController.onEngineReady` callback.
- `engineFactoryProvider` (must be overridden at ProviderScope) selects which implementation to construct.
