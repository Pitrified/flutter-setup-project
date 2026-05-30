---
status: complete
depends_on: [05_controllers/00_conversation_controller.md, 05_controllers/01_app_controller.md, 05_controllers/02_welcome_screen.md, 05_controllers/03_model_download_screen.md, 05_controllers/04_conversation_screen.md]
produces: []
---

# Plan: Integration and Demo-Ready

## Goal

Wire all screens, controllers, and services together. Update the router with
proper redirects. Ensure the app runs end-to-end with FakeInferenceEngine.
Verify all items in the "Definition of Demo-Ready" checklist from the spec.

## Tasks

### 1. Router integration

Update `lib/app.dart` to:
- Wire AppController initialization on app start
- Add redirect logic based on AppState
- Ensure /model-download route is accessible

### 2. FakeInferenceEngine as default

For development and testing, set FakeInferenceEngine as the default override:

```dart
// lib/main.dart (dev mode)
ProviderScope(
  overrides: [
    inferenceEngineProvider.overrideWithValue(FakeInferenceEngine()),
  ],
  child: const FalaApp(),
)
```

### 3. Repository initialization

Ensure ConversationRepository.initialize() is called at app start (after Hive init).

### 4. End-to-end flow verification

Verify with FakeInferenceEngine:
1. App launches to welcome screen
2. Start conversation navigates to conversation screen
3. User sends message, sees tutor reply with corrections
4. Messages persist across app restart
5. Loading states visible during fake inference delay

### 5. Error states

Verify:
- Engine not initialized shows error on welcome screen
- Invalid output shows raw text (not crash)

### 6. Demo-ready checklist (from spec Section 12)

- [ ] App launches on Android emulator in < 5 seconds
- [ ] User can send a message and receive structured correction + reply
- [ ] Conversation persists across app restarts
- [ ] Invalid model output shows graceful fallback
- [ ] Loading states visible during inference
- [ ] App works fully offline after model download (fake engine always works)

## Acceptance criteria

- [ ] App runs end-to-end with FakeInferenceEngine
- [ ] All 3 screens connected via router with proper redirects
- [ ] Repository initialized at app start
- [ ] All existing tests still pass
- [ ] `flutter analyze` passes
- [ ] Demo-ready checklist items met (minus real model download)
