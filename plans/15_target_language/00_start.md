# Target language as a setting

Status: bootstrap. Nothing implemented yet.

Original ask (2026-09-24): make the language a setting, so the app can swap to Spanish or whatever,
and chase all the places that need parametrizing.

Today the target language is Portuguese in five different ways: a default on a model field, a
default parameter, English prose inside the prompt template, three strings of UI copy, and the
store listing. Only the first two are data; the rest are text that has to be rewritten rather than
switched.

---

## Inventory: everywhere the language is baked in

Line numbers are from 2026-09-24, `main` at `af510ea`.

### Data that already exists and does nothing

| Where | What | Note |
| --- | --- | --- |
| [`lib/models/conversation.dart:16`](../../lib/models/conversation.dart) | `@Default('pt-BR') String language` | Persisted on every conversation since phase 04 |
| [`lib/services/conversation/conversation_controller.dart:59`](../../lib/services/conversation/conversation_controller.dart) | `String language = 'pt-BR'` parameter | Stored at line 69 |

The field is **dead**: nothing reads it. `buildPrompt` at
[`conversation_controller.dart:148`](../../lib/services/conversation/conversation_controller.dart)
passes `cefr_level`, `topic`, `user_message` and `conversation_history`, and no language. So the
model carries a language that the prompt ignores, and the prompt hardcodes a language the model
does not know about. That gap is the actual bug behind this feature.

### The prompt template

[`assets/prompts/tutor_response/v2.txt`](../../assets/prompts/tutor_response/v2.txt) (and `v1.txt`,
kept for history) names the language six times:

- line 1: "You are a Portuguese language tutor. The user is learning Portuguese at {{cefr_level}} level."
- lines 6, 17: "the full corrected sentence in Portuguese", "your conversational reply in Portuguese"
- line 23: "Always reply in Portuguese (Brazilian)."
- lines 7, 12, 18: "**English** translation", "explanation in **English**"

Two axes, not one. The **target language** is what the learner practises; the **explanation
language** is what the corrections and translations are written in, currently English. They are
independent: a Spanish speaker learning Portuguese wants explanations in Spanish.

[`PromptManager.buildPrompt`](../../lib/services/prompt/prompt_manager.dart) already substitutes
`{{var}}` for anything passed in, so new variables cost nothing beyond passing them.

### Settings plumbing that does not exist yet

The CEFR level and the topic are the working precedent for a per-conversation value with an app-wide
default, and each has four pieces. Language has none of them:

| Piece | CEFR | Topic | Language |
| --- | --- | --- | --- |
| Typed model | [`models/cefr_level.dart`](../../lib/models/cefr_level.dart) | [`models/topic.dart`](../../lib/models/topic.dart) | missing |
| Hive key + default | `keyDefaultCefr` | `keyDefaultTopic` | missing |
| Notifier + provider | `DefaultCefrLevelNotifier` | `DefaultTopicNotifier` | missing |
| Settings control | `_CefrDropdown` ([`settings_screen.dart:101`](../../lib/screens/settings/settings_screen.dart)) | none, see below | missing |
| In-conversation picker | [`cefr_picker_sheet.dart`](../../lib/screens/conversation/widgets/cefr_picker_sheet.dart) | [`topic_picker_sheet.dart`](../../lib/screens/conversation/widgets/topic_picker_sheet.dart) | missing |
| Controller setter | `setCefrLevel` (line 90) | `setTopic` (line 107) | missing |

How the default is actually written matters for phase 3. Settings has a dropdown for the CEFR level
and nothing for the topic; the real entry point for both is the app-bar chip
([`conversation_screen.dart:207-209`](../../lib/screens/conversation/conversation_screen.dart),
`_TopicAction` and `_CefrAction`), and each chip writes **twice**: the conversation via the
controller setter, and the app default via the provider (lines 440-450 and 490). So "the default" is
a side effect of the last in-conversation choice, not a separate thing the user maintains.

### UI copy

| Where | String |
| --- | --- |
| [`welcome_screen.dart:81`](../../lib/screens/welcome/welcome_screen.dart) | "Learn Portuguese by speaking" |
| [`conversation_screen.dart:256`](../../lib/screens/conversation/conversation_screen.dart) | "Say something in Portuguese!" |
| [`conversation_screen.dart:362`](../../lib/screens/conversation/conversation_screen.dart) | "Type in Portuguese..." |

No test asserts on these three strings, so they are safe to make dynamic.

### Content that is culture-specific rather than language-specific

