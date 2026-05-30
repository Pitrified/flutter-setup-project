# Plan 06/02 - Testing Strategy

## Status: in-progress

## Goal

Comprehensive test coverage: unit tests for all services, widget tests for
screens, one integration test for the full conversation flow.

## Context

Current test state (38 tests passing):
- `test/models/conversation_message_test.dart` - serialization
- `test/services/prompt_manager_test.dart` - template loading
- `test/services/fake_inference_engine_test.dart` - engine behavior
- `test/services/structured_output_parser_test.dart` - parsing
- `test/services/conversation_repository_test.dart` - Hive persistence
- `test/services/app_controller_test.dart` - lifecycle states
- `test/services/conversation_controller_test.dart` - send/receive flow

Missing:
- Widget tests for all three screens
- Widget tests for MessageBubble, CorrectionCard
- Unit test for JsonExtractor
- Unit test for ModelManager (mock file system)
- Integration test: full app boot -> conversation flow with FakeInferenceEngine

## Tasks

### 1. Widget tests for screens

Files:
- `test/screens/welcome_screen_test.dart`
- `test/screens/model_download_screen_test.dart`
- `test/screens/conversation_screen_test.dart`

Use `ProviderScope` overrides with fakes. Verify:
- Correct widgets render for each state
- Button taps trigger expected actions
- Stream updates cause rebuilds

### 2. Widget tests for reusable widgets

Files:
- `test/widgets/message_bubble_test.dart`
- `test/widgets/correction_card_test.dart`

Verify:
- User messages align right, tutor messages align left
- Corrections display original/corrected/explanation
- Empty corrections list renders nothing

### 3. Unit test for JsonExtractor

File: `test/services/json_extractor_test.dart`

Cover:
- Direct JSON string
- JSON in markdown code block
- JSON embedded in prose
- Invalid input returns null

### 4. Unit test for ModelManager

File: `test/services/model_manager_test.dart`

Use temp directory. Cover:
- `getDownloadedModel` returns null for missing file
- `getDownloadedModel` returns metadata for existing file
- `deleteModel` removes file

### 5. Integration test

File: `integration_test/conversation_flow_test.dart`

Full app with FakeInferenceEngine override. Verify:
- App starts at welcome screen
- Navigate to conversation
- Send message, receive tutor reply
- Corrections card appears

## Produces

- 5+ new test files
- Target: 60+ total tests passing
- All screen states covered

## Test commands

```bash
flutter test                        # unit + widget tests
flutter test integration_test/      # integration tests
```
