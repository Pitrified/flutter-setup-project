# ConversationController

> System spec for `lib/services/conversation/conversation_controller.dart`

## Purpose

Orchestrates the conversation loop between user and tutor. Owns the full flow:
build prompt from template + history, call structured inference, persist messages,
and expose conversation state for UI.

## Constructor parameters

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `structuredEngine` | `StructuredInferenceEngine<TutorResponse>` | yes | Typed inference with structured output |
| `repository` | `ConversationRepository` | yes | Persistence layer |
| `promptManager` | `PromptManager` | yes | Loads and fills prompt templates |
| `maxHistoryMessages` | `int` | no | History window size (default 10) |

## Public API

| Method | Signature | Description |
|--------|-----------|-------------|
| `conversationStream` | `Stream<Conversation?>` | Broadcast stream of conversation updates |
| `currentConversation` | `Conversation?` | Current active conversation |
| `startConversation()` | `Future<Conversation>` | Create and persist a new conversation |
| `loadConversation(id)` | `Future<void>` | Load existing conversation by ID |
| `sendMessage(content)` | `Future<ConversationMessage?>` | Full round trip: user msg -> prompt -> inference -> parse -> persist |
| `dispose()` | `Future<void>` | Close stream controller |

## sendMessage flow

1. Create user `ConversationMessage`, persist via repository.
2. Build prompt using `promptManager.buildPrompt('tutor_response', ...)`.
3. Call `structuredEngine.generate(InferenceRequest(prompt: ...))`.
4. Match on `StructuredResult`:
   - `StructuredSuccess` - extract `TutorResponse`, use `conversation.content` as reply.
   - `StructuredParseFailure` - use raw text as fallback reply.
   - `StructuredInferenceFailure` - use hardcoded error message.
5. Create tutor `ConversationMessage` (with optional `tutorResponse` for UI rendering).
6. Persist tutor message, emit updated conversation.

## History formatting

`_formatHistory()` takes the last N messages (configurable via `maxHistoryMessages`)
and formats them as `User: ...` / `Tutor: ...` lines for prompt context.

## Dependencies

- `StructuredInferenceEngine<TutorResponse>` (inference + parsing)
- `ConversationRepository` (Hive persistence)
- `PromptManager` (template loading)
- Models: `Conversation`, `ConversationMessage`, `TutorResponse`

## Provider

`conversationControllerProvider` in `lib/providers/conversation_provider.dart`:

```dart
final conversationControllerProvider = Provider<ConversationController?>((ref) {
  final structuredEngine = ref.watch(structuredInferenceEngineProvider);
  if (structuredEngine == null) return null;
  return ConversationController(
    structuredEngine: structuredEngine,
    repository: ref.watch(conversationRepositoryProvider),
    promptManager: ref.watch(promptManagerProvider),
  );
});
```

Returns null until the inference engine is initialized.