[`models/topic.dart:45`](../../lib/models/topic.dart): `Topic(value: 'Brazilian culture')` in
`kSuggestedTopics`. The other fourteen suggestions are neutral. One entry has to vary with the
language, or become something like "local culture".

### Outside the app code

| Where | What |
| --- | --- |
| [`pubspec.yaml:2`](../../pubspec.yaml) | `description: On-device Portuguese language tutor` |
| [`docs/google-play-private-alpha.md:61-62`](../../docs/google-play-private-alpha.md) | Store title `fala - Portuguese Tutor`, short description |
| [`docs/functional-specs.md:7,11,75`](../../docs/functional-specs.md) | App name gloss, "Target language: Portuguese (Brazilian), expandable to others", the flow description |
| [`docs/prompt-engineering.md:137-147`](../../docs/prompt-engineering.md) | Prompt guidance written in terms of Portuguese |
| `android/app/src/main/AndroidManifest.xml:5` | `android:label="fala"` |

The app name is a Portuguese word ("fala" = "speaks"), which the functional spec already notes. That
is a branding question, not a parametrization one, and it is raised as Q6 rather than assumed.

### What the engines do with a language

- **Cloud (`openai_dart`)**: no language parameter exists. The prompt is the only lever, and
  gpt-4o-mini handles the major European languages, so the setting works the day it ships.
- **On-device (Qwen3-0.6B via LiteRT-LM)**: multilingual by training, quality per language unmeasured
  at 0.6B. This is the risk in the whole effort, and it is a measurement, not a design decision.
  It needs a device, so it belongs in a g7 session (Q5).
- **Audio, phase 14**: [`14_audio_io/00_start.md`](../14_audio_io/00_start.md) already needs a locale
  for both dictation and speech, and lists per-language availability as an open risk. A BCP-47 code
  on the conversation is what it will read, which is another reason to settle the representation here.

---

## Approach

Mirror the CEFR level, which is the closest existing thing: a typed model, a Hive-backed default, a
notifier, a Settings control, an in-conversation picker, and a controller setter. Then make the
prompt template take the two language axes as variables, and make the three UI strings read the
active conversation's language.

Order matters more than usual here. The prompt cannot be parametrized before there is a value to
pass, and the UI cannot show a language before the conversation carries one. So: model and storage,
then prompt, then UI, then the non-code surfaces.

---

## Decisions

- **TL1: `pt-BR` stays the default.** Every stored conversation already carries it, so there is no
  migration and no behaviour change for the current user until a language is picked.
- **TL2: the existing `Conversation.language` field is reused rather than replaced.** It is already
  persisted and already defaulted, so wiring it up is strictly less work than adding a field, and it
  turns a dead field into a used one.
- **TL3: the language is a per-conversation value with an app-wide default**, exactly like the CEFR
  level. A conversation's language cannot change once it has messages (Q8), which is where it differs
  from CEFR.
- **TL4: two axes, parametrized together, exposed separately.** The prompt gets both
  `{{target_language}}` and `{{explanation_language}}` in the same pass, because editing the template
  twice costs more than adding one variable. Only the target language gets a UI control now;
  explanation language stays English until someone asks (Q3).
- **TL5: cloud is the quality bar (Q5).** The shipped language set is whatever the cloud engine
  handles, which is all of them, so nothing waits on device measurement. The on-device engine stays
  selectable and is best-effort in any language. Whether it is removed outright is a separate effort:
  [`../16_cloud_first_engine/00_start.md`](../16_cloud_first_engine/00_start.md).
- **TL6: the first set is `pt-BR`, `es-ES`, `fr-FR`, `it-IT`, `de-DE`** (Q2, narrowed by Q9).
  `en-US` is out until the explanation language is a setting, because English as a target with English
  explanations makes every translation a restatement.
- **TL8: the language list does not vary by engine (Q10).** No per-engine warning, no filtering of the
  picker. The engine selector and the language selector stay independent.
- **TL7: `topic.dart` is not touched (Q7).** `Brazilian culture` stays a suggestion in every language.

---

## Open questions

- Q1: how is a language represented?
  a. A curated `enum TargetLanguage` with a BCP-47 code, an English name and an endonym, mirroring
     `CefrLevel` and its `fromString` parsing.
  b. A free-form string the user types, validated loosely.
  Recommended: a, because the enum is what lets the UI list languages, the prompt name them properly,
  and a stored unknown value fall back to the default the way `CefrLevel.fromString` already does.
  A free-form string moves all of that into the prompt and makes the audio phase guess at a locale.
  ANS: a.
