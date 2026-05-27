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
