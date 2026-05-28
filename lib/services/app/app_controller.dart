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

  /// Current application state.
  AppState get state => _state;

  /// Stream of state changes for reactive UI.
  Stream<AppState> get stateStream => _stateController.stream;

  /// Run the initialization sequence.
  ///
  /// Checks model availability, initializes engine if model found.
  /// Times out after 10 seconds if engine init hangs.
  Future<void> initialize() async {
    _setState(const AppLoading());

    final modelInfo = await modelManager.getDownloadedModel(modelName);

    if (modelInfo == null) {
      _setState(const AppNeedsModel());
      return;
    }

    try {
      await engine.initialize().timeout(const Duration(seconds: 10));
    } on TimeoutException {
      _setState(
        const AppError(message: 'Engine initialization timed out'),
      );
      return;
    }

    if (engine.isReady) {
      _setState(AppReady(modelInfo: modelInfo));
    } else {
      _setState(
        const AppError(message: 'Failed to initialize inference engine'),
      );
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

  /// Dispose resources.
  Future<void> dispose() async {
    await _stateController.close();
  }
}