- Q2: which languages ship in the first set?
  a. Portuguese (pt-BR) and Spanish (es-ES) only, the ask as stated.
  b. Five or six major European languages: pt-BR, es-ES, fr-FR, it-IT, de-DE, en-US.
  Recommended: b, because the cost per entry is one enum case with two strings, and a list of two
  looks like a prototype. Both are gated on Q5 for the on-device engine.
  ANS: b. The gate is gone with Q5, so the whole set ships at once. See Q9 on `en-US`.
- Q3: the explanation language (translations, error explanations), currently English.
  a. Parametrize the template now, hardcode English at the call site, no UI.
  b. Parametrize and add a second Settings dropdown in this effort.
  Recommended: a, because there is one user and their explanation language is English. The variable
  is in the template, so b is an afternoon later.
  ANS: a.
- Q4: one template for all languages, or one per language?
  a. One template, with the language as a variable.
  b. `assets/prompts/tutor_response/pt-BR/vN.txt` per language.
  Recommended: a. Per-language templates duplicate the JSON contract, which is the part most likely
  to need editing. If one language later needs special handling, the loader already supports a name
  and a version, so a targeted override can be added then.
  ANS: a.
- Q5: is Qwen3-0.6B good enough in a second language? Unknown, and it needs the Pixel.
  a. Measure first on g7 (a handful of turns per candidate language), then decide the shipped set.
  b. Ship the setting for all languages with a note that on-device quality varies.
  Recommended: a for the languages in Q2, because a tutor that corrects Spanish badly is worse than
  one that does not offer Spanish, and the measurement is half an hour of device time.
  ANS: neither. "Local models are soon to be dismissed. Too shaky and slow. We target cloud main for
  now." So there is nothing to gate: the cloud engine is the quality bar, every language in Q2 ships,
  and the on-device engine is best-effort in whatever language it is given. Phase 4 is discarded, and
  the wider question of dropping `flutter_gemma` is a separate effort, spun off as
  [`../16_cloud_first_engine/00_start.md`](../16_cloud_first_engine/00_start.md).
- Q6: the app is called `fala`, a Portuguese word, and the store listing says "Portuguese Tutor".
  a. Keep the name, make the tagline and store copy language-neutral.
  b. Keep both, treat Portuguese as the flagship language and the others as extras.
  c. Rename the app.
  Recommended: a. The name is short and already shipped to the alpha; the copy is what misleads.
  ANS: a.
- Q7: what does the language control do to the suggested topics, where "Brazilian culture" is the
  odd one out?
  a. Replace it with a neutral "Local culture".
  b. Per-language suggestion lists.
  c. Drop the entry.
  Recommended: a, because the other fourteen suggestions are already language-neutral and one
  culture entry that reads correctly everywhere is cheaper than fifteen lists per language.
  ANS: none of the above, keep `Brazilian culture` as it is ("Brasil is cool"). The suggestions are a
  seed for the conversation, not a claim about the learner's language, and a Spanish learner who taps
  it gets a conversation about Brazil in Spanish, which is fine. `topic.dart` is untouched by this
  effort.
- Q8: can the language change inside a conversation that already has messages?
  a. No. The in-conversation picker starts a new conversation, the way the language of a lesson is
     fixed when it starts.
  b. Yes, like the CEFR chip: change it and the next turn uses it.
  Recommended: a, because the history is in the old language and a mid-conversation switch gives the
  model a bilingual transcript and a correction pass over sentences in a language it was told to
  stop using.
  ANS: a.

### Second batch, raised while folding in the first (2026-09-24)

- Q9: `en-US` is in the Q2 set, but Q3 hardcodes the explanation language to English. For an English
  learner both axes are then English, so every `translation` field restates the sentence and every
  explanation is in the language being learned.
  a. Drop `en-US` from the first set, and add it when the explanation language becomes a setting.
  b. Ship it, and let the template's translation fields be redundant for that one language.
  c. Ship it, and special-case the prompt so translations are omitted when the two languages match.
  Recommended: a, because it is the only case where the two axes collide, and shipping a language
  whose output is visibly redundant costs more credibility than leaving it out for now.
  ANS: a, drop it. The first set is `pt-BR`, `es-ES`, `fr-FR`, `it-IT`, `de-DE`. `en-US` becomes
  available once the explanation language is a setting (Q3b).
- Q10: with cloud as the target (Q5), what does the language picker say when the on-device engine is
  the selected one?
  a. Nothing. The engine selector is an expert setting and the language list is the same either way.
  b. A line under the picker noting that on-device quality varies by language.
  Recommended: a, because the on-device engine is on its way out per Q5, and a warning about
  something being removed is a maintenance burden with a short life.
  ANS: a, no warning. The language list is the same whichever engine is selected.
