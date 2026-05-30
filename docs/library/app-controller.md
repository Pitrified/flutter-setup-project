# AppController

> System spec for `lib/services/app/app_controller.dart`

## Purpose

Controls top-level application lifecycle. Checks model availability, initializes
the inference engine, and exposes reactive state for the router to decide
navigation (loading screen, download screen, or conversation screen).

## State machine

```
AppLoading -> AppNeedsModel   (model not found)
AppLoading -> AppReady        (engine initialized)
AppLoading -> AppError        (init timeout or failure)
```

`AppState` is a sealed class with four subtypes:

| State | Meaning |
|-------|---------|
| `AppLoading` | Initialization in progress |
| `AppNeedsModel` | Model file not available on device |
| `AppReady` | Engine initialized, model info available |
| `AppError` | Something failed (message field) |

## Constructor parameters

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `engineFactory` | `InferenceEngine Function(String)` | yes | Factory to create engine from model path |
| `onEngineReady` | `void Function(InferenceEngine)` | yes | Callback fired when engine reaches ready state |
| `modelChecker` | `Future<bool> Function()` | yes | Checks if model file exists on device |
| `modelName` | `String` | no | Defaults to `ModelConfig.defaultModelFileName` |
| `skipModelCheck` | `bool` | no | Bypass model verification (for FakeInferenceEngine) |

## Public API

| Method | Signature | Description |
|--------|-----------|-------------|
| `state` | `AppState get state` | Current state (synchronous read) |
| `stateStream` | `Stream<AppState> get stateStream` | Broadcast stream of state changes |
| `initialize()` | `Future<void>` | Run init sequence: check model, create engine, call onEngineReady |
| `onModelDownloaded()` | `Future<void>` | Re-trigger initialize after download completes |
| `dispose()` | `Future<void>` | Close stream controller |

## Behavior details

- `initialize()` times out engine init after 10 seconds.
- When `skipModelCheck` is true, skips `modelChecker` call entirely (used in test builds with `FakeInferenceEngine`).
- `onEngineReady` is only called when `engine.isReady == true` after initialization.

## Dependencies

- `InferenceEngine` (interface)
- `ModelConfig` (default model file name)
- `ModelMetadata` (passed in `AppReady` state)

## Provider

`appControllerProvider` in `lib/providers/app_provider.dart`:

```dart
final appControllerProvider = Provider<AppController>((ref) {
  final factory = ref.watch(engineFactoryProvider);
  return AppController(
    engineFactory: factory,
    modelChecker: () => FlutterGemma.isModelInstalled(
      ModelConfig.defaultModelFileName,
    ),
    onEngineReady: (engine) {
      ref.read(inferenceEngineProvider.notifier).setEngine(engine);
    },
    skipModelCheck: ref.watch(skipModelCheckProvider),
  );
});
```
