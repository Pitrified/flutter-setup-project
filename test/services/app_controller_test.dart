import 'package:fala/models/inference_status.dart';
import 'package:fala/models/model_metadata.dart';
import 'package:fala/services/app/app_controller.dart';
import 'package:fala/services/inference/inference_engine.dart';
import 'package:fala/services/model/model_manager.dart';
import 'package:flutter_test/flutter_test.dart';

/// Minimal fake ModelManager for testing AppController.
class _FakeModelManager extends ModelManager {
  ModelMetadata? modelToReturn;

  @override
  Future<ModelMetadata?> getDownloadedModel(String modelName) async {
    return modelToReturn;
  }
}

/// Minimal fake InferenceEngine for testing AppController.
class _FakeEngine implements InferenceEngine {
  bool initializeCalled = false;
  bool shouldBeReady = true;

  @override
  InferenceStatus get status => shouldBeReady
      ? const InferenceStatus.ready()
      : const InferenceStatus.uninitialized();

  @override
  bool get isReady => initializeCalled && shouldBeReady;

  @override
  Stream<InferenceStatus> get statusStream => const Stream.empty();

  @override
  Future<void> initialize() async {
    initializeCalled = true;
  }

  @override
  Future<InferenceResult> generate(InferenceRequest request) async {
    return const InferenceFailure(error: 'not implemented');
  }

  @override
  Future<void> dispose() async {}
}

void main() {
  late _FakeModelManager modelManager;
  late _FakeEngine engine;
  late AppController controller;

  setUp(() {
    modelManager = _FakeModelManager();
    engine = _FakeEngine();
    controller = AppController(
      modelManager: modelManager,
      engine: engine,
    );
  });

  tearDown(() async {
    await controller.dispose();
  });

  test('initial state is AppLoading', () {
    expect(controller.state, isA<AppLoading>());
  });

  test('sets AppNeedsModel when model not downloaded', () async {
    modelManager.modelToReturn = null;

    await controller.initialize();

    expect(controller.state, isA<AppNeedsModel>());
    expect(engine.initializeCalled, isFalse);
  });

  test('sets AppReady when model exists and engine initializes', () async {
    modelManager.modelToReturn = ModelMetadata(
      name: 'gemma3-1b-it.task',
      filePath: '/fake/path',
      fileSizeBytes: 1000,
      downloadedAt: DateTime(2024),
    );

    await controller.initialize();

    expect(controller.state, isA<AppReady>());
    expect(engine.initializeCalled, isTrue);
  });

  test('sets AppError when engine fails to initialize', () async {
    modelManager.modelToReturn = ModelMetadata(
      name: 'gemma3-1b-it.task',
      filePath: '/fake/path',
      fileSizeBytes: 1000,
      downloadedAt: DateTime(2024),
    );
    engine.shouldBeReady = false;

    await controller.initialize();

    expect(controller.state, isA<AppError>());
  });

  test('stateStream emits state changes', () async {
    modelManager.modelToReturn = null;

    final states = <AppState>[];
    controller.stateStream.listen(states.add);

    await controller.initialize();
    await Future<void>.delayed(Duration.zero);

    expect(states, hasLength(2));
    expect(states[0], isA<AppLoading>());
    expect(states[1], isA<AppNeedsModel>());
  });

  test('onModelDownloaded retries initialization', () async {
    modelManager.modelToReturn = ModelMetadata(
      name: 'gemma3-1b-it.task',
      filePath: '/fake/path',
      fileSizeBytes: 1000,
      downloadedAt: DateTime(2024),
    );

    await controller.onModelDownloaded();

    expect(controller.state, isA<AppReady>());
  });
}
