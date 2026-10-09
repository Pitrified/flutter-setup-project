# Coding Standards

## 1. Formatting

- `dart format` is the authority, and a gate: `scripts/check.sh` fails on any tracked Dart file it would change
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

- Use the project logger, `AppLogger.instance` (`lib/services/logging/app_logger.dart`), never `print` or `debugPrint` directly. It wraps `debugPrint` and is a no-op in release builds
- Log levels: `info`, `warn`, `error` (with an optional `cause`)
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
- A new test has to fail when the code it covers is broken. Break the code by hand (drop a filter, skip a call), run the test, see it fail, then restore the code.

### Widget tests that write to Hive

`testWidgets` runs in fake async, where Hive's file I/O never completes, so a test that waits on a write hangs or sees stale data.

- Seed data and pump the first frame inside `tester.runAsync`.
- A tap whose handler writes to Hive runs inside `tester.runAsync`, followed by a real delay of about 100 ms.
- A dialog's `await showDialog(...)` continues in the zone of the tap that opened it. If the code after the dialog writes to Hive, open the dialog inside `tester.runAsync` too, not only the confirming tap.
- A GoRouter push or pop takes longer than 500 ms of pumped time. `pumpAndSettle` does not finish while a progress indicator animates, so pump in steps (25 pumps of 50 ms) instead. Until the transition finishes, the page underneath still matches finders.
- Use a fresh box name per test (`'test_box_$run'` with a counter). Hive keeps a box open by name across tests.
- Do not close Hive boxes in `tearDown`, which hangs. Delete the temp directory instead.
- Ids made from `millisecondsSinceEpoch` collide when two records are created in the same millisecond. A user cannot do that, a test can, so a test that creates records in a loop waits 2 ms between them.

## 11. Documentation

- Public API gets `///` doc comments
- Private code: comments explain WHY, not WHAT
- No doc comments on obvious getters/setters
- TODOs include explanation of when to resolve
