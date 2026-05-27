---
status: not-started
depends_on: [03_scaffold/01_folder_structure.md, docs/functional-specs.md]
produces: [lib/models/*.dart, lib/models/*.freezed.dart, lib/models/*.g.dart]
---

# Plan: Generated Data Models

## Goal

Define the core data models using freezed + json_serializable, run build_runner,
and validate that code generation produces correct output. These models are the
data contracts used across the entire app.

## Models to create

### 1. ConversationMessage

The fundamental chat message unit.

`lib/models/conversation_message.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'conversation_message.freezed.dart';
part 'conversation_message.g.dart';

/// Role of a message sender.
enum MessageRole {
  user,
  tutor,
  system,
}

/// A single message in a conversation.
@freezed
class ConversationMessage with _$ConversationMessage {
  const factory ConversationMessage({
    required String id,
    required MessageRole role,
    required String content,
    required DateTime timestamp,
    TutorResponse? tutorResponse,
  }) = _ConversationMessage;

  factory ConversationMessage.fromJson(Map<String, dynamic> json) =>
      _$ConversationMessageFromJson(json);
}
```

### 2. TutorResponse

The structured output the LLM produces (parsed from JSON).

`lib/models/tutor_response.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'tutor_response.freezed.dart';
part 'tutor_response.g.dart';

/// Structured response from the tutor LLM.
@freezed
class TutorResponse with _$TutorResponse {
  const factory TutorResponse({
    required String reply,
    required List<CorrectionBlock> corrections,
  }) = _TutorResponse;

  factory TutorResponse.fromJson(Map<String, dynamic> json) =>
      _$TutorResponseFromJson(json);
}

/// A single correction the tutor identified in the user's message.
@freezed
class CorrectionBlock with _$CorrectionBlock {
  const factory CorrectionBlock({
    required String original,
    required String corrected,
    required String explanation,
    String? rule,
  }) = _CorrectionBlock;

  factory CorrectionBlock.fromJson(Map<String, dynamic> json) =>
      _$CorrectionBlockFromJson(json);
}
```

### 3. Conversation

A full conversation session (list of messages + metadata).

`lib/models/conversation.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

import 'conversation_message.dart';

part 'conversation.freezed.dart';
part 'conversation.g.dart';

/// A conversation session between user and tutor.
@freezed
class Conversation with _$Conversation {
  const factory Conversation({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    required List<ConversationMessage> messages,
    @Default('pt-BR') String language,
    @Default('A1') String cefrLevel,
  }) = _Conversation;

  factory Conversation.fromJson(Map<String, dynamic> json) =>
      _$ConversationFromJson(json);
}
```

### 4. InferenceStatus

Runtime status of the inference engine.

`lib/models/inference_status.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'inference_status.freezed.dart';

/// Current status of the inference engine.
@freezed
sealed class InferenceStatus with _$InferenceStatus {
  const factory InferenceStatus.uninitialized() = InferenceStatusUninitialized;
  const factory InferenceStatus.loading() = InferenceStatusLoading;
  const factory InferenceStatus.ready() = InferenceStatusReady;
  const factory InferenceStatus.generating() = InferenceStatusGenerating;
  const factory InferenceStatus.error(String message) = InferenceStatusError;
  const factory InferenceStatus.disposed() = InferenceStatusDisposed;
}
```

### 5. ModelInfo

Metadata about a downloaded model file.

`lib/models/model_info.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'model_info.freezed.dart';
part 'model_info.g.dart';

/// Metadata for a downloaded LLM model file.
@freezed
class ModelInfo with _$ModelInfo {
  const factory ModelInfo({
    required String name,
    required String filePath,
    required int fileSizeBytes,
    required DateTime downloadedAt,
    String? version,
    String? checksum,
  }) = _ModelInfo;

  factory ModelInfo.fromJson(Map<String, dynamic> json) =>
      _$ModelInfoFromJson(json);
}
```

## Steps

### 1. Write model files

Create all 5 model files listed above in `lib/models/`.

### 2. Update barrel file

`lib/models/models.dart`:

```dart
export 'conversation.dart';
export 'conversation_message.dart';
export 'inference_status.dart';
export 'model_info.dart';
export 'tutor_response.dart';
```

### 3. Configure build_runner

Create `build.yaml` in project root (optional, only if custom config needed):

```yaml
targets:
  $default:
    builders:
      freezed:
        generate_for:
          include:
            - lib/models/**
      json_serializable:
        generate_for:
          include:
            - lib/models/**
```

### 4. Run code generation

```bash
dart run build_runner build --delete-conflicting-outputs
```

This generates:
- `*.freezed.dart` files (immutable classes, copyWith, equality)
- `*.g.dart` files (JSON serialization)

### 5. Validate

```bash
flutter analyze          # no errors in model files
dart run build_runner build  # generates without errors
flutter test             # compiles successfully
```

### 6. Add a smoke test

`test/models/conversation_message_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fala/models/conversation_message.dart';
import 'package:fala/models/tutor_response.dart';

void main() {
  group('ConversationMessage', () {
    test('creates from factory', () {
      final msg = ConversationMessage(
        id: '1',
        role: MessageRole.user,
        content: 'Eu gosto de cafe',
        timestamp: DateTime(2025, 1, 1),
      );

      expect(msg.role, MessageRole.user);
      expect(msg.content, 'Eu gosto de cafe');
      expect(msg.tutorResponse, isNull);
    });

    test('roundtrips through JSON', () {
      final msg = ConversationMessage(
        id: '1',
        role: MessageRole.tutor,
        content: 'Quase perfeito!',
        timestamp: DateTime(2025, 1, 1),
        tutorResponse: TutorResponse(
          reply: 'Quase perfeito!',
          corrections: [
            CorrectionBlock(
              original: 'cafe',
              corrected: 'cafe',
              explanation: 'Missing accent on e',
            ),
          ],
        ),
      );

      final json = msg.toJson();
      final restored = ConversationMessage.fromJson(json);
      expect(restored, msg);
    });
  });
}
```

## Key decisions

- InferenceStatus uses sealed class (freezed union type) for exhaustive pattern matching
- Conversation stores CEFR level per session (user can change difficulty between sessions)
- TutorResponse is embedded in ConversationMessage (nullable, only present for tutor messages)
- Model files are gitignored (*.freezed.dart, *.g.dart) per coding-standards.md

## Acceptance criteria

- [ ] All 5 model files compile without errors
- [ ] `dart run build_runner build` generates freezed + JSON code
- [ ] Generated files match the patterns in docs/coding-standards.md
- [ ] Smoke test passes (`flutter test`)
- [ ] Barrel file exports all models
- [ ] `flutter analyze` passes
