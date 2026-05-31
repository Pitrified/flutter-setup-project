# 03 - Topic suggestions and picker

Part of phase 09 (UI tweaks and small functionality). Adds a "Pick a topic"
affordance at the top of the conversation screen that biases the tutor's
prompts toward a chosen subject.

## Goal

After this change:

- The conversation screen's app bar exposes a "Pick a topic" button (icon +
  short label of the current topic, or "Pick a topic" if none).
- Tapping it opens a modal bottom sheet with:
  - A `TextField` at the top for a custom topic, with an "Apply" button.
  - A scrollable list of suggested topics (static, curated, ~15 entries
    such as "Daily routine", "Travel", "Food", "Work", "Hobbies", etc.).
- Picking a topic (custom or from the list) updates the active conversation
  and seeds future conversations.
- The current conversation is **not** restarted; the next prompt includes
  the topic.
- The change does **not** invalidate `inferenceEngineProvider` or
  `appControllerProvider`.

## Non-goals

- No LLM-generated topic suggestions in this iteration (the seed list is
  hard-coded). Dynamic suggestions can come later.
- No per-message topic override - topic is conversation-scoped.
- No topic history dropdown.
- No translation of the topic label.

## Files touched

New:

- `lib/models/topic.dart`
  - `class Topic { final String value; final bool isCustom; ... }` (simple
    value object). Equality on `value`.
  - `const kSuggestedTopics = <Topic>[ Topic(value: 'Daily routine'), ... ]`
    (~15 entries).
- `lib/providers/topic_provider.dart`
  - `defaultTopicProvider` - `NotifierProvider<DefaultTopicNotifier, Topic?>`.
  - `DefaultTopicNotifier.select(Topic?)` writes to `AppSettingsRepository`
    under the `default_topic` key (empty string = no topic). **Does not**
    invalidate engine providers.
- `lib/screens/conversation/widgets/topic_button.dart`
  - `AppBar` action: icon + truncated topic label or "Pick a topic".
- `lib/screens/conversation/widgets/topic_picker_sheet.dart`
  - `showTopicPickerSheet(BuildContext, current)` returns the picked
    `Topic?`. Layout: top text field with "Apply" suffix button, then a
    `ListView.separated` of suggestions.
- `test/providers/topic_provider_test.dart` - persistence round-trip.
- `test/screens/conversation/widgets/topic_picker_sheet_test.dart` - widget
  tests: pick a suggestion, enter and apply a custom topic, dismiss
  without changing.

Modified:

- `lib/models/conversation.dart`
  - Add `@Default('') String topic` to the freezed `Conversation` factory.
  - **Regenerate** freezed / json files (`dart run build_runner build -d`).
- `lib/services/settings/app_settings_repository.dart`
  - Add `default_topic` string key with documented default of `''`.
  - Read/write via plain string (no enum).
- `lib/services/conversation/conversation_controller.dart`
  - `startConversation` accepts an optional `topic` (default empty).
  - New `Future<void> setTopic(String topic)`: updates
    `_currentConversation.topic`, persists via repository, emits to the
    stream.
  - Pass `'topic': _currentConversation!.topic` into
    `promptManager.buildPrompt(...)`.
- `assets/prompts/tutor_response/v2.txt` (new file, do **not** edit v1)
  - Copy v1 verbatim and insert, near the "Rules" section:
    `When a topic is provided, steer the conversation toward it without forcing it. Topic: "{{topic}}".`
  - Add `{{topic}}` substitution at the end of the prompt body. When the
    topic is empty, the prompt should read naturally (the controller passes
    `topic` as the empty string; the template handles both).
- `lib/services/conversation/conversation_controller.dart`
  - Bump the prompt version request to `v2` (or rely on
    `PromptManager._findLatestVersion` which already picks the highest).
- `lib/screens/conversation/conversation_screen.dart`
  - Add `TopicButton` as an `AppBar` action (left of the CEFR chip from
    plan 02 if both land).

## Behaviour contract

- The button label reflects the conversation's current topic; truncation at
  ~20 chars with ellipsis.
- Empty topic is a valid state - the prompt template degrades to a neutral
  "no topic specified" line.
- Choosing a topic:
  - Persists immediately to `Conversation.topic` and `default_topic`.
  - Affects only **subsequent** messages.
  - Does not invalidate inference providers.
- Custom topics are stored as plain strings, trimmed; empty input is
  rejected (button disabled until non-empty).

## Acceptance criteria

- `flutter analyze` clean.
- Freezed regen succeeds; all existing tests still pass.
- New tests cover the notifier round-trip, the picker (suggestion +
  custom), and a unit test that the prompt built by the controller
  contains the chosen topic.
- Manual smoke: pick "Food", send a message, verify the tutor's reply
  references food; switch to a custom topic "ciclismo", verify subsequent
  replies pivot. Restart the app, confirm the topic persists into a new
  conversation.

## Commit message (suggested)

```
feat(conversation): topic picker bottom sheet + prompt integration

- Add Topic value object, defaultTopicProvider, AppBar TopicButton, and
  modal picker sheet with curated suggestions and a custom-topic field.
- ConversationController.setTopic mutates the active conversation
  without restart; subsequent prompts include the chosen topic.
- Bump tutor_response prompt to v2 with a topic-aware steering rule.
```
