---
status: not-started
depends_on: [03_scaffold/02_generated_models.md]
produces: [lib/services/persistence/conversation_repository.dart]
---

# Plan: Conversation Repository

## Goal

Hive-backed local persistence for conversations. Save, load, list, append messages,
and delete conversations. Fully offline, stored in app-specific storage.

## Implementation

`lib/services/persistence/conversation_repository.dart`:

```dart
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
        .map((json) => Conversation.fromJson(
              jsonDecode(json) as Map<String, dynamic>,
            ))
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
```

## Storage format

- Box name: `conversations`
- Key: conversation ID (UUID string)
- Value: JSON-encoded Conversation object (String)
- Location: Hive default path (app-specific storage via path_provider)

Using JSON strings (not Hive TypeAdapters) because:
- No need to write/maintain TypeAdapters for every model
- Models already have fromJson/toJson via json_serializable
- Schema migrations are simpler (just parse and re-save)
- Slightly less performant but negligible for our data sizes

## Provider

```dart
// lib/providers/persistence_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/persistence/conversation_repository.dart';

final conversationRepositoryProvider = Provider<ConversationRepository>((ref) {
  return ConversationRepository();
});
```

## Initialization

Hive must be initialized before the repository:

```dart
// In main.dart (before runApp):
await Hive.initFlutter();
```

## Tests

`test/services/conversation_repository_test.dart`:

- Save and load a conversation
- List all returns sorted by updatedAt
- Append message updates conversation
- Delete removes conversation
- Load nonexistent ID returns null
- DeleteAll clears everything

Tests use a temporary Hive directory (cleaned up after each test).

## Acceptance criteria

- [ ] ConversationRepository implements save/load/listAll/appendMessage/delete
- [ ] Uses JSON serialization (not Hive TypeAdapters)
- [ ] Hive initialized in main.dart
- [ ] Provider exists for dependency injection
- [ ] Tests pass with temporary storage
- [ ] `flutter analyze` passes
