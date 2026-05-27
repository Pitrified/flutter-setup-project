---
status: not-started
depends_on: [04_core_systems/00_inference_interface.md, 04_core_systems/03_structured_output.md, 04_core_systems/04_conversation_repository.md, 04_core_systems/06_prompt_manager.md]
produces: [lib/services/conversation/conversation_controller.dart, lib/providers/conversation_provider.dart]
---

# Plan: ConversationController

## Goal

Orchestrate the full conversation loop: receive user input, build prompt, call
inference engine, parse output, persist messages, expose state to UI. This is
the primary "glue" between services.

## Implementation

`lib/services/conversation/conversation_controller.dart`:

```dart
import 'dart:async';

import '../../models/conversation.dart';
import '../../models/conversation_message.dart';
import '../../models/tutor_response.dart';
import '../inference/inference_engine.dart';
import '../inference/structured_output_parser.dart';
import '../persistence/conversation_repository.dart';
import '../prompt/prompt_manager.dart';

/// Orchestrates the conversation loop between user and tutor.
///
/// Responsibilities:
/// - Build prompt from template + history + user message
/// - Call inference engine and parse structured output
/// - Persist messages to repository
/// - Expose conversation state for UI consumption
class ConversationController {
  ConversationController({
    required this.engine,
    required this.repository,
    required this.promptManager,
    this.parser = const StructuredOutputParser(),
    this.maxHistoryMessages = 10,
  });

  final InferenceEngine engine;
  final ConversationRepository repository;
  final PromptManager promptManager;
  final StructuredOutputParser parser;
  final int maxHistoryMessages;

  Conversation? _currentConversation;
  final _conversationController = StreamController<Conversation?>.broadcast();

  /// Stream of conversation updates for reactive UI.
  Stream<Conversation?> get conversationStream =>
      _conversationController.stream;

  /// Current active conversation.
  Conversation? get currentConversation => _currentConversation;

  /// Start a new conversation.
  Future<Conversation> startConversation({
    String language = 'pt-BR',
    String cefrLevel = 'A1',
  }) async {
    final now = DateTime.now();
    final conversation = Conversation(
      id: now.millisecondsSinceEpoch.toString(),
      createdAt: now,
      updatedAt: now,
      messages: [],
      language: language,
      cefrLevel: cefrLevel,
    );
    await repository.save(conversation);
    _currentConversation = conversation;
    _conversationController.add(conversation);
    return conversation;
  }

  /// Load an existing conversation by ID.
  Future<void> loadConversation(String id) async {
    _currentConversation = repository.load(id);
    _conversationController.add(_currentConversation);
  }

  /// Send a user message and get a tutor response.
  ///
  /// Returns the tutor's ConversationMessage (or null on failure).
  Future<ConversationMessage?> sendMessage(String content) async {
    if (_currentConversation == null) return null;

    final userMessage = ConversationMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: MessageRole.user,
      content: content,
      timestamp: DateTime.now(),
    );

    _currentConversation = await repository.appendMessage(
      _currentConversation!.id,
      userMessage,
    );
    _conversationController.add(_currentConversation);

    // Build prompt
    final prompt = await promptManager.buildPrompt(
      name: 'tutor_response',
      variables: {
        'cefr_level': _currentConversation!.cefrLevel,
        'user_message': content,
        'conversation_history': _formatHistory(),
      },
    );

    // Call inference
    final result = await engine.generate(InferenceRequest(prompt: prompt));

    // Parse response
    TutorResponse? tutorResponse;
    String replyContent;

    if (result is InferenceSuccess) {
      final parsed = parser.parse(result.rawText);
      if (parsed is ParseSuccess) {
        tutorResponse = parsed.response;
        replyContent = tutorResponse.conversation.content;
      } else {
        replyContent = result.rawText;
      }
    } else {
      replyContent = 'Sorry, I could not generate a response.';
    }

    final tutorMessage = ConversationMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: MessageRole.tutor,
      content: replyContent,
      timestamp: DateTime.now(),
      tutorResponse: tutorResponse,
    );

    _currentConversation = await repository.appendMessage(
      _currentConversation!.id,
      tutorMessage,
    );
    _conversationController.add(_currentConversation);
    return tutorMessage;
  }

  /// Format recent history for prompt context.
  String _formatHistory() {
    if (_currentConversation == null) return '';
    final messages = _currentConversation!.messages;
    final recent = messages.length > maxHistoryMessages
        ? messages.sublist(messages.length - maxHistoryMessages)
        : messages;
    return recent.map((m) {
      final role = m.role == MessageRole.user ? 'User' : 'Tutor';
      return '$role: ${m.content}';
    }).join('\n');
  }

  /// Dispose resources.
  Future<void> dispose() async {
    await _conversationController.close();
  }
}
```

## Provider

`lib/providers/conversation_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/inference_provider.dart';
import '../providers/service_providers.dart';
import '../services/conversation/conversation_controller.dart';

/// Provider for the ConversationController.
///
/// Depends on inference engine, repository, and prompt manager.
final conversationControllerProvider = Provider<ConversationController>((ref) {
  return ConversationController(
    engine: ref.watch(inferenceEngineProvider),
    repository: ref.watch(conversationRepositoryProvider),
    promptManager: ref.watch(promptManagerProvider),
  );
});
```

## Tests

`test/services/conversation_controller_test.dart`:

- Start conversation creates and persists a new conversation
- Send message appends user and tutor messages
- Tutor response is parsed into TutorResponse on success
- Failed inference shows fallback message
- Invalid JSON output shows raw text
- History truncation respects maxHistoryMessages

## Acceptance criteria

- [ ] ConversationController orchestrates full send/receive loop
- [ ] Uses all Phase 04 services (engine, parser, repository, prompt manager)
- [ ] Conversation stream emits updates for reactive UI
- [ ] Screens never import services directly - use provider
- [ ] Tests pass with FakeInferenceEngine
- [ ] `flutter analyze` passes
