import 'dart:async';

import '../../models/cefr_level.dart';
import '../../models/conversation.dart';
import '../../models/conversation_message.dart';
import '../../models/tutor_response.dart';
import '../inference/inference_engine.dart';
import '../inference/structured_stream_engine.dart';
import '../persistence/conversation_repository.dart';
import '../prompt/prompt_manager.dart';

/// Orchestrates the conversation loop between user and tutor.
///
/// Responsibilities:
/// - Build prompt from template + history + user message
/// - Drive the structured streaming engine, exposing live partial deltas
/// - Persist the final message to repository (from the terminal delta's value)
/// - Expose conversation state for UI consumption
class ConversationController {
  ConversationController({
    required this.streamEngine,
    required this.repository,
    required this.promptManager,
    this.maxHistoryMessages = 10,
  });

  /// Streaming engine for the in-flight turn. Its terminal delta carries the
  /// same fully-typed value the one-shot path would produce, which is what we
  /// persist.
  final StructuredStreamEngine<TutorResponse> streamEngine;
  final ConversationRepository repository;
  final PromptManager promptManager;
  final int maxHistoryMessages;

  Conversation? _currentConversation;
  final _conversationController = StreamController<Conversation?>.broadcast();

  /// Live, ephemeral partial deltas for the in-flight tutor turn. Events flow
  /// only during a [sendMessage]; the UI overlays them on top of the committed
  /// [conversationStream]. Broadcast so it can be (re)bound across turns.
  final _streamingReplyController =
      StreamController<StructuredDelta<TutorResponse>>.broadcast();

  bool _isSending = false;

  /// Stream of conversation updates for reactive UI.
  Stream<Conversation?> get conversationStream =>
      _conversationController.stream;

  /// Live partial deltas for the in-flight tutor reply (empty between sends).
  Stream<StructuredDelta<TutorResponse>> get streamingReply =>
      _streamingReplyController.stream;

  /// Whether a [sendMessage] is currently streaming.
  bool get isSending => _isSending;

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
  /// Streams partial deltas to [streamingReply] as the reply arrives, then
  /// persists the final tutor message built from the terminal delta's typed
  /// value (identical to the one-shot result). Returns the tutor's
  /// ConversationMessage, or null if there is no active conversation or a send
  /// is already in flight (concurrent sends are ignored; the UI also gates).
  Future<ConversationMessage?> sendMessage(String content) async {
    if (_currentConversation == null) return null;
    if (_isSending) return null;
    _isSending = true;

    try {
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

      // Drive the streaming engine: forward each partial delta to the live
      // channel and remember the terminal one for persistence.
      StructuredDelta<TutorResponse>? terminal;
      await for (final delta in streamEngine.generateStream(
        InferenceRequest(prompt: prompt),
      )) {
        if (!_streamingReplyController.isClosed) {
          _streamingReplyController.add(delta);
        }
        if (delta.isTerminal) terminal = delta;
      }

      final (replyContent, tutorResponse) = _resolveReply(terminal);

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
    } finally {
      _isSending = false;
    }
  }

  /// Map the terminal delta to the persisted reply, preserving the existing
  /// three-state outcome: typed success -> reply text + value; parse failure ->
  /// the raw text; inference failure -> the error fallback text.
  (String, TutorResponse?) _resolveReply(
    StructuredDelta<TutorResponse>? terminal,
  ) {
    if (terminal == null) {
      return ('Error generating response: no response received', null);
    }
    if (terminal.isComplete && terminal.value != null) {
      final value = terminal.value!;
      return (value.conversation.content, value);
    }
    final failure = terminal.failure;
    if (failure != null) {
      return switch (failure.kind) {
        StructuredFailureKind.parse => (failure.rawText ?? '', null),
        StructuredFailureKind.inference => (
            'Error generating response: ${failure.error}',
            null,
          ),
      };
    }
    return ('Error generating response: unknown', null);
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
    await _streamingReplyController.close();
  }
}
