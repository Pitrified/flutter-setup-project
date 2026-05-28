import '../../models/inference_status.dart';
import 'inference_engine.dart';
import 'structured_output_parser.dart';

/// Result of a structured inference call.
///
/// Three possible outcomes:
/// - [StructuredSuccess]: inference succeeded and output parsed to T
/// - [StructuredInferenceFailure]: engine failed to generate
/// - [StructuredParseFailure]: engine generated text but parsing failed
sealed class StructuredResult<T> {
  const StructuredResult();
}

class StructuredSuccess<T> extends StructuredResult<T> {
  const StructuredSuccess({required this.value, required this.rawText});

  /// The parsed and validated domain object.
  final T value;

  /// The raw text from the engine (kept for logging/debugging).
  final String rawText;
}

class StructuredInferenceFailure<T> extends StructuredResult<T> {
  const StructuredInferenceFailure({required this.error});

  /// Description of the inference failure.
  final String error;
}

class StructuredParseFailure<T> extends StructuredResult<T> {
  const StructuredParseFailure({required this.rawText, required this.error});

  /// The raw text that could not be parsed.
  final String rawText;

  /// Description of the parse failure.
  final String error;
}

/// Composes a raw [InferenceEngine] with a [StructuredOutputParser]`<T>`.
///
/// Provides a single typed API: send a prompt, get back T or an explicit
/// failure mode. The caller never deals with raw text parsing directly.
class StructuredInferenceEngine<T> {
  const StructuredInferenceEngine({
    required this.engine,
    required this.parser,
  });

  /// The underlying raw text inference engine.
  final InferenceEngine engine;

  /// The parser that converts raw text to T.
  final StructuredOutputParser<T> parser;

  /// Current status of the underlying engine.
  InferenceStatus get status => engine.status;

  /// Stream of status changes from the underlying engine.
  Stream<InferenceStatus> get statusStream => engine.statusStream;

  /// Whether the underlying engine is ready to accept requests.
  bool get isReady => engine.isReady;

  /// Generate and parse a structured response.
  ///
  /// Returns one of three outcomes:
  /// - [StructuredSuccess] with the parsed value of type T
  /// - [StructuredInferenceFailure] if the engine could not generate
  /// - [StructuredParseFailure] if the engine generated text but parsing failed
  Future<StructuredResult<T>> generate(InferenceRequest request) async {
    final result = await engine.generate(request);
    return switch (result) {
      InferenceFailure(:final error) =>
        StructuredInferenceFailure(error: error),
      InferenceSuccess(:final rawText) => switch (parser.parse(rawText)) {
        ParseSuccess(:final value) =>
          StructuredSuccess(value: value, rawText: rawText),
        ParseFailure(:final rawText, :final error) =>
          StructuredParseFailure(rawText: rawText, error: error),
      },
    };
  }

  /// Delegates initialization to the underlying engine.
  Future<void> initialize() => engine.initialize();

  /// Delegates disposal to the underlying engine.
  Future<void> dispose() => engine.dispose();
}
