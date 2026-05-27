import 'package:fala/models/inference_status.dart';
import 'package:fala/services/inference/fake_inference_engine.dart';
import 'package:fala/services/inference/inference_engine.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const fixtureJson = '''
[
  {
    "correction": {
      "content": "Eu gosto de cafe",
      "translation": "I like coffee",
      "errors": []
    },
    "conversation": {
      "content": "Muito bem!",
      "translation": "Very good!"
    }
  },
  {
    "correction": {
      "content": "",
      "translation": "",
      "errors": []
    },
    "conversation": {
      "content": "Otimo!",
      "translation": "Great!"
    }
  }
]
''';

  late FakeInferenceEngine engine;

  setUp(() {
    engine = FakeInferenceEngine(responseDelayMs: 0);

    // Mock asset bundle
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (message) async {
      final key = String.fromCharCodes(message!.buffer.asUint8List());
      if (key == 'assets/fixtures/tutor_responses.json') {
        return ByteData.sublistView(
          Uint8List.fromList(fixtureJson.codeUnits),
        );
      }
      return null;
    });
  });

  tearDown(() async {
    await engine.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
  });

  test('starts as uninitialized', () {
    expect(engine.status, const InferenceStatus.uninitialized());
    expect(engine.isReady, isFalse);
  });

  test('transitions to ready after initialize', () async {
    await engine.initialize();
    expect(engine.status, const InferenceStatus.ready());
    expect(engine.isReady, isTrue);
  });

  test('status stream emits transitions during initialize', () async {
    final statuses = <InferenceStatus>[];
    engine.statusStream.listen(statuses.add);

    await engine.initialize();
    await Future<void>.delayed(Duration.zero);

    expect(statuses, [
      const InferenceStatus.loading(),
      const InferenceStatus.ready(),
    ]);
  });

  test('returns failure if generate called before initialize', () async {
    final result = await engine.generate(
      const InferenceRequest(prompt: 'test'),
    );
    expect(result, isA<InferenceFailure>());
  });

  test('returns responses in sequence', () async {
    await engine.initialize();

    final result1 = await engine.generate(
      const InferenceRequest(prompt: 'msg1'),
    );
    expect(result1, isA<InferenceSuccess>());
    expect(
      (result1 as InferenceSuccess).tutorResponse!.conversation.content,
      'Muito bem!',
    );

    final result2 = await engine.generate(
      const InferenceRequest(prompt: 'msg2'),
    );
    expect(
      (result2 as InferenceSuccess).tutorResponse!.conversation.content,
      'Otimo!',
    );
  });

  test('cycles back to first response after exhausting list', () async {
    await engine.initialize();

    // Exhaust both responses
    await engine.generate(const InferenceRequest(prompt: '1'));
    await engine.generate(const InferenceRequest(prompt: '2'));

    // Third call should cycle back
    final result = await engine.generate(
      const InferenceRequest(prompt: '3'),
    );
    expect(
      (result as InferenceSuccess).tutorResponse!.conversation.content,
      'Muito bem!',
    );
  });

  test('status transitions during generate', () async {
    await engine.initialize();

    final statuses = <InferenceStatus>[];
    engine.statusStream.listen(statuses.add);

    await engine.generate(const InferenceRequest(prompt: 'test'));
    await Future<void>.delayed(Duration.zero);

    expect(statuses, [
      const InferenceStatus.generating(),
      const InferenceStatus.ready(),
    ]);
  });
}
