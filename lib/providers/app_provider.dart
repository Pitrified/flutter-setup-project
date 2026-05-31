import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/model_config.dart';
import '../services/app/app_controller.dart';
import '../services/inference/engine_registry.dart';
import 'inference_provider.dart';
import 'settings_provider.dart';

/// Whether to skip model file verification during app init.
///
/// Derived from the selected engine kind: only the on-device Gemma engine
/// needs a model file on disk. Tests may still override this provider.
final skipModelCheckProvider = Provider<bool>((ref) {
  final kind = ref.watch(selectedEngineKindProvider);
  return skipModelCheckFor(kind);
});

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
