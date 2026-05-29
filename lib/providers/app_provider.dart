import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/app/app_controller.dart';
import '../services/inference/fake_inference_engine.dart';
import 'inference_provider.dart';
import 'service_providers.dart';

/// Provider for the AppController.
final appControllerProvider = Provider<AppController>((ref) {
  final engine = ref.watch(inferenceEngineProvider);
  return AppController(
    modelManager: ref.watch(modelManagerProvider),
    engine: engine,
    skipModelCheck: engine is FakeInferenceEngine,
  );
});
