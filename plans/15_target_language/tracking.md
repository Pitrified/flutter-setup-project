# implementation tracking

Make the tutor's target language a setting instead of five hardcoded mentions of Portuguese, so the
same app can teach Spanish or anything else on the list. Inventory, decisions and open questions in
[`00_start.md`](00_start.md).

## Key decisions

- `pt-BR` stays the default, so nothing changes for the current user until a language is picked (TL1).
- The dead `Conversation.language` field is wired up rather than replaced (TL2).
- Per-conversation value with an app-wide default, mirroring the CEFR level, but fixed once a
  conversation has messages (TL3, Q8).
- Target language and explanation language are parametrized in the same prompt pass; only the target
  language gets a control now (TL4, Q3).
- Cloud is the quality bar (TL5, Q5): local models are on the way out, so nothing is gated on
  measuring the on-device engine and phase 4 is discarded. Whether `flutter_gemma` is removed is a
  separate effort, [`../16_cloud_first_engine/00_start.md`](../16_cloud_first_engine/00_start.md).
- First set: `pt-BR`, `es-ES`, `fr-FR`, `it-IT`, `de-DE` (TL6). `en-US` is out until the explanation
  language is a setting (Q9), and the picker is identical for both engines (TL8, Q10).
- `topic.dart` is untouched: `Brazilian culture` stays a suggestion in every language (TL7).

## Phases

| #  | Phase                                   | Plan                                                             | Status |
| -- | --------------------------------------- | ---------------------------------------------------------------- | ------ |
| 1  | TargetLanguage model + settings storage | [`01_feat_language_model.md`](01_feat_language_model.md)          | done |
| 2  | Prompt parametrization                  | [`02_feat_prompt_parametrization.md`](02_feat_prompt_parametrization.md) | done |
| 3  | UI: picker, dropdown, dynamic copy      | [`03_feat_language_ui.md`](03_feat_language_ui.md)                | done |
| 4  | On-device language check                | [`04_feat_on_device_language_check.md`](04_feat_on_device_language_check.md) | discarded |
| 5  | Docs, store listing, naming             | [`05_feat_outward_copy.md`](05_feat_outward_copy.md)              | done |

Status values: draft / planned / in progress / done / superseded / discarded.

Sequencing rationale: phases 1 and 2 are pure Dart and unit-testable with the fake engine, no device
and no network. Phase 3 is where the user can see it. Phase 5 is the outward-facing copy and comes
last so it is rewritten once. With phase 4 discarded, nothing in this effort needs a device, though
one real conversation per language through the cloud engine is still the honest check on phase 3.

## Log

Append-only. Newest at the bottom.

- 2026-09-24 : bootstrapped the folder from the ask "make the language a setting". Chased every
  hardcoded mention: the `Conversation.language` field exists and is **dead** (nothing reads it, and
  `buildPrompt` passes no language), the prompt template names Portuguese four times and English
  three times (two independent axes), three UI strings, one culture-specific topic suggestion, and
  five outward-facing files. Drafted 5 phases, Q1-Q8 open.
- 2026-09-24 : reviewed the five phases as written, before any code. Two claims were wrong and are
  corrected in `00_start.md`: Settings has **no** default-topic control (only CEFR has a dropdown),
  and the real entry point for both defaults is the app-bar chip, which writes the conversation and
  the app default in the same handler. Phase 3 now follows that double write instead of inventing a
  Settings-only path. Checked and held: no test asserts the three Portuguese UI strings,
  `PromptManager` silently leaves an unmatched `{{var}}` in the prompt (hence the phase-2 guard), and
  `_findLatestVersion` counts down from v10 so dropping in `v3.txt` makes it active with no code
  change.
- 2026-09-24 : folded in the first answer batch (Q1-Q8). Taken as recommended: the curated
  `TargetLanguage` enum (Q1a), one template with variables (Q4a), English explanations with no control
  yet (Q3a), keep the name and neutralize the copy (Q6a), language fixed once a conversation has
  messages (Q8a). Two answers diverged. **Q5**: local models are on the way out ("too shaky and slow"),
  cloud is the target, so phase 4 is **discarded** and the shipped set stops depending on device
  measurement; the wider engine question became the spin-off `16_cloud_first_engine`. **Q7**:
  `Brazilian culture` stays, so `topic.dart` is out of the diff entirely. Phase 5 moved from draft to
  planned. Two new questions raised while folding in: Q9 (`en-US` collides with English explanations,
  so it is held out of the first set) and Q10 (whether the picker warns when the on-device engine is
  selected).
