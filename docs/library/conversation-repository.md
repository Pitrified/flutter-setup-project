# ConversationRepository

> System spec for `lib/services/persistence/conversation_repository.dart`

## Purpose

Hive-backed persistence for conversations. Stores complete conversation objects
as JSON strings in a Hive box, keyed by conversation ID. Provides CRUD
operations plus message appending.

## Constructor parameters

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `boxName` | `String` | no | Hive box name (default `'conversations'`) |

## Public API

| Method | Signature | Description |
|--------|-----------|-------------|
| `initialize()` | `Future<void>` | Open the Hive box. Must be called before other methods |
| `save(conversation)` | `Future<void>` | Save or update a conversation |
| `load(id)` | `Conversation?` | Load by ID, returns null if not found |
| `listAll()` | `List<Conversation>` | All conversations, sorted by updatedAt descending |
| `appendMessage(id, message)` | `Future<Conversation?>` | Append message, update timestamp, persist |
| `delete(id)` | `Future<void>` | Delete single conversation |
| `deleteAll()` | `Future<void>` | Clear entire box |
| `close()` | `Future<void>` | Close the Hive box |

## Storage format

Each conversation is serialized via `jsonEncode(conversation.toJson())` and
stored as a `String` value in a `Box<String>`. The key is the conversation ID.

## Dependencies

- `hive` package (`Box<String>`)
- `Conversation` model (freezed, with `toJson`/`fromJson`)
- `ConversationMessage` model

## Provider

`conversationRepositoryProvider` in `lib/providers/service_providers.dart`:

```dart
final conversationRepositoryProvider = Provider<ConversationRepository>((ref) {
  return ConversationRepository();
});
```

Note: `initialize()` must be called separately (typically during app startup)
before the repository is usable.
