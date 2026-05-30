---
status: complete
depends_on: [04_core_systems/07_decouple_structured_output.md, 04_core_systems/04_conversation_repository.md, 04_core_systems/06_prompt_manager.md]
produces: [lib/services/conversation/conversation_controller.dart, lib/providers/conversation_provider.dart]
---

# Plan: ConversationController

## Goal

Orchestrate the full conversation loop: receive user input, build prompt, call
structured inference engine, handle result, persist messages, expose state to UI.
This is the primary "glue" between services.

## Design decision: StructuredInferenceEngine<TutorResponse>

The controller depends on `StructuredInferenceEngine<TutorResponse>` (from
Plan 04/07), NOT on InferenceEngine directly. This means:

- The controller never handles raw text parsing
- It receives `StructuredResult<TutorResponse>` with three explicit outcomes:
  - `StructuredSuccess` - parsed TutorResponse ready to use
  - `StructuredInferenceFailure` - engine could not generate at all
  - `StructuredParseFailure` - engine generated text but parsing failed (raw text available for fallback display)
- The parsing, extraction, and validation layers are fully encapsulated below

This keeps the controller focused on orchestration: prompt building,
calling inference, persisting messages, and exposing state.

## Implementation

`lib/services/conversation/conversation_controller.dart`:

```dart
import 'dart:async';

import '../../models/conversation.dart';
import '../../models/conversation_message.dart';
import '../../models/tutor_response.dart';
import '../inference/structured_inference_engine.dart';
import '../inference/inference_engine.dart';
import '../persistence/conversation_repository.dart';
import '../prompt/prompt_manager.dart';
import '../inference/structured_output_parser.dart';
import '../persistence/conversation_repository.dart';
import '../prompt/prompt_manager.dart';

/// Orchestrates the conversation loop between user and tutor.
///
/// Responsibilities:
/// - Build prompt from template + history + user message
/// - Call structured inference engine
/// - Persist messages to repository
/// - Expose conversation state for UI consumption
class ConversationController {
  ConversationController({
    required this.structuredEngine,
    required this.repository,
    required this.promptManager,
    this.maxHistoryMessages = 10,
  });

  final StructuredInferenceEngine<TutorResponse> structuredEngine;
  final ConversationRepository repository;
  final PromptManager promptManager;
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

    // Call structured inference engine
    final result = await structuredEngine.generate(
      InferenceRequest(prompt: prompt),
    );

    // Handle three-state result
    TutorResponse? tutorResponse;
    String replyContent;

    switch (result) {
      case StructuredSuccess(:final value):
        tutorResponse = value;
        replyContent = value.conversation.content;
      case StructuredParseFailure(:final rawText):
        // Engine generated text but parsing failed - show raw text
        replyContent = rawText;
      case StructuredInferenceFailure(:final error):
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
/// Depends on structured inference engine, repository, and prompt manager.
final conversationControllerProvider = Provider<ConversationController>((ref) {
  return ConversationController(
    structuredEngine: ref.watch(structuredInferenceEngineProvider),
    repository: ref.watch(conversationRepositoryProvider),
    promptManager: ref.watch(promptManagerProvider),
  );
});
```

## Tests

`test/services/conversation_controller_test.dart`:

- Start conversation creates and persists a new conversation
- Send message appends user and tutor messages
- StructuredSuccess: uses parsed TutorResponse, sets reply content
- StructuredParseFailure: shows raw text as reply content
- StructuredInferenceFailure: shows error fallback message
- History truncation respects maxHistoryMessages
- Stream emits updated conversation after each message

## Acceptance criteria

- [ ] ConversationController orchestrates full send/receive loop
- [ ] Uses all Phase 04 services (engine, parser, repository, prompt manager)
- [ ] Conversation stream emits updates for reactive UI
- [ ] Screens never import services directly - use provider
- [ ] Tests pass with FakeInferenceEngine
- [ ] `flutter analyze` passes