- 2026-09-24 : folded in the second batch. Q9 dropped `en-US` from the first set, so TL6 is final at
  five languages, and Q10 confirmed the picker behaves the same for both engines. No phase changed
  status; phase 1 and phase 3 gained a line each. All questions are now answered and phases 1-3 are
  ready to execute.
- 2026-09-24 : phase 1 **done**. `TargetLanguage` (5 languages, BCP-47 code, English name, endonym,
  `promptName` with the regional variant), `default_language` in the settings repository with a
  fallback on an unsupported stored code, `DefaultTargetLanguageNotifier`, and
  `startConversation`/`setLanguage` on the controller with `LanguageLockedException` when a
  conversation already has messages. 11 new tests, full suite 152, analyze clean. Surprise: the sealed
  `AppException` forced a matching entry in `ErrorMessages`, which is the taxonomy working as intended.
- 2026-09-24 : phase 2 **done**. `v3.txt` names no language of its own; the controller passes
  `target_language` (the `promptName`, e.g. "Portuguese (Brazilian)") and `explanation_language`
  (English, a documented constant). `PromptManager.buildPrompt` now throws `PromptTemplateException`
  on an unsubstituted placeholder, which **contradicted an existing test** asserting the old
  leave-it-alone behaviour; that test was rewritten with a note on why. Added a test that builds the
  real shipped asset with the real variable set. Full suite 158, analyze clean.
- 2026-09-24 : phase 3 **done**. Settings dropdown, app-bar chip with the endonym, picker sheet,
  confirm dialog for a conversation that already has messages, and the three copy strings now read the
  language. Two widget tests hung before failing: a `testWidgets` body runs on a fake clock, so the
  Hive writes behind `startConversation` never complete inside it (fixed with `tester.runAsync`), and
  the height-capped sheet put the lower languages below the fold so taps missed. Rather than keep
  fighting the harness, the decision was **extracted out of the button callback** into
  `languageSwitchAction(...)`, unit-tested in four cases, with the sheet and dialog widget-tested
  standalone. Also found: `fromCode(...) ?? ref.read(...)` infers a nullable `T` for `read`, so the
  chip needed an explicit type. Not covered end to end: the chip's double write.
- 2026-09-24 : phase 5 **done**. pubspec description, `functional-specs.md` (target language is now a
  setting with the five supported languages), `prompt-engineering.md` rewritten around the variables
  rather than around Portuguese, and the store title and short description drafted. The live Play
  listing edit stays a manual step in phase 07. Full suite 167, analyze clean, all gates pass.
- 2026-09-24 : diff review after phase 3 found a **real bug no test caught**: the conversation screen
  called `startConversation` without `language`, so a new conversation ignored the Settings default and
  used `pt-BR`. Fixed at both call sites. The test written for it hangs (the `initState` Hive write sits
  inside the fake clock) and was removed rather than left skipped, so that path is verified by reading
  the code and belongs to the manual check.
- 2026-09-24 : effort complete for what can be done off-device. Phases 1, 2, 3, 5 done, phase 4
  discarded. **Not verified:** a real conversation in a non-Portuguese language against the cloud
  engine, which needs an API key and a device or emulator, so it is the one open item.
- 2026-09-25 : two of the three untested paths are now **verified on a headless emulator** (see
  [`../17_emulator_e2e/01_feat_emulator_smoke.md`](../17_emulator_e2e/01_feat_emulator_smoke.md)): the
  cold-start default (Settings to Spanish, force-stop, relaunch, conversation opens in Spanish) and
  the chip's double write (declining "Start over in German?" keeps the Spanish conversation and still
  moves the default to German). Still open: a real tutor turn in a non-Portuguese language, which
  needs the mocked endpoint in phase 17.2.
