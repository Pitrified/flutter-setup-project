---
status: draft
depends_on: []
produces: [docs/functional-specs.md]
---

# Plan: Functional Specification

## Goal

Define the locked scope of the application. This is the source of truth for what we build.
Nothing gets implemented unless it appears here. Follows the 14-section template from
unity-setup-project.

## Target output: docs/functional-specs.md

### 1. Overview

- App name: TBD (working title: "fala" or similar)
- Purpose: on-device language tutoring via conversational AI
- Core value: structured corrections + natural conversation, fully offline after model download
- Target language: Portuguese (Brazilian), expandable to others
- Primary interaction: text chat with a tutor that corrects and continues

### 2. Core Technical Decisions (locked)

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
| Model size | 0.6B-3B parameters (Qwen3 0.6B initial target) |
| Model delivery | Download on first launch |
| Min Android version | API 26 (Android 8.0) |
| Target Android version | API 36 (Android 16) |

### 3. Platform Constraints

- Minimum RAM: 6 GB (functional), 8 GB (recommended)
- Minimum chipset tier: Snapdragon 8 Gen 1 / equivalent (2022 flagship)
- APK size budget: < 50 MB (model downloaded separately)
- Model file size: ~500 MB - 2 GB (quantized, stored in app-specific storage)
- First-launch requires internet (model download), then fully offline

### 4. Application Lifecycle

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

### 5. Screen Inventory

| Screen | Purpose | Lifetime |
|--------|---------|----------|
| Welcome | App entry, runtime status, start session | Until navigation |
| Model Download | Download progress, retry on failure | Until model cached |
| Conversation | Main interaction: messages, input, corrections | Session-scoped |

### 6. Systems

| System | Spec location |
|--------|---------------|
| AppController | docs/library/app-controller.md |
| LLMRuntimeAdapter (InferenceEngine) | docs/library/llm-runtime-adapter.md |
| ConversationController | docs/library/conversation-controller.md |
| StructuredOutputSystem | docs/library/structured-output-system.md |
| ConversationRepository | docs/library/conversation-repository.md |
| RuntimeModelManager | docs/library/runtime-model-manager.md |
| PromptManager | docs/library/prompt-manager.md |

### 7. Interaction Model

- User types a message in target language (Portuguese)
- App builds prompt: system instructions + schema + history subset + user message
- InferenceEngine produces structured JSON output
- Output parsed into: correction block + conversation block
- Correction shown if errors found; conversation reply always shown
- Message pair persisted to history

### 8. Structured Output Schema (initial)

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

### 9. Persistence

- Hive boxes: conversations, settings, model metadata
- Conversation: list of messages with role, content, timestamp, correction data
- Settings: selected language, difficulty, prompt version
- Model metadata: file path, version, download timestamp, compatibility info

### 10. Error Handling

| Failure | Fallback |
|---------|----------|
| Model not downloaded | Show download screen |
| Download fails | Retry button, resume partial download |
| Runtime initialization fails | Error screen with diagnostics |
| Inference timeout | Show timeout message, allow retry |
| Invalid structured output | Show raw text reply, log error for debugging |
| Storage corrupt | Reset conversation, preserve settings |

### 11. Logging and Debugging

- Logging utility (not print/debugPrint directly)
- Log levels: debug, info, warning, error
- Debug overlay: model info, inference time, token count, prompt version
- Logs stored in app storage, exportable for bug reports

### 12. Definition of Demo-Ready

A demo is ready when:
- [ ] App launches on Android emulator in < 5 seconds (cold start, model already cached)
- [ ] Model downloads successfully on first launch
- [ ] User can send a message and receive a structured correction + reply
- [ ] Conversation persists across app restarts
- [ ] Invalid model output shows graceful fallback (not a crash)
- [ ] Loading states are visible during inference
- [ ] App works fully offline after model download

### 13. Milestones

| Milestone | Definition |
|-----------|------------|
| M0 | Repo created, docs complete, environment working |
| M1 | Empty app builds and runs on emulator |
| M2 | Fake engine conversation loop works end-to-end |
| M3 | Real model inference produces structured output |
| M4 | Full flow: download, infer, correct, persist, reload |
| M5 | Private alpha on Google Play |

### 14. Out of Scope

Explicitly forbidden (not "later" - not allowed to leak into the codebase):

- Cloud/server LLM calls (this is on-device only)
- Multiple languages simultaneously (one at a time)
- Speech-to-text or text-to-speech
- User accounts or cloud sync
- Social features (leaderboards, sharing)
- Gamification (points, streaks, achievements)
- iOS support
- Web support
- Desktop support
- Ads, analytics, telemetry
- In-app purchases
- Multiple conversation types (only tutor conversation)
- Custom model training/fine-tuning in-app
- Model marketplace or model switching UI

## Key decisions (resolved)

- App name: "fala" (Portuguese for "speak") - used as package ID: `com.fala.app`
- Initial model: Gemma 3 1B (best balance of flutter_gemma support and capability, to be evaluated on-device)
- Difficulty levels: standard A1-C2 CEFR levels, controlled via prompt templates (correction strictness, explanation depth, tutor reply complexity)
