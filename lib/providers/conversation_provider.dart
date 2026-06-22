import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/conversation/conversation_controller.dart';
import 'inference_provider.dart';
import 'service_providers.dart';

/// Provider for the ConversationController.
///
/// Returns null when the inference engine is not yet initialized.
/// Depends on structured inference engine, repository, and prompt manager.
final conversationControllerProvider =
    Provider<ConversationController?>((ref) {
  final streamEngine = ref.watch(structuredStreamEngineProvider);
  if (streamEngine == null) return null;
  return ConversationController(
    streamEngine: streamEngine,
    repository: ref.watch(conversationRepositoryProvider),
    promptManager: ref.watch(promptManagerProvider),
  );
});
