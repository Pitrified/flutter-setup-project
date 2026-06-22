import 'dart:convert';

import 'package:fala/models/inference_status.dart';
import 'package:fala/services/inference/fake_inference_engine.dart';
import 'package:fala/services/inference/inference_engine.dart';
import 'package:fala/services/inference/partial_json_parser.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // A single fixture long enough that small chunks land mid-string and
  // mid-array element.
  const fixtureJson = '''
[
  {
    "correction": {
      "content": "Eu gosto de cafe",
      "translation": "I like coffee",
      "errors": [
        {"original": "cafe", "corrected": "cafe", "explanation": "accent"}
      ]
    },
    "conversation": {
      "content": "Muito bem!",
      "translation": "Very good!"
    }
  }
]
''';

  late FakeInferenceEngine engine;

  setUp(() {
    engine = FakeInferenceEngine(
      responseDelayMs: 0,
      streamChunkSize: 8,
      streamChunkDelayMs: 0,
    );

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

  test('throws before initialize', () {
    expect(
      engine.generateStream(const InferenceRequest(prompt: 'x')).toList(),
      throwsA(isA<InferenceStreamException>()),
    );
  });

  test('emits monotonically growing cumulative buffers', () async {
    await engine.initialize();

    final emissions = await engine
        .generateStream(const InferenceRequest(prompt: 'x'))
        .toList();

    expect(emissions.length, greaterThan(1));
    for (var i = 1; i < emissions.length; i++) {
      // Each emission is a prefix-extension of the previous one.
      expect(emissions[i].startsWith(emissions[i - 1]), isTrue);
      expect(emissions[i].length, greaterThan(emissions[i - 1].length));
    }
  });

  test('final emission equals the full fixture JSON', () async {
    await engine.initialize();

    final emissions = await engine
        .generateStream(const InferenceRequest(prompt: 'x'))
        .toList();

    final firstResponse = (jsonDecode(fixtureJson) as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .first;
    expect(emissions.last, jsonEncode(firstResponse));
    expect(jsonDecode(emissions.last), firstResponse);
  });

  test('at least one intermediate emission is a valid partial map', () async {
    await engine.initialize();

    const parser = PartialJsonParser();
    final emissions = await engine
        .generateStream(const InferenceRequest(prompt: 'x'))
        .toList();

    // Drop the final (complete) emission; the rest are genuinely partial.
    final intermediates = emissions.sublist(0, emissions.length - 1);
    expect(intermediates, isNotEmpty);

    // Every intermediate round-trips through phase 1 to some best-effort map,
    // and at least one is a strict prefix that is not yet closed.
    final partials = intermediates.map(parser.parse).toList();
    expect(
      partials.any((p) => !p.closure.closed && p.value.isNotEmpty),
      isTrue,
    );
  });

  test('status transitions ready -> generating -> ready', () async {
    await engine.initialize();

    final statuses = <InferenceStatus>[];
    engine.statusStream.listen(statuses.add);

    await engine.generateStream(const InferenceRequest(prompt: 'x')).toList();
    await Future<void>.delayed(Duration.zero);

    expect(statuses.first, const InferenceStatus.generating());
    expect(statuses.last, const InferenceStatus.ready());
  });

  test('bufferedGenerateStream emits the one-shot result once', () async {
    await engine.initialize();

    final emissions =
        await bufferedGenerateStream(engine, const InferenceRequest(prompt: 'x'))
            .toList();

    expect(emissions, hasLength(1));
    expect(jsonDecode(emissions.single), isA<Map<String, dynamic>>());
  });
}
