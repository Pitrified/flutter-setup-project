import 'package:fala/services/inference/engine_kind.dart';
import 'package:fala/services/inference/engine_registry.dart';
import 'package:fala/services/inference/fake_inference_engine.dart';
import 'package:fala/services/inference/flutter_gemma_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('engineFactoryFor', () {
    test('returns a FakeInferenceEngine factory for EngineKind.fake', () {
      final factory = engineFactoryFor(EngineKind.fake);
      expect(factory(''), isA<FakeInferenceEngine>());
    });

    test('returns a FlutterGemmaEngine factory for EngineKind.gemma', () {
      final factory = engineFactoryFor(EngineKind.gemma);
      expect(factory('some/path'), isA<FlutterGemmaEngine>());
    });

    test('throws UnimplementedError for EngineKind.openai (lands in 03.2)',
        () {
      expect(
        () => engineFactoryFor(EngineKind.openai),
        throwsUnimplementedError,
      );
    });
  });

  group('skipModelCheckFor', () {
    test('returns true for fake and openai, false for gemma', () {
      expect(skipModelCheckFor(EngineKind.fake), isTrue);
      expect(skipModelCheckFor(EngineKind.openai), isTrue);
      expect(skipModelCheckFor(EngineKind.gemma), isFalse);
    });
  });

  group('EngineKindX', () {
    test('isImplemented matches what the registry supports today', () {
      expect(EngineKind.fake.isImplemented, isTrue);
      expect(EngineKind.gemma.isImplemented, isTrue);
      expect(EngineKind.openai.isImplemented, isFalse);
    });

    test('displayName is non-empty for every value', () {
      for (final kind in EngineKind.values) {
        expect(kind.displayName, isNotEmpty);
      }
    });
  });
}
