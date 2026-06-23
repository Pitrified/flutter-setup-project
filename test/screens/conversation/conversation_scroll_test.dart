import 'dart:io';

import 'package:fala/models/inference_status.dart';
import 'package:fala/models/tutor_response.dart';
import 'package:fala/providers/conversation_provider.dart';
import 'package:fala/screens/conversation/conversation_screen.dart';
import 'package:fala/services/conversation/conversation_controller.dart';
import 'package:fala/services/inference/inference_engine.dart';
import 'package:fala/services/inference/structured_stream_engine.dart';
import 'package:fala/services/persistence/conversation_repository.dart';
import 'package:fala/services/prompt/prompt_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

/// A complete, schema-conforming TutorResponse document (the "Ola!" reply).
const _olaJson =
    '{"correction":{"content":"","translation":"","errors":[]},'
    '"conversation":{"content":"Ola!","translation":"Hello!"}}';

/// Raw engine that emits the full document in one buffer (no per-token splitting
/// needed for these scroll tests).
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
  }) async =>
      'fake prompt';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ConversationController controller;
  late ConversationRepository repo;
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_scroll_test_');
    Hive.init(tempDir.path);

    final streamEngine = StructuredStreamEngine<TutorResponse>(
      engine: _OneShotEngine(),
      fromJson: TutorResponse.fromJson,
    );
    repo = ConversationRepository(boxName: 'test_scroll_convos');
    await repo.initialize();

    controller = ConversationController(
      streamEngine: streamEngine,
      repository: repo,
      promptManager: _FakePromptManager(),
    );

    // Seed a conversation tall enough to be scrollable in the test viewport.
    await controller.startConversation();
    for (var i = 0; i < 12; i++) {
      await controller.sendMessage('Oi $i');
    }
  });

  tearDown(() async {
    await controller.dispose();
    await repo.close();
    await tempDir.delete(recursive: true);
  });

  // Pump a fixed window of frames - enough to run the 200ms scroll animation
  // and the 150ms opacity fade to completion. We avoid pumpAndSettle because
  // the screen hosts continuously-running tickers (e.g. the typing indicator
  // when streaming) in the general case, and fixed pumps keep these tests
  // deterministic.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          conversationControllerProvider.overrideWithValue(controller),
        ],
        child: const MaterialApp(home: ConversationScreen()),
      ),
    );
    await settle(tester);
  }

  ScrollPosition scrollPosition(WidgetTester tester) {
    final state = tester.state<ScrollableState>(
      find.descendant(
        of: find.byType(ListView),
        matching: find.byType(Scrollable),
      ),
    );
    return state.position;
  }

  double buttonOpacity(WidgetTester tester) {
    final finder = find.ancestor(
      of: find.byIcon(Icons.keyboard_arrow_down),
      matching: find.byType(AnimatedOpacity),
    );
    return tester.widget<AnimatedOpacity>(finder).opacity;
  }

  testWidgets('pinned user: a new message scrolls to the bottom, no button',
      (tester) async {
    await pumpScreen(tester);

    // sendMessage drives a real Stream; runAsync lets it complete outside the
    // test's fake-async zone, then we pump to flush the rebuild.
    await tester.runAsync(() => controller.sendMessage('mais uma'));
    await settle(tester);

    final pos = scrollPosition(tester);
    expect(pos.pixels, moveTo(pos.maxScrollExtent));
    expect(buttonOpacity(tester), 0);
  });

  testWidgets('scrolled-up user: a new message does not move the view',
      (tester) async {
    await pumpScreen(tester);

    // Go to the bottom (pinned), then scroll up to read earlier messages; the
    // upward drag moves away from the bottom and unpins the user.
    await tester.drag(find.byType(ListView), const Offset(0, -2000));
    await settle(tester);
    await tester.drag(find.byType(ListView), const Offset(0, 250));
    await settle(tester);
    final before = scrollPosition(tester).pixels;
    expect(buttonOpacity(tester), 1);

    await tester.runAsync(() => controller.sendMessage('chega de scroll'));
    await settle(tester);

    expect(scrollPosition(tester).pixels, before);
    expect(buttonOpacity(tester), 1);
  });

  testWidgets('tapping the button scrolls to the bottom and hides it',
      (tester) async {
    await pumpScreen(tester);

    await tester.drag(find.byType(ListView), const Offset(0, -2000));
    await settle(tester);
    await tester.drag(find.byType(ListView), const Offset(0, 250));
    await settle(tester);
    expect(buttonOpacity(tester), 1);

    await tester.tap(find.byIcon(Icons.keyboard_arrow_down));
    await settle(tester);

    final pos = scrollPosition(tester);
    expect(pos.pixels, moveTo(pos.maxScrollExtent));
    expect(buttonOpacity(tester), 0);
  });
}

/// Matcher: equal within a 1px tolerance (animations can land a hair short).
Matcher moveTo(double target) => closeTo(target, 1.0);
