---
status: not-started
depends_on: [04_core_systems/05_model_manager.md, 04_core_systems/00_inference_interface.md]
produces: [lib/services/app/app_controller.dart, lib/providers/app_provider.dart]
---

# Plan: AppController

## Goal

Manage application lifecycle: check model availability, orchestrate initialization
sequence, expose top-level app state (ready, needs download, error). The router
uses this state to decide which screen to show.

## Implementation

`lib/services/app/app_controller.dart`:

```dart
import 'dart:async';

import '../../models/model_metadata.dart';
import '../inference/inference_engine.dart';
import '../model/model_manager.dart';

/// Top-level application state.
sealed class AppState {
  const AppState();
}

class AppLoading extends AppState {
  const AppLoading();
}

class AppNeedsModel extends AppState {
  const AppNeedsModel();
}

class AppReady extends AppState {
  const AppReady({required this.modelInfo});
  final ModelMetadata modelInfo;
}

class AppError extends AppState {
  const AppError({required this.message});
  final String message;
}

/// Controls application-level lifecycle.
///
/// Checks if model is downloaded, initializes the inference engine,
/// and exposes state for the router to decide navigation.
class AppController {
  AppController({
    required this.modelManager,
    required this.engine,
    this.modelName = 'gemma3-1b-it.task',
  });

  final ModelManager modelManager;
  final InferenceEngine engine;
  final String modelName;

  AppState _state = const AppLoading();
  final _stateController = StreamController<AppState>.broadcast();

  AppState get state => _state;
  Stream<AppState> get stateStream => _stateController.stream;

  /// Run the initialization sequence.
  ///
  /// Checks model availability, initializes engine if model found.
  Future<void> initialize() async {
    _setState(const AppLoading());

    final modelInfo = await modelManager.getDownloadedModel(modelName);

    if (modelInfo == null) {
      _setState(const AppNeedsModel());
      return;
    }

    await engine.initialize();

    if (engine.isReady) {
      _setState(AppReady(modelInfo: modelInfo));
    } else {
      _setState(AppError(message: 'Failed to initialize inference engine'));
    }
  }

  /// Called after model download completes. Retries initialization.
  Future<void> onModelDownloaded() async {
    await initialize();
  }

  void _setState(AppState newState) {
    _state = newState;
    _stateController.add(newState);
  }

  Future<void> dispose() async {
    await _stateController.close();
  }
}
```

## Provider

`lib/providers/app_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/inference_provider.dart';
import '../providers/service_providers.dart';
import '../services/app/app_controller.dart';

/// Provider for the AppController.
final appControllerProvider = Provider<AppController>((ref) {
  return AppController(
    modelManager: ref.watch(modelManagerProvider),
    engine: ref.watch(inferenceEngineProvider),
  );
});
```

## Router integration

The router uses AppController state to redirect:

```dart
redirect: (context, state) {
  final appState = ref.read(appControllerProvider).state;
  if (appState is AppNeedsModel) return '/model-download';
  if (appState is AppLoading) return null; // stay on current
  return null;
}
```

## Tests

- Initializes to AppReady when model exists (use temp file)
- Initializes to AppNeedsModel when no model found
- onModelDownloaded retries and transitions to AppReady
- Engine failure transitions to AppError

## Acceptance criteria

- [ ] AppController manages full lifecycle
- [ ] Sealed AppState enables exhaustive UI handling
- [ ] Router can redirect based on state
- [ ] Tests pass with FakeInferenceEngine
- [ ] `flutter analyze` passes
