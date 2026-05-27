import 'dart:async';

import '../../models/inference_status.dart';
import 'inference_engine.dart';

/// Production inference engine using flutter_gemma.
///
/// Loads a real model file from device storage and performs on-device inference.
/// Requires a downloaded model file (see ModelManager).
class FlutterGemmaEngine implements InferenceEngine {
  FlutterGemmaEngine({required this.modelPath});

  final String modelPath;
  final _statusController = StreamController<InferenceStatus>.broadcast();
  InferenceStatus _status = const InferenceStatus.uninitialized();

  @override
  InferenceStatus get status => _status;

  @override
  Stream<InferenceStatus> get statusStream => _statusController.stream;

  @override
  bool get isReady => _status == const InferenceStatus.ready();

  @override
  Future<void> initialize() async {
    _setStatus(const InferenceStatus.loading());
    try {
      // TODO: Initialize flutter_gemma with model file
      // await FlutterGemmaPlugin.instance.init(
      //   maxTokens: 1024,
      //   modelPath: modelPath,
      // );
      _setStatus(const InferenceStatus.ready());
    } on Exception catch (e) {
      _setStatus(InferenceStatus.error(e.toString()));
    }
  }

  @override
  Future<InferenceResult> generate(InferenceRequest request) async {
    if (!isReady) {
      return const InferenceFailure(error: 'Engine not initialized');
    }

    _setStatus(const InferenceStatus.generating());
    try {
      // TODO: Call flutter_gemma inference
      // final response = await FlutterGemmaPlugin.instance.getResponse(
      //   prompt: request.prompt,
      // );
      const response = ''; // placeholder

      _setStatus(const InferenceStatus.ready());
      return const InferenceSuccess(rawText: response);
    } on Exception catch (e) {
      _setStatus(const InferenceStatus.ready());
      return InferenceFailure(error: e.toString());
    }
  }

  @override
  Future<void> dispose() async {
    // TODO: Release flutter_gemma resources
    _setStatus(const InferenceStatus.disposed());
    await _statusController.close();
  }

  void _setStatus(InferenceStatus newStatus) {
    _status = newStatus;
    _statusController.add(newStatus);
  }
}
