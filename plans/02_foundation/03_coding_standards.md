---
status: draft
depends_on: [02_foundation/02_project_structure.md]
produces: [docs/coding-standards.md]
---

# Plan: Coding Standards

## Goal

Define how Dart/Flutter code is written in this project. AI assistants follow these rules
for all generated code. Human reviewers check against these standards.

## Target output: docs/coding-standards.md

### 1. Formatting

- Dart formatter (`dart format`) is the authority - no manual formatting arguments
- Line length: 80 characters (Dart default)
- Trailing commas on all multi-line argument lists (enables better diffs)
- Single quotes for strings (enforced by lint)
- No semicolons after class/enum declarations (Dart style)

### 2. Naming

| Item | Convention | Example |
|------|-----------|---------|
| Classes, enums, typedefs | PascalCase | `InferenceEngine` |
| Variables, parameters, functions | camelCase | `conversationHistory` |
| Constants | camelCase | `maxRetryCount` |
| Private members | _camelCase | `_isInitialized` |
| File names | snake_case | `inference_engine.dart` |
| Named parameters | always use named for > 2 params | `Message(role: role, content: content)` |

### 3. State Management (Riverpod)

- Use `@riverpod` annotation (code generation) over manual provider definitions
- AsyncNotifier for services with loading/error states
- Notifier for synchronous state
- Provider for computed/derived values
- Never use ChangeNotifier or setState (except throwaway prototypes)
- Providers live in `lib/providers/`, one file per feature area
- Dispose logic in provider's `ref.onDispose()`

### 4. Widget Decomposition

- Screens are top-level route targets (one folder per screen in `lib/screens/`)
- Each screen folder: screen widget + local widgets + local state (if any)
- Extract widget when: reused OR > 50 lines of build method OR has its own state
- Prefer composition over inheritance (no deep widget hierarchies)
- No business logic in widgets - delegate to providers/services
- Use `const` constructors wherever possible

### 5. Data Models (Freezed)

- All data models use `@freezed` - no manual immutable classes
- JSON serialization via `@JsonSerializable` on the freezed class
- Factory constructors: `factory Message.fromJson(Map<String, dynamic> json)`
- No business logic in models (pure data)
- Default values in factory constructor, not in fields
- Union types for state enums: `@freezed sealed class InferenceState`

### 6. Error Handling

- Services return typed results, not exceptions, for expected failures
  (use a Result type or sealed class: Success/Failure)
- Exceptions only for programmer errors (assert in debug, throw in release)
- Never catch generic `Exception` or `Object` - catch specific types
- All async code handles errors explicitly (no unhandled Future rejections)
- UI shows error state from provider's AsyncError, never from try/catch in widgets

### 7. Async Patterns

- Always `await` Futures (no fire-and-forget unless explicitly documented why)
- Use `AsyncValue` from Riverpod for loading/error/data in UI
- Cancellation via `ref.onDispose()` and CancelToken patterns
- No `Timer` for polling - use Stream or Riverpod refresh mechanisms
- Heavy computation off main isolate via `compute()` or `Isolate.run()`

### 8. Logging

- Use a project logging utility (lib/utils/logger.dart), never `print` or `debugPrint`
- Log levels: debug, info, warning, error
- Debug logs include: inference timing, prompt token count, model info
- Error logs include: stack trace, context (what was being attempted)
- No sensitive data in logs (no user messages in production logs)

### 9. Imports

- Relative imports within the package (`import '../models/message.dart'`)
- Absolute imports for package dependencies (`import 'package:riverpod/riverpod.dart'`)
- Order: dart core, packages, relative (dart format handles this)
- No barrel files (index.dart that re-exports everything) - import specifically

### 10. Testing

- Every service has unit tests (test/ mirrors lib/ structure)
- Widget tests for screens (verify key interactions, not pixel-perfect)
- Integration tests for critical flows (uses FakeInferenceEngine)
- Test file naming: `<source_file>_test.dart`
- Use `setUp`/`tearDown` for provider overrides
- No tests that depend on real model inference (always use fake engine in tests)

### 11. Documentation

- Public API gets `///` doc comments (classes, public methods, providers)
- Private implementation: comments explain WHY, not WHAT
- No doc comments on obvious getters/setters
- TODOs include ticket/issue reference or explanation of when to resolve

## Key decisions

- Trailing commas enforced (cosmetic but improves git diffs significantly)
- Result type for service errors vs exceptions (reduces unhandled crash surface)
- No barrel files (explicit imports are clearer for AI code generation)
- Relative imports within package (simpler, avoids package name dependency)
