import '../../providers/inference_provider.dart';
import 'engine_kind.dart';
import 'fake_inference_engine.dart';
import 'flutter_gemma_engine.dart';

/// Returns the [EngineFactory] registered for [kind].
///
/// Adding a new engine is a single entry in this switch plus a new
/// [EngineKind] value.
///
/// Throws [UnimplementedError] for kinds whose factory has not been wired up
/// yet. 03.2 replaces the [EngineKind.openai] branch with the real factory.
EngineFactory engineFactoryFor(EngineKind kind) {
  switch (kind) {
    case EngineKind.fake:
      return (_) => FakeInferenceEngine();
    case EngineKind.gemma:
      return (modelPath) => FlutterGemmaEngine(modelPath: modelPath);
    case EngineKind.openai:
      throw UnimplementedError(
        'OpenAI engine is wired up in plan 03.2; not available yet.',
      );
  }
}

/// Whether the model-check step should be skipped for [kind].
///
/// Only the on-device Gemma engine requires a downloaded model file on disk.
bool skipModelCheckFor(EngineKind kind) => kind != EngineKind.gemma;
