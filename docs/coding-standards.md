# Coding Standards

## 1. Formatting

- `dart format` is the authority
- Line length: 80 characters
- Trailing commas on all multi-line argument lists
- Single quotes for strings
- No manual formatting overrides

## 2. Naming

| Item | Convention | Example |
|------|-----------|---------|
| Classes, enums, typedefs | PascalCase | `InferenceEngine` |
| Variables, parameters, functions | camelCase | `conversationHistory` |
| Constants | camelCase | `maxRetryCount` |
| Private members | _camelCase | `_isInitialized` |
| File names | snake_case | `inference_engine.dart` |
| Named parameters | always use named for > 2 params | `Message(role: role, content: content)` |

## 3. State Management (Riverpod)

- Use `@riverpod` annotation (code generation)
- AsyncNotifier for services with loading/error states
- Notifier for synchronous state
- Provider for computed/derived values
- Never use ChangeNotifier or setState
- Providers live in `lib/providers/`, one file per feature area
- Dispose logic in `ref.onDispose()`

## 4. Widget Decomposition

- One folder per screen in `lib/screens/`
- Each screen folder: screen widget + local widgets + local state
- Extract widget when: reused OR > 50 lines build method OR has own state
- Prefer composition over inheritance
- No business logic in widgets - delegate to providers/services
- Use `const` constructors wherever possible

## 5. Data Models (Freezed)

- All data models use `@freezed`
- JSON serialization via `@JsonSerializable`
- Factory constructors: `factory X.fromJson(Map<String, dynamic> json)`
- No business logic in models (pure data)
- Default values in factory constructor
- Union types for state: `@freezed sealed class InferenceState`

## 6. Error Handling

- Services return typed results for expected failures (sealed class: Success/Failure)
- Exceptions only for programmer errors
- Never catch generic `Exception` or `Object`
- All async code handles errors explicitly
- UI shows error state from provider's AsyncError

## 7. Async Patterns

- Always `await` Futures (no fire-and-forget unless documented why)
- Use `AsyncValue` from Riverpod for loading/error/data in UI
- Cancellation via `ref.onDispose()` and CancelToken patterns
- No `Timer` for polling
- Heavy computation off main isolate via `Isolate.run()`

## 8. Logging

- Use project logger (`lib/utils/logger.dart`), never `print` or `debugPrint`
- Log levels: debug, info, warning, error
- Debug logs: inference timing, prompt token count, model info
- Error logs: stack trace, context of what was attempted
- No sensitive data in logs (no user messages in production)

## 9. Imports

- Relative imports within the package
- Absolute imports for package dependencies
- Order: dart core, packages, relative (`dart format` handles this)
- No barrel files - import specifically

## 10. Testing

- Every service has unit tests (test/ mirrors lib/)
- Widget tests for screens (key interactions, not pixel-perfect)
- Integration tests for critical flows (uses FakeInferenceEngine)
- Test file naming: `<source_file>_test.dart`
- `setUp`/`tearDown` for provider overrides
- No tests depend on real model inference

## 11. Documentation

- Public API gets `///` doc comments
- Private code: comments explain WHY, not WHAT
- No doc comments on obvious getters/setters
- TODOs include explanation of when to resolve
