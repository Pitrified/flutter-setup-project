import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/tutor_response.dart';
import '../services/inference/engine_registry.dart';
import '../services/inference/inference_engine.dart';
import '../services/inference/structured_inference_engine.dart';
import '../services/inference/structured_output_parser.dart';
import 'settings_provider.dart';

/// Factory that creates an [InferenceEngine] given a model file path.
///
/// Resolved from the engine registry based on the currently selected
/// [EngineKind]. To select a different engine at runtime, mutate
/// [selectedEngineKindProvider].
typedef EngineFactory = InferenceEngine Function(String modelPath);

/// Provider for the engine factory.
///
/// Derived from [selectedEngineKindProvider] via [engineFactoryFor]. Tests can
/// still override this provider directly to inject a fixed factory.
final engineFactoryProvider = Provider<EngineFactory>((ref) {
  final kind = ref.watch(selectedEngineKindProvider);
  return engineFactoryFor(kind);
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
    timeout: const Duration(seconds: 60),
  );
});
