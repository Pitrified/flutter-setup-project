# 02 - CEFR level indicator and picker

Part of phase 09 (UI tweaks and small functionality). Surfaces the active
CEFR level at the top of the conversation screen and lets the user change it
without restarting the conversation.

## Goal

After this change:

- The conversation screen's app bar shows a chip displaying the active CEFR
  level (`A1`, `A2`, `B1`, `B2`, `C1`, `C2`).
- Tapping the chip opens a modal bottom sheet listing all six levels with a
  short description for each.
- Selecting a level: persists the new level on the active `Conversation`
  (via `ConversationRepository`) and on a new `default_cefr` key in
  `AppSettingsRepository` so future conversations start at the same level.
- The current conversation is **not** restarted; the next prompt uses the
  new `cefr_level` variable.
- The change does **not** invalidate `inferenceEngineProvider` or
  `appControllerProvider`.

## Non-goals

- No level recommendation from the LLM.
- No per-skill CEFR (writing vs. speaking) - one level for the whole app.
- No history of past levels.
- No prompt template change (`tutor_response/v1.txt` already substitutes
  `{{cefr_level}}`).

## Files touched

New:

- `lib/models/cefr_level.dart`
  - `enum CefrLevel { a1, a2, b1, b2, c1, c2 }`.
  - Extension: `displayName` (`"A1"` etc.) and `description` (one-sentence
    blurb per level).
  - Helpers: `CefrLevel.fromString(String)` mirroring `EngineKind.values.byName`.
- `lib/providers/cefr_level_provider.dart`
  - `defaultCefrLevelProvider` - `NotifierProvider<DefaultCefrLevelNotifier, CefrLevel>`.
  - `DefaultCefrLevelNotifier.select(CefrLevel)` writes to
    `AppSettingsRepository` under the `default_cefr` key. **Does not**
    invalidate engine providers (Settings invalidation discipline from
    `08/03.2`).
- `lib/screens/conversation/widgets/cefr_level_chip.dart`
  - Small `ActionChip` widget that reads the current level (from the active
    Conversation) and opens the picker on tap.
- `lib/screens/conversation/widgets/cefr_picker_sheet.dart`
  - `showCefrPickerSheet(BuildContext, current)` opens a `ModalBottomSheet`
    with a `ListView` of six tiles (title = `displayName`, subtitle =
    `description`, trailing check on the current level). Returns the picked
    `CefrLevel?`.
- `test/models/cefr_level_test.dart`
- `test/providers/cefr_level_provider_test.dart` - round-trip through a
  temp Hive box.
- `test/screens/conversation/widgets/cefr_picker_sheet_test.dart` - widget
  test: opens the sheet, taps a tile, verifies the returned value.

Modified:

- `lib/services/settings/app_settings_repository.dart`
  - Add the `default_cefr` string key with a documented default of
    `CefrLevel.a1`. Read/write via `CefrLevel.fromString` with safe
    fallback (same pattern as `engine_kind`).
- `lib/services/conversation/conversation_controller.dart`
  - Replace the `String cefrLevel` parameter on `startConversation` with a
    `CefrLevel` (default still A1 for backward compat - keep a string
    coercion at the boundary if needed).
  - Add `Future<void> setCefrLevel(CefrLevel level)`: updates
    `_currentConversation` with a new `cefrLevel` value and persists via
    `repository.save(...)`. Emits to the stream so the chip rebuilds.
- `lib/models/conversation.dart`
  - Keep `cefrLevel` as `String` (Hive-friendly) but enforce values via the
    enum at the controller boundary. No model regen needed.
- `lib/screens/conversation/conversation_screen.dart`
  - Add a `CefrLevelChip` as an `AppBar` action on the right side. On
    selection, call `controller.setCefrLevel(level)` and
    `ref.read(defaultCefrLevelProvider.notifier).select(level)`.
- `lib/screens/settings/settings_screen.dart`
  - New section "Default CEFR level" between the engine selector and the
    OpenAI section. Uses a `DropdownButtonFormField<CefrLevel>` wired to
    `defaultCefrLevelProvider`. Selection updates the default only; does
    not touch any active conversation (the chip on the conversation screen
    remains the in-session control).

## Behaviour contract

- The chip always reflects the conversation's level (single source of truth
  for the active session). The `defaultCefrLevelProvider` is consulted only
  when starting a new conversation.
- Changing the level mid-conversation:
  - Persists immediately.
  - Affects only **subsequent** messages (the prompt is rebuilt per send).
  - Does not invalidate inference providers - no engine restart.
- Picker is dismissible; cancelling makes no change.

## Acceptance criteria

- `flutter analyze` clean.
- All existing tests still pass; new tests cover enum round-trip, the
  notifier persists across rebuilds, and the picker sheet returns the
  selected level.
- Manual smoke: pick B1 in the picker, send a message in Portuguese,
  verify the LLM response complexity matches B1 expectations; close and
  reopen the app, confirm new conversations seed at B1.

## Commit message (suggested)

```
feat(conversation): CEFR level chip + picker bottom sheet

- New CefrLevel enum and default-level provider backed by
  AppSettingsRepository (Settings invalidation discipline preserved).
- ConversationController.setCefrLevel updates the active conversation
  without restarting it; the next prompt substitutes the new level.
- App bar action chip on ConversationScreen opens a modal sheet with
  the six levels and their descriptions.
```
