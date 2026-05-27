import '../../models/inference_status.dart';
import '../../models/tutor_response.dart';

/// Configuration for a single inference call.
class InferenceRequest {
  const InferenceRequest({
    required this.prompt,
    this.maxTokens = 512,
    this.temperature = 0.7,
    this.topK = 40,
  });

  final String prompt;
  final int maxTokens;
  final double temperature;
  final int topK;
}

/// Result of an inference call.
sealed class InferenceResult {
  const InferenceResult();
}

class InferenceSuccess extends InferenceResult {
  const InferenceSuccess({required this.rawText, this.tutorResponse});

  final String rawText;
  final TutorResponse? tutorResponse;
}

class InferenceFailure extends InferenceResult {
  const InferenceFailure({required this.error});

  final String error;
}

/// Abstract interface for on-device LLM inference.
///
/// All backends (FakeInferenceEngine, FlutterGemmaEngine, etc.) implement this.
/// App code interacts only with this interface via Riverpod providers.
abstract class InferenceEngine {
  /// Current status of the engine.
  InferenceStatus get status;

  /// Stream of status changes for reactive UI updates.
  Stream<InferenceStatus> get statusStream;

  /// Initialize the engine (load model weights, warm up).
  ///
  /// Must be called before [generate]. Can be called only once.
  /// Transitions status: uninitialized -> loading -> ready (or error).
  Future<void> initialize();

  /// Generate a response given a prompt.
  ///
  /// Returns structured output if parsing succeeds, raw text otherwise.
  /// Transitions status: ready -> generating -> ready.
  Future<InferenceResult> generate(InferenceRequest request);

  /// Whether the engine is ready to accept inference requests.
  bool get isReady;

  /// Release all resources (model memory, GPU handles).
  ///
  /// After dispose, the engine cannot be reused.
  Future<void> dispose();
}
