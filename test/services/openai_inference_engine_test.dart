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

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('generate returns failure when no key is stored', () async {
    final store = ApiKeyStore();
    final engine = _engineWith(
      httpClient: MockClient((_) async => http.Response('', 200)),
      store: store,
    );
    await engine.initialize();
    final result = await engine.generate(
      const InferenceRequest(prompt: 'oi'),
    );
    expect(result, isA<InferenceFailure>());
    expect(
      (result as InferenceFailure).error,
      contains('OpenAI key missing or rejected'),
    );
  });

  test('generate returns success with the raw JSON body content', () async {
    final store = ApiKeyStore();
    await store.write('sk-test');
    const rawJson =
        '{"correction":{"content":"","translation":"","errors":[]},'
        '"conversation":{"content":"Oi!","translation":"Hi!"}}';
    final mock = MockClient((request) async {
      expect(request.url.path, endsWith('/chat/completions'));
      return http.Response(
        '{'
        '"id":"chatcmpl-1",'
        '"object":"chat.completion",'
        '"created":1,'
        '"model":"gpt-4o-mini",'
        '"choices":[{"index":0,"finish_reason":"stop","message":'
        '{"role":"assistant","content":${_jsonString(rawJson)}}}]'
        '}',
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final engine = _engineWith(httpClient: mock, store: store);
    await engine.initialize();
    final result = await engine.generate(
      const InferenceRequest(prompt: 'oi'),
    );
    expect(result, isA<InferenceSuccess>());
    expect((result as InferenceSuccess).rawText, rawJson);
  });

  test('generate maps HTTP 401 to a "key rejected" failure', () async {
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
    final result = await engine.generate(
      const InferenceRequest(prompt: 'oi'),
    );
    expect(result, isA<InferenceFailure>());
    expect(
      (result as InferenceFailure).error,
      contains('OpenAI key missing or rejected'),
    );
  });

  test('generate maps HTTP 429 to a rate-limit failure', () async {
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
    final result = await engine.generate(
      const InferenceRequest(prompt: 'oi'),
    );
    expect(result, isA<InferenceFailure>());
    expect(
      (result as InferenceFailure).error,
      contains('rate limit'),
    );
  });

  test('generate returns failure when response has empty content', () async {
    final store = ApiKeyStore();
    await store.write('sk-test');
    final mock = MockClient((_) async {
      return http.Response(
        '{'
        '"id":"x","object":"chat.completion","created":1,"model":"m",'
        '"choices":[{"index":0,"finish_reason":"stop","message":'
        '{"role":"assistant","content":""}}]'
        '}',
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final engine = _engineWith(httpClient: mock, store: store);
    await engine.initialize();
    final result = await engine.generate(
      const InferenceRequest(prompt: 'oi'),
    );
    expect(result, isA<InferenceFailure>());
    expect(
      (result as InferenceFailure).error,
      contains('empty response'),
    );
  });
}

/// Encode [s] as a JSON string literal (quoted, with escapes).
String _jsonString(String s) {
  final buf = StringBuffer('"');
  for (final code in s.codeUnits) {
    switch (code) {
      case 0x22:
        buf.write(r'\"');
      case 0x5c:
        buf.write(r'\\');
      case 0x0a:
        buf.write(r'\n');
      case 0x0d:
        buf.write(r'\r');
      case 0x09:
        buf.write(r'\t');
      default:
        if (code < 0x20) {
          buf.write('\\u${code.toRadixString(16).padLeft(4, '0')}');
        } else {
          buf.writeCharCode(code);
        }
    }
  }
  buf.write('"');
  return buf.toString();
}
