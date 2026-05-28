import 'dart:async';

import 'package:fala/models/inference_status.dart';
import 'package:fala/models/tutor_response.dart';
import 'package:fala/services/inference/inference_engine.dart';
import 'package:fala/services/inference/structured_inference_engine.dart';
import 'package:fala/services/inference/structured_output_parser.dart';
import 'package:flutter_test/flutter_test.dart';

/// Engine that never completes generate().
class _HangingEngine implements InferenceEngine {
  @override
  InferenceStatus get status => const InferenceStatus.ready();
  @override
  bool get isReady => true;
  @override
  Stream<InferenceStatus> get statusStream => const Stream.empty();
  @override
  Future<void> initialize() async {}
  @override
  Future<InferenceResult> generate(InferenceRequest request) {
    return Completer<InferenceResult>().future; // never completes
  }

  @override
  Future<void> dispose() async {}
}

void main() {
  test('generate times out and returns failure', () async {
    final engine = StructuredInferenceEngine<TutorResponse>(
      engine: _HangingEngine(),
      parser: const StructuredOutputParser<TutorResponse>(
        fromJson: TutorResponse.fromJson,
      ),
      timeout: const Duration(milliseconds: 100),
    );

    final result = await engine.generate(
      const InferenceRequest(prompt: 'test'),
    );

    expect(result, isA<StructuredInferenceFailure<TutorResponse>>());
    final failure = result as StructuredInferenceFailure<TutorResponse>;
    expect(failure.error, 'Response timed out');
  });
}
