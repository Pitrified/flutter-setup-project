import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/model_config.dart';
import '../services/app/app_controller.dart';
import 'inference_provider.dart';

/// Whether to skip model file verification during app init.
///
/// Set to true when using FakeInferenceEngine (dev/test builds).
final skipModelCheckProvider = Provider<bool>((ref) => false);

/// Provider for the AppController.
final appControllerProvider = Provider<AppController>((ref) {
  final factory = ref.watch(engineFactoryProvider);
  return AppController(
    engineFactory: factory,
    modelChecker: () => FlutterGemma.isModelInstalled(
      ModelConfig.defaultModelFileName,
    ),
    onEngineReady: (engine) {
      ref.read(inferenceEngineProvider.notifier).setEngine(engine);
    },
    skipModelCheck: ref.watch(skipModelCheckProvider),
  );
});
