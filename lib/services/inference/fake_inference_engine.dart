import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

import '../../models/inference_status.dart';
import 'inference_engine.dart';

/// Fake inference engine that returns pre-loaded responses in sequence.
///
/// Responses are loaded from a JSON fixture file in assets/fixtures/.
/// Each call to [generate] returns the next response in order, cycling back
/// to the start when all responses have been used.
///
/// Returns only raw text (serialized JSON). The StructuredInferenceEngine
/// layer handles parsing into domain types.
class FakeInferenceEngine implements InferenceEngine {
  FakeInferenceEngine({
    this.fixtureAssetPath = 'assets/fixtures/tutor_responses.json',
    this.responseDelayMs = 500,
    this.streamChunkSize = 8,
    this.streamChunkDelayMs = 10,
  });

  final String fixtureAssetPath;
  final int responseDelayMs;

  /// Number of characters revealed per [generateStream] tick. Small so tests
  /// and manual runs see genuinely partial buffers (mid-string, mid-array).
  final int streamChunkSize;

  /// Delay between [generateStream] ticks, simulating token latency.
  final int streamChunkDelayMs;

  final _statusController = StreamController<InferenceStatus>.broadcast();
  InferenceStatus _status = const InferenceStatus.uninitialized();
  List<Map<String, dynamic>> _responses = [];
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
    _responses = jsonList.cast<Map<String, dynamic>>();

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

    final rawText = _nextRawText();

    _setStatus(const InferenceStatus.ready());
    return InferenceSuccess(rawText: rawText);
  }

  @override
  Stream<String> generateStream(InferenceRequest request) async* {
    if (!isReady) {
      throw const InferenceStreamException('Engine not initialized');
    }

    _setStatus(const InferenceStatus.generating());

    final full = _nextRawText();
    // Emit growing prefixes (cumulative buffer-so-far), then the full text.
    for (var end = streamChunkSize; end < full.length; end += streamChunkSize) {
      await Future.delayed(Duration(milliseconds: streamChunkDelayMs));
      yield full.substring(0, end);
    }
    await Future.delayed(Duration(milliseconds: streamChunkDelayMs));
    yield full;

    _setStatus(const InferenceStatus.ready());
  }

  /// Next fixture serialized to JSON, advancing the round-robin cursor. Falls
  /// back to a placeholder document when no fixtures are loaded.
  String _nextRawText() {
    if (_responses.isEmpty) {
      return '{"correction": {"content": "", "translation": "", "errors": []}, '
          '"conversation": {"content": "No fixtures loaded", '
          '"translation": "No fixtures loaded"}}';
    }

    final response = _responses[_nextIndex % _responses.length];
    _nextIndex++;
    return jsonEncode(response);
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
