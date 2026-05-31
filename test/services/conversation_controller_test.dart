import 'dart:io';

import 'package:fala/models/cefr_level.dart';
import 'package:fala/models/conversation_message.dart';
import 'package:fala/models/inference_status.dart';
import 'package:fala/models/tutor_response.dart';
import 'package:fala/services/conversation/conversation_controller.dart';
import 'package:fala/services/inference/inference_engine.dart';
import 'package:fala/services/inference/structured_inference_engine.dart';
import 'package:fala/services/inference/structured_output_parser.dart';
import 'package:fala/services/persistence/conversation_repository.dart';
import 'package:fala/services/prompt/prompt_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

/// Fake StructuredInferenceEngine that returns a configurable result.
class _FakeStructuredEngine extends StructuredInferenceEngine<TutorResponse> {
  _FakeStructuredEngine()
      : super(engine: _DummyEngine(), parser: _dummyParser());

  StructuredResult<TutorResponse> nextResult = const StructuredSuccess(
    value: TutorResponse(
      correction: CorrectionBlock(content: '', translation: '', errors: []),
      conversation: ConversationBlock(content: 'Ola!', translation: 'Hello!'),
    ),
    rawText: '{}',
  );

  @override
  Future<StructuredResult<TutorResponse>> generate(
    InferenceRequest request,
  ) async {
    return nextResult;
  }

  @override
  bool get isReady => true;

  @override
  InferenceStatus get status => const InferenceStatus.ready();

  @override
  Stream<InferenceStatus> get statusStream => const Stream.empty();
}

class _DummyEngine implements InferenceEngine {
  @override
  InferenceStatus get status => const InferenceStatus.ready();
  @override
  bool get isReady => true;
  @override
  Stream<InferenceStatus> get statusStream => const Stream.empty();
  @override
  Future<void> initialize() async {}
  @override
  Future<InferenceResult> generate(InferenceRequest request) async =>
      const InferenceSuccess(rawText: '');
  @override
  Future<void> dispose() async {}
}

// Need a dummy parser just for the super constructor

StructuredOutputParser<TutorResponse> _dummyParser() {
  return const StructuredOutputParser<TutorResponse>(
    fromJson: TutorResponse.fromJson,
  );
}

/// Fake PromptManager that returns a fixed string.
class _FakePromptManager extends PromptManager {
  Map<String, String>? lastVariables;

  @override
  Future<String> buildPrompt({
    required String name,
    required Map<String, String> variables,
    int? version,
  }) async {
    lastVariables = variables;
    return 'fake prompt';
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeStructuredEngine engine;
  late ConversationRepository repo;
  late _FakePromptManager promptManager;
  late ConversationController controller;
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_cc_test_');
    Hive.init(tempDir.path);

    engine = _FakeStructuredEngine();
    repo = ConversationRepository(boxName: 'test_cc_convos');
    await repo.initialize();
    promptManager = _FakePromptManager();

    controller = ConversationController(
      structuredEngine: engine,
      repository: repo,
      promptManager: promptManager,
    );
  });

  tearDown(() async {
    await repo.close();
    await tempDir.delete(recursive: true);
  });

  test('startConversation creates a new conversation', () async {
    final conv = await controller.startConversation();
    expect(conv.id, isNotEmpty);
    expect(conv.messages, isEmpty);
    expect(controller.currentConversation, isNotNull);
  });

  test('sendMessage adds user and tutor messages', () async {
    await controller.startConversation();
    final tutorMsg = await controller.sendMessage('Oi');

    expect(tutorMsg, isNotNull);
    expect(tutorMsg!.role, MessageRole.tutor);
    expect(tutorMsg.content, 'Ola!');

    final messages = controller.currentConversation!.messages;
    expect(messages, hasLength(2));
    expect(messages[0].role, MessageRole.user);
    expect(messages[0].content, 'Oi');
    expect(messages[1].role, MessageRole.tutor);
  });

  test('sendMessage returns null if no conversation started', () async {
    final result = await controller.sendMessage('Oi');
    expect(result, isNull);
  });

  test('sendMessage handles inference failure', () async {
    await controller.startConversation();
    engine.nextResult =
        const StructuredInferenceFailure(error: 'engine down');

    final tutorMsg = await controller.sendMessage('Oi');

    expect(tutorMsg, isNotNull);
    expect(
      tutorMsg!.content,
      'Error generating response: engine down',
    );
  });

  test('sendMessage handles parse failure with raw text', () async {
    await controller.startConversation();
    engine.nextResult = const StructuredParseFailure(
      rawText: 'some garbled output',
      error: 'invalid json',
    );

    final tutorMsg = await controller.sendMessage('Oi');

    expect(tutorMsg, isNotNull);
    expect(tutorMsg!.content, 'some garbled output');
    expect(tutorMsg.tutorResponse, isNull);
  });

  test('startConversation persists CefrLevel.displayName and topic',
      () async {
    final conv = await controller.startConversation(
      cefrLevel: CefrLevel.b1,
      topic: 'Food',
    );
    expect(conv.cefrLevel, 'B1');
    expect(conv.topic, 'Food');
  });

  test('setCefrLevel updates the active conversation without restarting it',
      () async {
    await controller.startConversation();
    final originalId = controller.currentConversation!.id;
    await controller.setCefrLevel(CefrLevel.c1);
    expect(controller.currentConversation!.id, originalId);
    expect(controller.currentConversation!.cefrLevel, 'C1');
  });

  test('setTopic trims input and updates the active conversation', () async {
    await controller.startConversation();
    await controller.setTopic('  Travel  ');
    expect(controller.currentConversation!.topic, 'Travel');
  });

  test('sendMessage substitutes cefr_level and topic into the prompt',
      () async {
    await controller.startConversation(
      cefrLevel: CefrLevel.a2,
      topic: 'Music',
    );
    await controller.sendMessage('Oi');
    expect(promptManager.lastVariables, isNotNull);
    expect(promptManager.lastVariables!['cefr_level'], 'A2');
    expect(promptManager.lastVariables!['topic'], 'Music');
  });
}
