# Functional Specification

> **Status:** Source of truth. Nothing gets implemented unless it appears here.

## 1. Overview

- **App name:** fala (Portuguese for "speak")
- **Package ID:** `com.fala.app`
- **Purpose:** on-device language tutoring via conversational AI
- **Core value:** structured corrections + natural conversation, fully offline after model download
- **Target language:** a setting (`default_language`), one of Portuguese (Brazilian),
  Spanish, French, Italian or German. Portuguese is the default; English is not offered
  while corrections and translations are written in English
- **Primary interaction:** text chat with a tutor that corrects grammar/vocabulary and continues the conversation

## 2. Core Technical Decisions (locked)

| Concern | Decision |
|---------|----------|
| Framework | Flutter (Dart) |
| Platform | Android only |
| State management | Riverpod |
| Navigation | GoRouter |
| Local storage | Hive |
| LLM inference | flutter_gemma (swappable via InferenceEngine interface) |
| Models (codegen) | freezed + json_serializable |
| Output enforcement | Constrained decoding (FSM) + schema validation fallback |
| Initial model | Gemma 3 1B (to be evaluated on-device) |
| Model delivery | Download on first launch |
| Min Android version | API 26 (Android 8.0) |
| Target Android version | API 36 (Android 16) |
| Difficulty system | A1-C2 CEFR levels via prompt templates |
| Target language | A setting, `TargetLanguage`, defaulting to `pt-BR` |

### Target language

The language being learned is a setting, not a constant. `TargetLanguage`
(`lib/models/target_language.dart`) is the closed set the app offers, and every
language-dependent string, prompt variable and piece of UI copy reads from it.

- **Default `pt-BR`.** Brazilian Portuguese is what the app was built around and
  what its store copy says; the default is the app's, not the device locale's.
- **Explanations stay in English.** Corrections and translations are written in
  English whatever the target language is, so the learner reads the explanation in
  a language they already have.
- **`en-US` is deliberately absent.** An English tutor explaining English in
  English has nothing to translate, so the enum does not offer it, and a test
  asserts that it does not.
- **A conversation's language is fixed once it has messages.** Changing the
  setting changes the default for the next conversation; changing it from inside a
  conversation that already has history offers a restart or keeping the current
  one, and `setLanguage` raises `LanguageLockedException` rather than rewriting
  history in a language it was not spoken in.

## 3. Platform Constraints

- Minimum RAM: 6 GB (functional), 8 GB (recommended)
- Minimum chipset tier: Snapdragon 8 Gen 1 / equivalent (2022 flagship)
- APK size budget: < 50 MB (model downloaded separately)
- Model file size: ~500 MB - 2 GB (quantized, stored in app-specific storage)
- First-launch requires internet (model download), then fully offline

## 4. Application Lifecycle

```
App Launch
  -> Initialize Hive
  -> Check model availability
  -> If no model: show download screen
  -> If model ready: initialize InferenceEngine
  -> Navigate to Welcome Screen
  -> User starts conversation
  -> Conversation Screen (main loop)
```

## 5. Screen Inventory

| Screen | Purpose | Lifetime |
|--------|---------|----------|
| Welcome | App entry, runtime status, start session | Until navigation |
| Model Download | Download progress, retry on failure | Until model cached |
| Conversation | Main interaction: messages, input, corrections | Session-scoped |

## 6. Systems

| System | Spec location |
|--------|---------------|
| AppController | [library/app-controller.md](library/app-controller.md) |
| InferenceEngine | [library/inference-engine.md](library/inference-engine.md) |
| ConversationController | [library/conversation-controller.md](library/conversation-controller.md) |
| StructuredOutputSystem | [library/structured-output-system.md](library/structured-output-system.md) |
| ConversationRepository | [library/conversation-repository.md](library/conversation-repository.md) |
| RuntimeModelManager | [library/runtime-model-manager.md](library/runtime-model-manager.md) |
| PromptManager | [library/prompt-manager.md](library/prompt-manager.md) |

## 7. Interaction Model

1. User types a message in the conversation's target language
2. App builds prompt: system instructions + schema + history subset + user message
3. InferenceEngine produces structured JSON output
4. Output parsed into: correction block + conversation block
5. Correction shown if errors found; conversation reply always shown
6. Message pair persisted to history

## 8. Structured Output Schema

```json
{
  "correction": {
    "content": "corrected sentence in target language",
    "translation": "English translation",
    "errors": [
      {
        "original": "what user wrote",
        "corrected": "fixed version",
        "explanation": "brief grammar/vocab note"
      }
    ]
  },
  "conversation": {
    "content": "tutor reply in target language",
    "translation": "English translation"
  }
}
```

If the user's message has no errors, `correction.content`, `correction.translation`,
and `correction.errors` are empty/empty list.

## 9. Persistence

| Hive box | Dart model | Contents |
|----------|------------|----------|
| conversations | `Conversation` (list of `ConversationMessage` with `TutorResponse`) | Messages: role, content, timestamp, correction data |
| settings | `Settings` (TBD) | Selected language, CEFR difficulty level, prompt version |
| model_metadata | `ModelMetadata` | File path, version, download timestamp, compatibility info |

## 10. Error Handling

| Failure | Fallback |
|---------|----------|
| Model not downloaded | Show download screen |
| Download fails | Retry button, resume partial download |
| Runtime initialization fails | Error screen with diagnostics |
| Inference timeout | Show timeout message, allow retry |
| Invalid structured output | Show raw text reply, log error for debugging |
| Storage corrupt | Reset conversation, preserve settings |

## 11. Logging and Debugging

- Project logging utility (never `print`/`debugPrint` directly)
- Log levels: debug, info, warning, error
- Debug overlay: model info, inference time, token count, prompt version
- Logs stored in app storage, exportable for bug reports

## 12. Definition of Demo-Ready

- [ ] App launches on Android emulator in < 5 seconds (cold start, model cached)
- [ ] Model downloads successfully on first launch
- [ ] User can send a message and receive a structured correction + reply
- [ ] Conversation persists across app restarts
- [ ] Invalid model output shows graceful fallback (not a crash)
- [ ] Loading states visible during inference
- [ ] App works fully offline after model download

## 13. Milestones

| Milestone | Definition |
|-----------|------------|
| M0 | Repo created, docs complete, environment working |
| M1 | Empty app builds and runs on emulator |
| M2 | Fake engine conversation loop works end-to-end |
| M3 | Real model inference produces structured output |
| M4 | Full flow: download, infer, correct, persist, reload |
| M5 | Private alpha on Google Play |

## 14. Out of Scope

Explicitly forbidden (not "later" - not allowed to leak into the codebase):

- Cloud/server LLM calls (on-device only)
- Multiple languages simultaneously (one at a time)
- Speech-to-text or text-to-speech
- User accounts or cloud sync
- Social features (leaderboards, sharing)
- Gamification (points, streaks, achievements)
- iOS, web, or desktop support
- Ads, analytics, telemetry
- In-app purchases
- Multiple conversation types (only tutor conversation)
- Custom model training/fine-tuning in-app
- Model marketplace or model switching UI
