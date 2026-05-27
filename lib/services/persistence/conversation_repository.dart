import 'dart:convert';

import 'package:hive/hive.dart';

import '../../models/conversation.dart';
import '../../models/conversation_message.dart';

/// Hive-backed repository for conversation persistence.
///
/// Stores conversations as JSON strings in a Hive box.
/// Each conversation is keyed by its ID.
class ConversationRepository {
  ConversationRepository({this.boxName = 'conversations'});

  final String boxName;
  late Box<String> _box;

  /// Open the Hive box. Must be called before any other method.
  Future<void> initialize() async {
    _box = await Hive.openBox<String>(boxName);
  }

  /// Save or update a conversation.
  Future<void> save(Conversation conversation) async {
    final json = jsonEncode(conversation.toJson());
    await _box.put(conversation.id, json);
  }

  /// Load a conversation by ID. Returns null if not found.
  Conversation? load(String id) {
    final json = _box.get(id);
    if (json == null) return null;
    return Conversation.fromJson(
      jsonDecode(json) as Map<String, dynamic>,
    );
  }

  /// List all conversations, sorted by updatedAt descending.
  List<Conversation> listAll() {
    return _box.values
        .map(
          (json) => Conversation.fromJson(
            jsonDecode(json) as Map<String, dynamic>,
          ),
        )
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  /// Append a message to an existing conversation.
  ///
  /// Updates the conversation's updatedAt timestamp.
  /// Returns the updated conversation, or null if not found.
  Future<Conversation?> appendMessage(
    String conversationId,
    ConversationMessage message,
  ) async {
    final conversation = load(conversationId);
    if (conversation == null) return null;

    final updated = conversation.copyWith(
      messages: [...conversation.messages, message],
      updatedAt: DateTime.now(),
    );
    await save(updated);
    return updated;
  }

  /// Delete a conversation by ID.
  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  /// Delete all conversations.
  Future<void> deleteAll() async {
    await _box.clear();
  }

  /// Close the Hive box.
  Future<void> close() async {
    await _box.close();
  }
}
