import '../../models/inference_status.dart';

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
  const InferenceSuccess({required this.rawText});

  /// The raw text output from the LLM.
  final String rawText;
}

class InferenceFailure extends InferenceResult {
  const InferenceFailure({required this.error});

  final String error;
}

/// Error surfaced on [InferenceEngine.generateStream] when generation fails.
///
/// Carries the same message an [InferenceFailure] would, so stream consumers
/// can detect failure without losing the [InferenceResult] error semantics.
class InferenceStreamException implements Exception {
  const InferenceStreamException(this.message);

  final String message;

  @override
  String toString() => 'InferenceStreamException: $message';
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
  /// Returns the raw text output from the LLM.
  /// Transitions status: ready -> generating -> ready.
  Future<InferenceResult> generate(InferenceRequest request);

  /// Generate a response as a stream of **cumulative** text buffers.
  ///
  /// Each event is the full raw text produced so far (monotonically growing),
  /// so the final event equals the complete output and downstream parsers can
  /// re-parse each emission directly (see `PartialJsonParser`). Engines that
  /// stream native deltas accumulate them internally; consumers never
  /// accumulate.
  ///
  /// The stream completes normally on success. On failure it emits an
  /// [InferenceStreamException] carrying the same message an [InferenceFailure]
  /// would, so failures are not lost.
  ///
  /// Transitions status: ready -> generating -> ready, mirroring [generate].
  Stream<String> generateStream(InferenceRequest request);

  /// Whether the engine is ready to accept inference requests.
  bool get isReady;

  /// Release all resources (model memory, GPU handles).
  ///
  /// After dispose, the engine cannot be reused.
  Future<void> dispose();
}

/// Temporary bridge that satisfies [InferenceEngine.generateStream] for engines
/// that do not yet stream natively: it runs the one-shot [generate] and emits
/// the result as a single (already-complete) cumulative buffer.
///
/// This is a phase-2 compile bridge for OpenAI / gemma; phase 4 replaces it
/// with real token streaming. It honors the streaming contract: success yields
/// one final buffer, failure throws [InferenceStreamException].
Stream<String> bufferedGenerateStream(
  InferenceEngine engine,
  InferenceRequest request,
) async* {
  final result = await engine.generate(request);
  switch (result) {
    case InferenceSuccess(:final rawText):
      yield rawText;
    case InferenceFailure(:final error):
      throw InferenceStreamException(error);
  }
}
