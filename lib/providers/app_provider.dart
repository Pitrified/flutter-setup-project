import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/app/app_controller.dart';
import 'inference_provider.dart';
import 'service_providers.dart';

/// Provider for the AppController.
final appControllerProvider = Provider<AppController>((ref) {
  return AppController(
    modelManager: ref.watch(modelManagerProvider),
    engine: ref.watch(inferenceEngineProvider),
  );
});
