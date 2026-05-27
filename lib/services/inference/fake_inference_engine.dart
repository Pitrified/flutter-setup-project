import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

import '../../models/inference_status.dart';
import '../../models/tutor_response.dart';
import 'inference_engine.dart';

/// Fake inference engine that returns pre-loaded responses in sequence.
///
/// Responses are loaded from a JSON fixture file in assets/fixtures/.
/// Each call to [generate] returns the next response in order, cycling back
/// to the start when all responses have been used.
class FakeInferenceEngine implements InferenceEngine {
  FakeInferenceEngine({
    this.fixtureAssetPath = 'assets/fixtures/tutor_responses.json',
    this.responseDelayMs = 500,
  });

  final String fixtureAssetPath;
  final int responseDelayMs;

  final _statusController = StreamController<InferenceStatus>.broadcast();
  InferenceStatus _status = const InferenceStatus.uninitialized();
  List<TutorResponse> _responses = [];
  int _nextIndex = 0;

  @override
  InferenceStatus get status => _status;

  @override
  Stream<InferenceStatus> get statusStream => _statusController.stream;

  @override
  bool get isReady => _status == const InferenceStatus.ready();

  @override
  Future<void> initialize() async {
    _setStatus(const InferenceStatus.loading());

    final jsonString = await rootBundle.loadString(fixtureAssetPath);
    final jsonList = jsonDecode(jsonString) as List<dynamic>;
    _responses = jsonList
        .map((e) => TutorResponse.fromJson(e as Map<String, dynamic>))
        .toList();

    _setStatus(const InferenceStatus.ready());
  }

  @override
  Future<InferenceResult> generate(InferenceRequest request) async {
    if (!isReady) {
      return const InferenceFailure(error: 'Engine not initialized');
    }

    _setStatus(const InferenceStatus.generating());

    // Simulate inference latency
    await Future.delayed(Duration(milliseconds: responseDelayMs));

    if (_responses.isEmpty) {
      _setStatus(const InferenceStatus.ready());
      return const InferenceSuccess(
        rawText:
            '{"correction": {"content": "", "translation": "", "errors": []}, '
            '"conversation": {"content": "No fixtures loaded", '
            '"translation": "No fixtures loaded"}}',
      );
    }

    final response = _responses[_nextIndex % _responses.length];
    _nextIndex++;

    _setStatus(const InferenceStatus.ready());
    return InferenceSuccess(
      rawText: jsonEncode(response.toJson()),
      tutorResponse: response,
    );
  }

  @override
  Future<void> dispose() async {
    _setStatus(const InferenceStatus.disposed());
    await _statusController.close();
  }

  void _setStatus(InferenceStatus newStatus) {
    _status = newStatus;
    _statusController.add(newStatus);
  }
}
