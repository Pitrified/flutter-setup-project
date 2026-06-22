import 'dart:convert';

import 'package:fala/services/inference/inference_engine.dart';
import 'package:fala/services/inference/openai_inference_engine.dart';
import 'package:fala/services/settings/api_key_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openai_dart/openai_dart.dart';

OpenAIClient _clientWith(http.Client httpClient) =>
    OpenAIClient.withApiKey('sk-test', httpClient: httpClient);

OpenAiInferenceEngine _engineWith({
  required http.Client httpClient,
  required ApiKeyStore store,
  String model = 'gpt-4o-mini',
}) {
  return OpenAiInferenceEngine(
    apiKeyStore: store,
    modelProvider: () => model,
    clientBuilder: (_) => _clientWith(httpClient),
  );
}

/// Builds an OpenAI chat-completions SSE body from a list of content deltas.
String _sse(List<String> contents) {
  final buf = StringBuffer();
  for (final content in contents) {
    final chunk = {
      'id': 'chatcmpl-1',
      'object': 'chat.completion.chunk',
      'created': 1,
      'model': 'gpt-4o-mini',
      'choices': [
        {
          'index': 0,
          'delta': {'content': content},
          'finish_reason': null,
        },
      ],
    };
    buf.write('data: ${jsonEncode(chunk)}\n\n');
  }
  buf.write('data: [DONE]\n\n');
  return buf.toString();
}

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('streams cumulative buffers from content deltas', () async {
    final store = ApiKeyStore();
    await store.write('sk-test');
    final mock = MockClient((request) async {
      expect(request.url.path, endsWith('/chat/completions'));
      return http.Response(
        _sse(['{"correction"', ':{"content"', ':"Oi"}}']),
        200,
        headers: {'content-type': 'text/event-stream'},
      );
    });
    final engine = _engineWith(httpClient: mock, store: store);
    await engine.initialize();

    final emissions = await engine
        .generateStream(const InferenceRequest(prompt: 'oi'))
        .toList();

    expect(emissions, [
      '{"correction"',
      '{"correction":{"content"',
      '{"correction":{"content":"Oi"}}',
    ]);
  });

  test('throws InferenceStreamException when no key is stored', () async {
    final store = ApiKeyStore();
    final engine = _engineWith(
      httpClient: MockClient((_) async => http.Response('', 200)),
      store: store,
    );
    await engine.initialize();

    await expectLater(
      engine.generateStream(const InferenceRequest(prompt: 'oi')).toList(),
      throwsA(
        isA<InferenceStreamException>().having(
          (e) => e.message,
          'message',
          contains('OpenAI key missing or rejected'),
        ),
      ),
    );
  });

  test('maps HTTP 401 to a key-rejected stream failure', () async {
    final store = ApiKeyStore();
    await store.write('sk-bad');
    final mock = MockClient((_) async {
      return http.Response(
        '{"error":{"message":"invalid key","type":"invalid_request_error",'
        '"code":"invalid_api_key"}}',
        401,
        headers: {'content-type': 'application/json'},
      );
    });
    final engine = _engineWith(httpClient: mock, store: store);
    await engine.initialize();

    await expectLater(
      engine.generateStream(const InferenceRequest(prompt: 'oi')).toList(),
      throwsA(
        isA<InferenceStreamException>().having(
          (e) => e.message,
          'message',
          contains('OpenAI key missing or rejected'),
        ),
      ),
    );
  });

  test('maps HTTP 429 to a rate-limit stream failure', () async {
    final store = ApiKeyStore();
    await store.write('sk-test');
    final mock = MockClient((_) async {
      return http.Response(
        '{"error":{"message":"slow down","type":"rate_limit_error"}}',
        429,
        headers: {'content-type': 'application/json'},
      );
    });
    final engine = _engineWith(httpClient: mock, store: store);
    await engine.initialize();

    await expectLater(
      engine.generateStream(const InferenceRequest(prompt: 'oi')).toList(),
      throwsA(
        isA<InferenceStreamException>().having(
          (e) => e.message,
          'message',
          contains('rate limit'),
        ),
      ),
    );
  });

  test('throws when the stream yields no content', () async {
    final store = ApiKeyStore();
    await store.write('sk-test');
    final mock = MockClient((_) async {
      return http.Response(
        _sse(const []), // only [DONE]
        200,
        headers: {'content-type': 'text/event-stream'},
      );
    });
    final engine = _engineWith(httpClient: mock, store: store);
    await engine.initialize();

    await expectLater(
      engine.generateStream(const InferenceRequest(prompt: 'oi')).toList(),
      throwsA(
        isA<InferenceStreamException>().having(
          (e) => e.message,
          'message',
          contains('empty response'),
        ),
      ),
    );
  });
}
