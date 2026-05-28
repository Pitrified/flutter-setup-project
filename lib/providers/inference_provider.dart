import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/tutor_response.dart';
import '../services/inference/inference_engine.dart';
import '../services/inference/structured_inference_engine.dart';
import '../services/inference/structured_output_parser.dart';

/// Provider for the raw inference engine.
///
/// Override this in tests with FakeInferenceEngine.
/// Override in production with FlutterGemmaEngine.
final inferenceEngineProvider = Provider<InferenceEngine>((ref) {
  throw UnimplementedError(
    'inferenceEngineProvider must be overridden with a concrete implementation',
  );
});

/// Provider for the structured inference engine (TutorResponse).
///
/// Composes the raw engine with the tutor response parser.
/// ConversationController depends on this, not on inferenceEngineProvider.
final structuredInferenceEngineProvider =
    Provider<StructuredInferenceEngine<TutorResponse>>((ref) {
  return StructuredInferenceEngine(
    engine: ref.watch(inferenceEngineProvider),
    parser: const StructuredOutputParser(fromJson: TutorResponse.fromJson),
  );
});
