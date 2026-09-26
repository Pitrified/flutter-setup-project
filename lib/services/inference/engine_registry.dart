import '../settings/api_key_store.dart';
import '../settings/app_settings_repository.dart';
import 'engine_kind.dart';
import 'fake_inference_engine.dart';
import 'flutter_gemma_engine.dart';
import 'inference_engine.dart';
import 'openai_inference_engine.dart';
import 'tutor_response_schema.dart';

/// Factory that creates an [InferenceEngine] given a model file path.
///
/// Engines that need no model file ignore the path.
typedef EngineFactory = InferenceEngine Function(String modelPath);

/// Dependencies the registry hands to engine factories that need them.
///
/// `fake` and `gemma` ignore everything in here; `openai` uses the API key
/// store and reads its model id from the settings repo on every call.
class EngineRegistryDeps {
  const EngineRegistryDeps({
    required this.apiKeyStore,
    required this.settings,
  });

  final ApiKeyStore apiKeyStore;
  final AppSettingsRepository settings;
}

/// Returns the [EngineFactory] registered for [kind].
///
/// Adding a new engine is a single entry in this switch plus a new
/// [EngineKind] value.
EngineFactory engineFactoryFor(EngineKind kind, EngineRegistryDeps deps) {
  switch (kind) {
    case EngineKind.fake:
      return (_) => FakeInferenceEngine();
    case EngineKind.gemma:
      return (modelPath) => FlutterGemmaEngine(modelPath: modelPath);
    case EngineKind.openai:
      return (_) => OpenAiInferenceEngine(
        apiKeyStore: deps.apiKeyStore,
        modelProvider: deps.settings.openaiModel,
        schemaName: 'tutor_response',
        schema: tutorResponseJsonSchema,
      );
  }
}

/// Whether the model-check step should be skipped for [kind].
///
/// Only the on-device Gemma engine requires a downloaded model file on disk.
bool skipModelCheckFor(EngineKind kind) => kind != EngineKind.gemma;
