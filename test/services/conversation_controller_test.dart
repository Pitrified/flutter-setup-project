import 'dart:io';

import 'package:fala/models/cefr_level.dart';
import 'package:fala/models/conversation_message.dart';
import 'package:fala/models/inference_status.dart';
import 'package:fala/models/tutor_response.dart';
import 'package:fala/services/conversation/conversation_controller.dart';
import 'package:fala/services/inference/inference_engine.dart';
import 'package:fala/services/inference/structured_stream_engine.dart';
import 'package:fala/services/persistence/conversation_repository.dart';
import 'package:fala/services/prompt/prompt_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

/// A complete, schema-conforming TutorResponse document (the "Ola!" reply).
const _olaJson =
    '{"correction":{"content":"","translation":"","errors":[]},'
    '"conversation":{"content":"Ola!","translation":"Hello!"}}';

/// Cumulative buffers-so-far for [full], revealing [step] chars at a time.
List<String> _cumulative(String full, {int step = 16}) {
  final out = <String>[];
  for (var end = step; end < full.length; end += step) {
    out.add(full.substring(0, end));
  }
  out.add(full);
  return out;
}

/// Raw engine that emits a scripted list of cumulative buffers, then optionally
/// throws an [InferenceStreamException].
class _ScriptedEngine implements InferenceEngine {
  List<String> buffers = _cumulative(_olaJson);
  String? throwMessage;

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
      const InferenceSuccess(rawText: _olaJson);

  @override
  Stream<String> generateStream(InferenceRequest request) async* {
    for (final buffer in buffers) {
      yield buffer;
    }
    if (throwMessage != null) {
      throw InferenceStreamException(throwMessage!);
    }
  }

  @override
  Future<void> dispose() async {}
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

  late _ScriptedEngine engine;
  late StructuredStreamEngine<TutorResponse> streamEngine;
  late ConversationRepository repo;
  late _FakePromptManager promptManager;
  late ConversationController controller;
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_cc_test_');
    Hive.init(tempDir.path);

    engine = _ScriptedEngine();
    streamEngine = StructuredStreamEngine<TutorResponse>(
      engine: engine,
      fromJson: TutorResponse.fromJson,
    );
    repo = ConversationRepository(boxName: 'test_cc_convos');
    await repo.initialize();
    promptManager = _FakePromptManager();

    controller = ConversationController(
      streamEngine: streamEngine,
      repository: repo,
      promptManager: promptManager,
    );
  });

  tearDown(() async {
    await controller.dispose();
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
    engine
      ..buffers = const ['{']
      ..throwMessage = 'engine down';

    final tutorMsg = await controller.sendMessage('Oi');

    expect(tutorMsg, isNotNull);
    expect(
      tutorMsg!.content,
      'Error generating response: engine down',
    );
    expect(tutorMsg.tutorResponse, isNull);
  });

  test('sendMessage handles parse failure with raw text', () async {
    await controller.startConversation();
    // A complete buffer that is not valid TutorResponse JSON: the strict final
    // parse fails and the raw text becomes the reply.
    engine.buffers = const ['some garbled output'];

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

  test('sendMessage emits intermediate deltas then a terminal on streamingReply',
      () async {
    await controller.startConversation();

    final deltas = <StructuredDelta<TutorResponse>>[];
    final sub = controller.streamingReply.listen(deltas.add);

    await controller.sendMessage('Oi');
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();

    expect(deltas.length, greaterThan(1));
    // At least one in-flight delta with a partial map and no typed value yet.
    expect(deltas.any((d) => !d.isTerminal && d.value == null), isTrue);
    // The last delta is the terminal success with the typed value.
    expect(deltas.last.isTerminal, isTrue);
    expect(deltas.last.value, isNotNull);
    expect(deltas.last.value!.conversation.content, 'Ola!');
  });

  test('persists exactly one tutor message with the terminal typed value',
      () async {
    await controller.startConversation();

    final msg = await controller.sendMessage('Oi');

    final tutors = controller.currentConversation!.messages
        .where((m) => m.role == MessageRole.tutor)
        .toList();
    expect(tutors, hasLength(1));
    expect(tutors.single.tutorResponse, isNotNull);
    expect(tutors.single.tutorResponse!.conversation.content, 'Ola!');
    expect(msg!.tutorResponse, tutors.single.tutorResponse);
  });

  test('on failure appends fallback text and stays usable for the next send',
      () async {
    await controller.startConversation();
    engine
      ..buffers = const ['{']
      ..throwMessage = 'engine down';

    final failMsg = await controller.sendMessage('Oi');
    expect(failMsg!.content, 'Error generating response: engine down');
    expect(controller.isSending, isFalse);

    // The in-flight channel is not left open/broken: a second send succeeds.
    engine
      ..throwMessage = null
      ..buffers = _cumulative(_olaJson);
    final okMsg = await controller.sendMessage('De novo');
    expect(okMsg!.content, 'Ola!');
  });
}
