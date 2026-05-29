import 'dart:async';

import 'package:flutter_gemma/flutter_gemma.dart';

import '../../config/model_config.dart';
import '../../models/inference_status.dart';
import 'inference_engine.dart';

/// Production inference engine using flutter_gemma plugin.
///
/// Loads a model via the plugin's LiteRT-LM runtime and performs on-device
/// inference. Supports any model format that flutter_gemma handles
/// (.litertlm, .task, .bin) - the plugin auto-selects the appropriate backend.
class FlutterGemmaEngine implements InferenceEngine {
  FlutterGemmaEngine({required this.modelPath});

  final String modelPath;

  InferenceModel? _model;
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
      // installModel is idempotent - skips download if already installed,
      // but always sets the model as active for getActiveModel().
      await FlutterGemma.installModel(
        modelType: ModelType.qwen3,
        fileType: ModelFileType.litertlm,
      ).fromNetwork(ModelConfig.defaultModel.downloadUrl).install();

      _model = await FlutterGemma.getActiveModel(maxTokens: 1024);
      _setStatus(const InferenceStatus.ready());
    } on Exception catch (e) {
      _setStatus(InferenceStatus.error(e.toString()));
    }
  }

  @override
  Future<InferenceResult> generate(InferenceRequest request) async {
    if (!isReady || _model == null) {
      return const InferenceFailure(error: 'Engine not initialized');
    }

    _setStatus(const InferenceStatus.generating());
    try {
      final chat = await _model!.createChat(
        isThinking: false,
        modelType: ModelType.qwen3,
        temperature: request.temperature,
        topK: request.topK,
      );
      await chat.addQueryChunk(
        Message(text: request.prompt, isUser: true),
      );
      final buffer = StringBuffer();
      await for (final response in chat.generateChatResponseAsync()) {
        if (response is TextResponse) {
          buffer.write(response.token);
        }
      }
      final result = buffer.toString();
      _setStatus(const InferenceStatus.ready());
      return InferenceSuccess(rawText: result);
    } on Exception catch (e) {
      _setStatus(const InferenceStatus.ready());
      return InferenceFailure(error: e.toString());
    }
  }

  @override
  Future<void> dispose() async {
    await _model?.close();
    _model = null;
    _setStatus(const InferenceStatus.disposed());
    await _statusController.close();
  }

  void _setStatus(InferenceStatus newStatus) {
    _status = newStatus;
    _statusController.add(newStatus);
  }
}
