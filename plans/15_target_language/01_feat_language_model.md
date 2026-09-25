---
status: done
---

# Phase 1 - TargetLanguage model and settings storage

## Overview

The typed value and the places it is stored, with nothing reading it yet. Pure Dart, no widgets, no
device. Context: [`00_start.md`](00_start.md), which inventories the four pieces the CEFR level has
and the language does not.

## Goals

1. A `TargetLanguage` model that can be displayed, persisted and parsed back defensively.
2. An app-wide default in `AppSettingsRepository`, with a notifier and provider.
3. `Conversation.language` fed from that default instead of from a hardcoded parameter.

## Plan

- Add `lib/models/target_language.dart`, shaped after
  [`cefr_level.dart`](../../lib/models/cefr_level.dart): an enum, plus an extension carrying
  `code` (BCP-47, the value persisted on the conversation), `displayName` (English, for our UI) and
  `endonym` (the language's own name, for the prompt and the picker subtitle), plus a
  `fromCode` that returns null on an unknown value. The cases are `pt-BR`, `es-ES`, `fr-FR`, `it-IT`
  and `de-DE` (TL6). `en-US` is deliberately absent: with explanations hardcoded to English (Q3), an
  English target makes every translation a restatement, so it waits for the explanation-language
  setting (Q9).
- Add to [`app_settings_repository.dart`](../../lib/services/settings/app_settings_repository.dart):
  `keyDefaultLanguage = 'default_language'`, `defaultTargetLanguage` (pt-BR per TL1), a
  `defaultLanguage()` getter that falls back on an unparseable stored value, and a setter.
- Add `DefaultTargetLanguageNotifier` + `defaultTargetLanguageProvider` to
  [`settings_provider.dart`](../../lib/providers/settings_provider.dart), following
  `DefaultCefrLevelNotifier`: write through to the repository, and **no** engine-provider
  invalidation, since the language is a prompt input rather than an engine input.
- Change `ConversationController.startConversation` to take `TargetLanguage language` instead of the
  `String language = 'pt-BR'` default parameter, storing `language.code` on the conversation.
  Keep the parameter optional with the same effective default so existing callers still compile.
- Add `setLanguage` to the controller for phase 3's picker, refusing the change when the current
  conversation already has messages (Q8), with a named exception rather than a bare `StateError`
  message.
- Tests: round-trip through the repository, fallback on an unknown stored code, `fromCode` on a bad
  value, every case has a non-empty `displayName` and `endonym` (the shape
  [`cefr_level_test.dart`](../../test/models/cefr_level_test.dart) already uses), and `setLanguage`
  refused on a conversation with messages.

## Out of scope

- The prompt (phase 2), any widget (phase 3), the explanation language (Q3).
- Migrating stored conversations: they already hold `pt-BR`, which stays the default.

## Done when

- `scripts/check.sh` is green, including the new tests.
- A new conversation's `language` comes from the stored default, verified by a test rather than by
  reading the code.
- Nothing in the app behaves differently yet, which is the point of stopping here.

## What the implementation found

`AppException` is a **sealed** class and `ErrorMessages.forException` switches over it exhaustively,
so adding `LanguageLockedException` broke the build until that switch gained a case. The analyzer
caught it immediately, which is the sealed hierarchy doing its job: a new failure mode cannot exist
without a user-facing message for it.

`setLanguage` needed one case the plan did not name: the same language on a conversation that already
has messages. Throwing there would be wrong, since nothing is changing, so the unchanged check comes
before the locked check. There is a test for it.

`en-US` being absent is asserted as a test (`fromCode('en-US')` is null) rather than left as a comment,
so re-adding it later is a deliberate act that trips a red test first.
