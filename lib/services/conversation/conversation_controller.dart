import 'dart:async';

import '../../models/cefr_level.dart';
import '../../models/conversation.dart';
import '../../models/conversation_message.dart';
import '../../models/tutor_response.dart';
import '../inference/inference_engine.dart';
import '../inference/structured_inference_engine.dart';
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
    CefrLevel cefrLevel = CefrLevel.a1,
    String topic = '',
  }) async {
    final now = DateTime.now();
    final conversation = Conversation(
      id: now.millisecondsSinceEpoch.toString(),
      createdAt: now,
      updatedAt: now,
      messages: [],
      language: language,
      cefrLevel: cefrLevel.displayName,
      topic: topic,
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

  /// Update the CEFR level of the active conversation without restarting it.
  ///
  /// The new level is persisted to the repository and is used by the very
  /// next prompt. Returns immediately if there is no active conversation or
  /// the level is unchanged.
  Future<void> setCefrLevel(CefrLevel level) async {
    final current = _currentConversation;
    if (current == null) return;
    final newLevel = level.displayName;
    if (current.cefrLevel == newLevel) return;
    final updated = current.copyWith(
      cefrLevel: newLevel,
      updatedAt: DateTime.now(),
    );
    await repository.save(updated);
    _currentConversation = updated;
    _conversationController.add(updated);
  }

  /// Update the topic of the active conversation without restarting it.
  ///
  /// Empty string clears the topic. Trims [topic] before persisting.
  Future<void> setTopic(String topic) async {
    final current = _currentConversation;
    if (current == null) return;
    final trimmed = topic.trim();
    if (current.topic == trimmed) return;
    final updated = current.copyWith(
      topic: trimmed,
      updatedAt: DateTime.now(),
    );
    await repository.save(updated);
    _currentConversation = updated;
    _conversationController.add(updated);
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
        'topic': _currentConversation!.topic,
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
        replyContent = rawText;
      case StructuredInferenceFailure(:final error):
        replyContent = 'Error generating response: $error';
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
