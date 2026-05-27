---
status: not-started
depends_on: [03_scaffold/00_create_project.md, docs/project-structure.md]
produces: [lib/ folder tree, analysis_options.yaml, test/ folder tree]
---

# Plan: Folder Structure

## Goal

Create the full folder tree defined in docs/project-structure.md, add placeholder files
in each directory, and configure analysis_options.yaml with strict linting rules.
After this step the project compiles with the empty structure in place.

## Steps

### 1. Create lib/ directory tree

```bash
mkdir -p lib/config
mkdir -p lib/models
mkdir -p lib/providers
mkdir -p lib/screens/welcome
mkdir -p lib/screens/conversation
mkdir -p lib/screens/model_download
mkdir -p lib/services/inference
mkdir -p lib/services/conversation
mkdir -p lib/services/persistence
mkdir -p lib/services/model
mkdir -p lib/services/prompt
mkdir -p lib/widgets
mkdir -p lib/utils
```

### 2. Add placeholder barrel files

Each directory gets a placeholder file so git tracks it and imports are ready:

| File | Content |
|------|---------|
| `lib/config/config.dart` | `// Configuration classes` |
| `lib/models/models.dart` | `// Barrel file for data models` |
| `lib/providers/providers.dart` | `// Barrel file for Riverpod providers` |
| `lib/services/inference/inference_engine.dart` | `// InferenceEngine interface (Phase 04)` |
| `lib/services/conversation/conversation_controller.dart` | `// ConversationController (Phase 05)` |
| `lib/services/persistence/conversation_repository.dart` | `// ConversationRepository (Phase 04)` |
| `lib/services/model/model_manager.dart` | `// RuntimeModelManager (Phase 04)` |
| `lib/services/prompt/prompt_manager.dart` | `// PromptManager (Phase 04)` |
| `lib/widgets/widgets.dart` | `// Shared widgets barrel` |
| `lib/utils/logger.dart` | Logger utility (see section 4) |

### 3. Create test/ directory tree

```bash
mkdir -p test/models
mkdir -p test/services
mkdir -p test/screens
mkdir -p test/fixtures
```

### 4. Create logger utility

`lib/utils/logger.dart`:

```dart
import 'package:logger/logger.dart';

/// Project-wide logger instance.
///
/// Use this instead of print/debugPrint throughout the app.
/// Log levels: verbose, debug, info, warning, error, fatal.
final log = Logger(
  printer: PrettyPrinter(
    methodCount: 0,
    printTime: true,
  ),
);
```

### 5. Configure analysis_options.yaml

```yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  errors:
    missing_return: error
    dead_code: warning
  exclude:
    - "**/*.freezed.dart"
    - "**/*.g.dart"

linter:
  rules:
    - always_declare_return_types
    - avoid_dynamic_calls
    - avoid_print
    - avoid_relative_lib_imports
    - cancel_subscriptions
    - close_sinks
    - directives_ordering
    - no_adjacent_strings_in_list
    - prefer_const_constructors
    - prefer_const_declarations
    - prefer_final_fields
    - prefer_final_locals
    - prefer_single_quotes
    - require_trailing_commas
    - sort_pub_dependencies
    - unawaited_futures
    - unnecessary_await_in_return
```

Key points:
- `avoid_print` enforces the project rule (use logger, not print)
- `require_trailing_commas` matches coding-standards.md
- Generated files excluded from analysis

### 6. Validate

```bash
flutter analyze    # should pass with empty structure
flutter test       # should pass (no tests yet, zero failures)
```

## Layer rules verification

After creating the structure, confirm it matches docs/project-structure.md:
- Models depend on nothing
- Services depend on Models and Config only
- Providers depend on Services, Models, Config
- Screens depend on Providers, Widgets, Models (never Services directly)

These are enforced by convention now and will be validated by lint rules once code exists.

## Acceptance criteria

- [ ] All directories from docs/project-structure.md exist
- [ ] Each directory has at least one placeholder file
- [ ] `analysis_options.yaml` configured with strict rules
- [ ] Generated files (*.freezed.dart, *.g.dart) excluded from analysis
- [ ] `flutter analyze` passes
- [ ] Logger utility exists at `lib/utils/logger.dart`
