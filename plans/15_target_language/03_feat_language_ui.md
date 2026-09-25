---
status: done
---

# Phase 3 - Language picker, Settings dropdown, dynamic copy

## Overview

Where the user gets to choose. Every piece mirrors something that already exists for the CEFR level,
so this phase is mostly copying a working pattern rather than designing one.
Context: [`00_start.md`](00_start.md), depends on
[`02_feat_prompt_parametrization.md`](02_feat_prompt_parametrization.md), since a picker that changes
nothing in the prompt is not testable.

## Goals

1. A default-language control in Settings.
2. An in-conversation way to see and change the language.
3. The three hardcoded UI strings name the active language instead of Portuguese.

## Plan

- Settings: add a `_LanguageDropdown` to
  [`settings_screen.dart`](../../lib/screens/settings/settings_screen.dart), built like
  `_CefrDropdown` at line 101, showing `displayName` with the `endonym` underneath.
- In-conversation: add `language_picker_sheet.dart` beside
  [`cefr_picker_sheet.dart`](../../lib/screens/conversation/widgets/cefr_picker_sheet.dart), and a
  `_LanguageAction` chip in the app bar next to `_TopicAction` and `_CefrAction`
  ([`conversation_screen.dart:207`](../../lib/screens/conversation/conversation_screen.dart)).
  Follow the existing double write: the chip sets the conversation through the controller and the app
  default through the provider. Per Q8 the sheet starts a **new** conversation when the current one
  has messages, so it needs a confirmation step that neither existing sheet has, and it writes the
  default even when the user declines the new conversation.
- Copy, all three strings from the inventory:
  [`welcome_screen.dart:81`](../../lib/screens/welcome/welcome_screen.dart) becomes
  "Learn <language> by speaking", and
  [`conversation_screen.dart:256`](../../lib/screens/conversation/conversation_screen.dart) and
  `:362` read the active conversation's language. The welcome screen reads the app default, since no
  conversation exists yet there.
- Topics: nothing to do. Q7 kept `Brazilian culture` as a suggestion in every language, so
  [`topic.dart`](../../lib/models/topic.dart) is untouched by this effort.
- Tests: the dropdown persists a change (the shape
  [`app_settings_repository_test.dart`](../../test/services/settings/app_settings_repository_test.dart)
  uses for CEFR), the picker refuses to switch in place on a conversation with messages, and the
  welcome-screen copy follows the stored default. A widget test asserting the *dynamic* string is the
  one that stops this regressing to a hardcoded label.

## Out of scope

- An explanation-language control (Q3), and with it `en-US` as a target language (Q9).
- Any engine-dependent behaviour in the picker: same list, no warning, whichever engine is selected
  (Q10).
- Localizing the app's own interface. The UI chrome stays English; only the named target language
  varies. A real `flutter_localizations` pass is a separate effort and is not implied by this one.

## Done when

- `scripts/check.sh` green.
- Changing the language in Settings and starting a conversation produces a tutor turn in that
  language, checked in the running app.
- No string in `lib/` names Portuguese: `grep -rn Portuguese lib` comes back empty.

## What the implementation found

**Type inference made the chip's language nullable.** `TargetLanguageX.fromCode(...) ?? ref.read(provider)`
infers `T` for `read` from the nullable left operand, so `current` came out `TargetLanguage?` and the
analyzer rejected `current.endonym`. An explicit `final TargetLanguage current = ...` fixes it, and is
what the code now carries.

**Two widget tests were written, failed for the right reason, and were replaced.** A `testWidgets`
body runs on a fake clock, so the Hive writes behind `startConversation`/`sendMessage` never complete
inside it: the first attempt hung with no output rather than failing. Seeding through
`tester.runAsync` fixed the hang, then the sheet taps missed, because the picker is height-capped and
the lower entries sit below the fold.

The fix was not more test plumbing. The decision the tests were reaching for lived inside the chip's
`onPressed` closure, where only a widget test could see it, so it was extracted to
`languageSwitchAction(picked:current:hasMessages:)` in the picker file, and the three rules (dismissed
or unchanged does nothing, empty conversation switches in place, one with messages asks first) are now
four unit tests. The sheet and the dialog are widget-tested standalone, with no Hive and no controller.
That is one fewer place where logic hides in a callback, which is why the phase is worth reading back.

**A real bug came out of the diff review, not the tests.** `_initConversation` and `_newConversation`
passed `cefrLevel` and `topic` to `startConversation` but not `language`, so a conversation started
from the screen used the parameter default (`pt-BR`) and silently ignored the Settings value. That is
the phase's own "Done when" failing while every test was green. Both call sites now pass
`ref.read(defaultTargetLanguageProvider)`.

**What is not covered by tests:**

- The cold-start path just fixed. A test for it was written and hangs: `_initConversation` runs in
  `initState`, so its Hive write happens inside the fake-clock zone with no way to flush it from
  outside `pumpWidget`. It was removed rather than left skipped. Verified by reading both call sites.
- The chip's double write (conversation plus app default) end to end. The rule and both writes are
  tested separately; the wiring between them is read, not executed.

Both belong to the manual check, which is the open item for this effort.

**Update 2026-09-25:** both are now covered automatically by
[`../17_emulator_e2e/`](../17_emulator_e2e/tracking.md): `integration_test/app_test.dart` sets the
language in Settings, restarts into a conversation in it, holds a turn against a mocked OpenAI, and
declines a language switch to prove the conversation and the default move independently. Run it with
`scripts/e2e.sh`.

Copy: `grep -rn Portuguese lib` now matches only `target_language.dart`, where the word is data.
