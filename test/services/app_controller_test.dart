import 'package:fala/models/inference_status.dart';
import 'package:fala/services/app/app_controller.dart';
import 'package:fala/services/inference/inference_engine.dart';
import 'package:flutter_test/flutter_test.dart';

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
  late _FakeEngine engine;
  late AppController controller;
  late bool modelInstalled;
  InferenceEngine? readyEngine;

  setUp(() {
    engine = _FakeEngine();
    readyEngine = null;
    modelInstalled = false;
    controller = AppController(
      engineFactory: (_) => engine,
      modelChecker: () async => modelInstalled,
      onEngineReady: (e) => readyEngine = e,
    );
  });

  tearDown(() async {
    await controller.dispose();
  });

  test('initial state is AppLoading', () {
    expect(controller.state, isA<AppLoading>());
  });

  test('sets AppNeedsModel when model not installed', () async {
    modelInstalled = false;

    await controller.initialize();

    expect(controller.state, isA<AppNeedsModel>());
    expect(engine.initializeCalled, isFalse);
  });

  test('sets AppReady when model exists and engine initializes', () async {
    modelInstalled = true;

    await controller.initialize();

    expect(controller.state, isA<AppReady>());
    expect(engine.initializeCalled, isTrue);
    expect(readyEngine, same(engine));
  });

  test('sets AppError when engine fails to initialize', () async {
    modelInstalled = true;
    engine.shouldBeReady = false;

    await controller.initialize();

    expect(controller.state, isA<AppError>());
  });

  test('stateStream emits state changes', () async {
    modelInstalled = false;

    final states = <AppState>[];
    controller.stateStream.listen(states.add);

    await controller.initialize();
    await Future<void>.delayed(Duration.zero);

    expect(states, hasLength(2));
    expect(states[0], isA<AppLoading>());
    expect(states[1], isA<AppNeedsModel>());
  });

  test('onModelDownloaded retries initialization', () async {
    modelInstalled = true;

    await controller.onModelDownloaded();

    expect(controller.state, isA<AppReady>());
  });
}
