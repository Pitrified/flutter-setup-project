import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/tutor_response.dart';
import '../services/inference/engine_registry.dart';
import '../services/inference/inference_engine.dart';
import '../services/inference/structured_inference_engine.dart';
import '../services/inference/structured_output_parser.dart';
import '../services/inference/structured_stream_engine.dart';
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
  final deps = EngineRegistryDeps(
    apiKeyStore: ref.watch(apiKeyStoreProvider),
    settings: ref.watch(appSettingsRepositoryProvider),
  );
  return engineFactoryFor(kind, deps);
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

  /// Clear the active engine (e.g. on engine-kind change).
  void clearEngine() {
    state = null;
  }
}

/// Provider for the raw inference engine.
final inferenceEngineProvider =
    NotifierProvider<InferenceEngineNotifier, InferenceEngine?>(
  InferenceEngineNotifier.new,
);

/// Provider for the structured inference engine (TutorResponse).
///
/// Composes the raw engine with the tutor response parser. Returns null when
/// the engine is not yet initialized.
///
/// Orphaned but kept: `ConversationController` now drives the streaming path
/// ([structuredStreamEngineProvider]) for the live turn. This one-shot provider
/// is valid and stays available for non-streaming callers (e.g. a future
/// batch/regenerate path); nothing watches it today.
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

/// Provider for the structured *streaming* engine (TutorResponse).
///
/// Wraps the same active raw engine in a [StructuredStreamEngine], following
/// the active engine kind exactly like [structuredInferenceEngineProvider].
/// ConversationController depends on this for the live in-flight turn; the
/// one-shot provider above stays available for non-streaming callers.
/// Returns null when the engine is not yet initialized.
final structuredStreamEngineProvider =
    Provider<StructuredStreamEngine<TutorResponse>?>((ref) {
  final engine = ref.watch(inferenceEngineProvider);
  if (engine == null) return null;
  return StructuredStreamEngine<TutorResponse>(
    engine: engine,
    fromJson: TutorResponse.fromJson,
    timeout: const Duration(seconds: 60),
  );
});
