import 'dart:async';

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
        replyContent = rawText;
      case StructuredInferenceFailure():
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
