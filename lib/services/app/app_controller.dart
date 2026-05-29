import 'dart:async';

import '../../config/model_config.dart';
import '../../models/model_metadata.dart';
import '../inference/inference_engine.dart';

/// Checks whether the model is available for inference.
typedef ModelChecker = Future<bool> Function();

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
    required this.engineFactory,
    required this.onEngineReady,
    required this.modelChecker,
    this.modelName = ModelConfig.defaultModelFileName,
    this.skipModelCheck = false,
  });

  final InferenceEngine Function(String modelPath) engineFactory;
  final void Function(InferenceEngine engine) onEngineReady;
  final ModelChecker modelChecker;
  final String modelName;

  /// When true, skip model file verification (used with FakeInferenceEngine).
  final bool skipModelCheck;

  InferenceEngine? _engine;

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

    if (!skipModelCheck) {
      final isAvailable = await modelChecker();

      if (!isAvailable) {
        _setState(const AppNeedsModel());
        return;
      }
    }

    _engine = engineFactory('');

    try {
      await _engine!.initialize().timeout(const Duration(seconds: 10));
    } on TimeoutException {
      _setState(
        const AppError(message: 'Engine initialization timed out'),
      );
      return;
    }

    if (_engine!.isReady) {
      onEngineReady(_engine!);
      _setState(AppReady(
        modelInfo: ModelMetadata(
          name: modelName,
          filePath: '',
          fileSizeBytes: 0,
          downloadedAt: DateTime.now(),
        ),
      ));
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
