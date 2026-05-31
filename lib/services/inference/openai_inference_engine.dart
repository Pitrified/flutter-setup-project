import 'dart:async';

import 'package:openai_dart/openai_dart.dart';

import '../../models/inference_status.dart';
import '../settings/api_key_store.dart';
import 'inference_engine.dart';
import 'tutor_response_schema.dart';

/// Builds an [OpenAIClient] from an API key.
///
/// Exposed as a typedef so tests can inject a fake-client builder without
/// hitting the network. Production callers use [defaultOpenAIClientBuilder].
typedef OpenAIClientBuilder = OpenAIClient Function(String apiKey);

/// Default builder: real OpenAI HTTP client.
OpenAIClient defaultOpenAIClientBuilder(String apiKey) =>
    OpenAIClient.withApiKey(apiKey);

/// Cloud inference engine backed by the OpenAI Chat Completions API.
///
/// Implements [InferenceEngine] so the rest of the app (notably
/// `StructuredInferenceEngine<T>`) can swap between this and the on-device
/// engines without code changes. Output is constrained to the
/// [tutorResponseJsonSchema] using OpenAI's strict structured-output mode, so
/// the parser downstream sees well-formed JSON.
///
/// The engine reads the API key and model id on every [generate] call so
/// changes persisted via Settings are picked up without re-initializing the
/// engine. The underlying [OpenAIClient] is rebuilt only when the key
/// actually changes.
class OpenAiInferenceEngine implements InferenceEngine {
  OpenAiInferenceEngine({
    required this.apiKeyStore,
    required this.modelProvider,
    this.clientBuilder = defaultOpenAIClientBuilder,
    this.schemaName = 'tutor_response',
    this.schema = tutorResponseJsonSchema,
  });

  /// Secure storage for the OpenAI API key. Read on every generate.
  final ApiKeyStore apiKeyStore;

  /// Resolves the active model id on every call (e.g. `'gpt-4o-mini'`).
  final String Function() modelProvider;

  /// Constructs an [OpenAIClient] from an API key. Tests inject a fake.
  final OpenAIClientBuilder clientBuilder;

  /// Schema name passed to OpenAI; surfaced in error responses for debugging.
  final String schemaName;

  /// JSON Schema enforced via `response_format: json_schema` (strict mode).
  final Map<String, dynamic> schema;

  final _statusController = StreamController<InferenceStatus>.broadcast();
  InferenceStatus _status = const InferenceStatus.uninitialized();

  OpenAIClient? _client;
  String? _cachedKey;

  @override
  InferenceStatus get status => _status;

  @override
  Stream<InferenceStatus> get statusStream => _statusController.stream;

  @override
  bool get isReady => _status == const InferenceStatus.ready();

  @override
  Future<void> initialize() async {
    // No network call: key validity is verified lazily on the first
    // [generate] so engine swaps are instantaneous.
    _setStatus(const InferenceStatus.ready());
  }

  @override
  Future<InferenceResult> generate(InferenceRequest request) async {
    if (!isReady) {
      return const InferenceFailure(error: 'Engine not initialized');
    }
    final key = await apiKeyStore.read();
    if (key == null || key.isEmpty) {
      return const InferenceFailure(
        error: 'OpenAI key missing or rejected. Open Settings to update.',
      );
    }
    _setStatus(const InferenceStatus.generating());
    try {
      final client = _clientFor(key);
      final response = await client.chat.completions.create(
        ChatCompletionCreateRequest(
          model: modelProvider(),
          messages: [ChatMessage.user(request.prompt)],
          maxCompletionTokens: request.maxTokens,
          temperature: request.temperature,
          responseFormat: ResponseFormat.jsonSchema(
            name: schemaName,
            schema: schema,
          ),
        ),
      );
      final raw = response.choices.isEmpty
          ? ''
          : (response.choices.first.message.content ?? '');
      _setStatus(const InferenceStatus.ready());
      if (raw.isEmpty) {
        return const InferenceFailure(error: 'OpenAI returned empty response');
      }
      return InferenceSuccess(rawText: raw);
    } on AuthenticationException {
      _setStatus(const InferenceStatus.ready());
      return const InferenceFailure(
        error: 'OpenAI key missing or rejected. Open Settings to update.',
      );
    } on RateLimitException {
      _setStatus(const InferenceStatus.ready());
      return const InferenceFailure(
        error: 'OpenAI rate limit reached. Try again shortly.',
      );
    } on RequestTimeoutException {
      _setStatus(const InferenceStatus.ready());
      return const InferenceFailure(
        error: 'OpenAI request timed out. Check your connection.',
      );
    } on ConnectionException {
      _setStatus(const InferenceStatus.ready());
      return const InferenceFailure(
        error: 'Network error reaching OpenAI. Check your connection.',
      );
    } on OpenAIException catch (e) {
      _setStatus(const InferenceStatus.ready());
      return InferenceFailure(error: 'OpenAI error: ${e.message}');
    }
  }

  OpenAIClient _clientFor(String key) {
    if (_client != null && _cachedKey == key) {
      return _client!;
    }
    _client?.close();
    _cachedKey = key;
    _client = clientBuilder(key);
    return _client!;
  }

  @override
  Future<void> dispose() async {
    _client?.close();
    _client = null;
    await _statusController.close();
  }

  void _setStatus(InferenceStatus status) {
    _status = status;
    _statusController.add(status);
  }
}
