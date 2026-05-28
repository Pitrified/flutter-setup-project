# Plan 06/00 - Error Handling

## Status: not-started

## Goal

Define a failure taxonomy and ensure every error path produces a recoverable
UI state. No unhandled exceptions, no silent failures, no infinite loading.

## Context

Current error handling is ad-hoc:
- `StructuredResult<T>` has three states (success, inference failure, parse failure)
- `AppState` has `AppError(message)`
- `DownloadStatus` has `DownloadFailed(error)`
- `InferenceResult` has `InferenceFailure(error)`
- Try/catch in model_manager, flutter_gemma_engine, json_extractor, prompt_manager

Missing:
- No unified error type or logging pattern
- No global error boundary widget
- Screens handle errors locally but inconsistently
- No user-facing error messages strategy (localization-ready)

## Tasks

### 1. Create `AppException` hierarchy

File: `lib/models/app_exception.dart`

```dart
sealed class AppException implements Exception {
  const AppException({required this.message, this.cause});
  final String message;
  final Object? cause;
}

class InferenceException extends AppException { ... }
class ModelException extends AppException { ... }
class StorageException extends AppException { ... }
class NetworkException extends AppException { ... }
```

### 2. Create error boundary widget

File: `lib/widgets/error_boundary.dart`

A widget that catches errors from child widget tree and displays a recovery UI
(retry button + error message). Wraps each screen in the router.

### 3. Add error logging service

File: `lib/services/logging/app_logger.dart`

Thin wrapper that logs to console in debug, suppresses in release.
All services should use this instead of raw `print`/`debugPrint`.

### 4. Audit and update error paths

- `ModelManager.downloadModel`: wrap HTTP/IO errors in `NetworkException`/`StorageException`
- `FlutterGemmaEngine`: wrap engine errors in `InferenceException`
- `ConversationController.sendMessage`: surface error type to UI via conversation stream
- `AppController.initialize`: catch and wrap unexpected errors

### 5. Add user-facing error messages

File: `lib/config/error_messages.dart`

Map `AppException` subtypes to user-friendly messages. Keep in one place
for future localization.

## Produces

- `lib/models/app_exception.dart`
- `lib/widgets/error_boundary.dart`
- `lib/services/logging/app_logger.dart`
- `lib/config/error_messages.dart`
- Updates to existing services

## Tests

- Unit test: each exception type formats correctly
- Widget test: error boundary displays retry button on error
