# 06 - New conversation button

Part of phase 09 (UI tweaks and small functionality). Adds a way to start a
fresh conversation from the conversation screen; there is currently none.

## Goal

After this change:

- The conversation screen exposes a "New conversation" affordance.
- Tapping it starts a brand-new conversation seeded with the current default
  CEFR level and default topic (same defaults `_initConversation` uses).
- The message list clears to the empty state ("Say something in
  Portuguese!"), the input field clears, and the view is pinned to the
  bottom again.
- The previous conversation is left persisted in the repository (not deleted).

## Non-goals

- No conversation list / history browser (there is no UI to reload past
  conversations yet; `ConversationController.loadConversation` stays unused
  here).
- No confirmation dialog before starting a new conversation.
- No change to how `startConversation` persists or to the repository.

## Design decision: where the button lives

`ConversationController.startConversation` already creates and persists a
fresh conversation and emits it on `conversationStream`, so the existing
`StreamBuilder` in `build` rebuilds the list automatically.

Place the trigger as an **AppBar action** in `_ConversationScreenState`,
because the state class already holds `ref`, the `controller`, the text
controller, and the scroll/pin state - no extra plumbing. (Alternative: a
drawer `ListTile`, but `_AppDrawer` is a plain `StatelessWidget` and would
need converting to a `ConsumerWidget` with provider reads; the AppBar action
is the smaller change.)

## Files touched

Modified:

- `lib/screens/conversation/conversation_screen.dart`
  - Add a `_newConversation` method on `_ConversationScreenState`:
    ```dart
    Future<void> _newConversation() async {
      final controller = ref.read(conversationControllerProvider);
      if (controller == null) return;
      await controller.startConversation(
        cefrLevel: ref.read(defaultCefrLevelProvider),
        topic: ref.read(defaultTopicProvider),
      );
      _textController.clear();
      setState(() {
        _isPinnedToBottom = true;
        _lastMessageCount = 0;
      });
    }
    ```
  - Add an `IconButton` to the `AppBar.actions` list (before or after the
    topic / CEFR actions), e.g.:
    ```dart
    IconButton(
      tooltip: 'New conversation',
      icon: const Icon(Icons.edit_square), // or Icons.add_comment_outlined
      onPressed: _isSending ? null : _newConversation,
    ),
    ```
  - Disable it while a send is in flight (`_isSending`) so a new conversation
    cannot start mid-stream.

## Behaviour contract

- Starting a new conversation while one is active replaces
  `currentConversation`; the old one remains saved (its id was the previous
  `millisecondsSinceEpoch`). No history UI consumes it yet - acceptable.
- The new conversation uses the **current default** CEFR/topic providers, not
  the level/topic of the conversation being replaced. This matches first-launch
  behaviour in `_initConversation`.
- `_lastMessageCount` is reset so the auto-scroll bookkeeping starts clean for
  the empty conversation.

## Acceptance criteria

- `flutter analyze` clean.
- Existing tests pass; add a widget test if the screen has a test harness:
  tapping the new-conversation action with messages present returns the list
  to the empty-state text.
- Manual smoke: have a conversation with a few messages, tap the new
  conversation button - the chat clears to the empty prompt, the input is
  empty, and sending a message starts a fresh thread at the default level/topic.

## Commit message (suggested)

```
feat(conversation): add new conversation button

- AppBar action starts a fresh conversation seeded with the default CEFR
  level and topic, clearing the message list and input. Disabled while a
  reply is streaming. The previous conversation stays persisted.
```
