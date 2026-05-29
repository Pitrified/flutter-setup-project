import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/tutor_response.dart';
import '../services/inference/inference_engine.dart';
import '../services/inference/structured_inference_engine.dart';
import '../services/inference/structured_output_parser.dart';

/// Factory that creates an [InferenceEngine] given a model file path.
///
/// Override this in main.dart to select the engine strategy:
/// - Fake: `(_) => FakeInferenceEngine()`
/// - On-device: `(path) => FlutterGemmaEngine(modelPath: path)`
/// - Remote: `(_) => RemoteInferenceEngine(apiKey: key, baseUrl: url)`
typedef EngineFactory = InferenceEngine Function(String modelPath);

/// Provider for the engine factory.
///
/// Must be overridden in ProviderScope with the desired engine strategy.
final engineFactoryProvider = Provider<EngineFactory>((ref) {
  throw UnimplementedError(
    'engineFactoryProvider must be overridden with a concrete factory',
  );
});

/// Notifier that holds the active inference engine instance.
///
/// Initially null. Set by AppController after model path is confirmed
/// and engine is initialized.
class InferenceEngineNotifier extends Notifier<InferenceEngine?> {
  @override
  InferenceEngine? build() => null;

  /// Set the active engine after initialization.
  void setEngine(InferenceEngine engine) {
    state = engine;
  }
}

/// Provider for the raw inference engine.
final inferenceEngineProvider =
    NotifierProvider<InferenceEngineNotifier, InferenceEngine?>(
  InferenceEngineNotifier.new,
);

/// Provider for the structured inference engine (TutorResponse).
///
/// Composes the raw engine with the tutor response parser.
/// ConversationController depends on this, not on inferenceEngineProvider.
/// Returns null when the engine is not yet initialized.
final structuredInferenceEngineProvider =
    Provider<StructuredInferenceEngine<TutorResponse>?>((ref) {
  final engine = ref.watch(inferenceEngineProvider);
  if (engine == null) return null;
  return StructuredInferenceEngine(
    engine: engine,
    parser: const StructuredOutputParser(fromJson: TutorResponse.fromJson),
  );
});
