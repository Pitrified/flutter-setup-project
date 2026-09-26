import 'dart:io';

import 'package:fala/models/inference_status.dart';
import 'package:fala/models/target_language.dart';
import 'package:fala/models/tutor_response.dart';
import 'package:fala/providers/conversation_provider.dart';
import 'package:fala/providers/settings_provider.dart';
import 'package:fala/screens/conversation/conversation_screen.dart';
import 'package:fala/services/conversation/conversation_controller.dart';
import 'package:fala/services/inference/inference_engine.dart';
import 'package:fala/services/inference/structured_stream_engine.dart';
import 'package:fala/services/persistence/conversation_repository.dart';
import 'package:fala/services/prompt/prompt_manager.dart';
import 'package:fala/services/settings/app_settings_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

const _olaJson =
    '{"correction":{"content":"","translation":"","errors":[]},'
    '"conversation":{"content":"Ola!","translation":"Hello!"}}';

class _OneShotEngine implements InferenceEngine {
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
    yield _olaJson;
  }

  @override
  Future<void> dispose() async {}
}

class _FakePromptManager extends PromptManager {
  @override
  Future<String> buildPrompt({
    required String name,
    required Map<String, String> variables,
    int? version,
  }) async => 'fake prompt';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ConversationController controller;
  late ConversationRepository repo;
  late AppSettingsRepository settings;
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_lang_copy_test_');
    Hive.init(tempDir.path);

    repo = ConversationRepository(boxName: 'test_lang_convos');
    await repo.initialize();
    settings = AppSettingsRepository(boxName: 'test_lang_settings');
    await settings.initialize();

    controller = ConversationController(
      streamEngine: StructuredStreamEngine<TutorResponse>(
        engine: _OneShotEngine(),
        fromJson: TutorResponse.fromJson,
      ),
      repository: repo,
      promptManager: _FakePromptManager(),
    );
  });

  tearDown(() async {
    await controller.dispose();
    await repo.close();
    await settings.close();
    await tempDir.delete(recursive: true);
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    // The picker sheet lists five languages; in the default 800x600 test
    // viewport the lower entries sit below the fold and a tap on them misses.
    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          conversationControllerProvider.overrideWithValue(controller),
          appSettingsRepositoryProvider.overrideWithValue(settings),
        ],
        child: const MaterialApp(home: ConversationScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('empty-state and hint name the conversation language', (
    tester,
  ) async {
    await tester.runAsync(
      () => controller.startConversation(language: TargetLanguage.esEs),
    );
    await pumpScreen(tester);

    expect(find.text('Say something in Spanish!'), findsOneWidget);
    expect(find.text('Type in Spanish...'), findsOneWidget);
    // The chip shows the language's own name.
    expect(find.text('español'), findsOneWidget);
  });

  testWidgets('a pt-BR conversation still reads as Portuguese', (tester) async {
    await tester.runAsync(() => controller.startConversation());
    await pumpScreen(tester);

    expect(find.text('Say something in Portuguese!'), findsOneWidget);
    expect(find.text('Type in Portuguese...'), findsOneWidget);
  });
}
