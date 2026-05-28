import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/conversation/conversation_controller.dart';
import 'inference_provider.dart';
import 'service_providers.dart';

/// Provider for the ConversationController.
///
/// Depends on structured inference engine, repository, and prompt manager.
final conversationControllerProvider = Provider<ConversationController>((ref) {
  return ConversationController(
    structuredEngine: ref.watch(structuredInferenceEngineProvider),
    repository: ref.watch(conversationRepositoryProvider),
    promptManager: ref.watch(promptManagerProvider),
  );
});
