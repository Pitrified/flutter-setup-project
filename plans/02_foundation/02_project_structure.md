---
status: draft
depends_on: [02_foundation/01_functional_spec.md]
produces: [docs/project-structure.md]
---

# Plan: Project Structure

## Goal

Define the folder layout, layer boundaries, and naming conventions for the Flutter app.
AI assistants use this as the authority on where to place new files.

## Target output: docs/project-structure.md

### Top-level layout

```
flutter_app/                          # Flutter project root (name TBD)
  android/                            # Android-specific (mostly generated)
  assets/
    prompts/                          # Versioned prompt templates
      tutor_response/
        v1.txt
    fixtures/                         # Fake engine response fixtures
      tutor_responses.json
  lib/
    main.dart                         # Entry point
    app.dart                          # App widget, providers, router
    config/                           # Typed configuration classes
    models/                           # Freezed data models (generated)
    providers/                        # Riverpod providers
    screens/                          # UI screens (one folder per screen)
      welcome/
      conversation/
      model_download/
    services/                         # Business logic services
      inference/                      # InferenceEngine + implementations
      conversation/                   # ConversationController
      persistence/                    # ConversationRepository
      model/                          # RuntimeModelManager
      prompt/                         # PromptManager
    widgets/                          # Shared reusable widgets
    utils/                            # Logging, extensions, helpers
  test/
    models/
    services/
    screens/
    fixtures/
  pubspec.yaml
  analysis_options.yaml
```

### Layer rules

| Layer | Path | Can depend on | Cannot depend on |
|-------|------|---------------|------------------|
| Models | lib/models/ | Nothing (pure data) | Everything else |
| Config | lib/config/ | Models | Services, Screens, Providers |
| Services | lib/services/ | Models, Config | Screens, Widgets |
| Providers | lib/providers/ | Services, Models, Config | Screens |
| Screens | lib/screens/ | Providers, Widgets, Models | Services directly |
| Widgets | lib/widgets/ | Models | Services, Providers, Screens |
| Utils | lib/utils/ | Nothing | - (used by all layers) |

### Naming conventions

| Item | Convention | Example |
|------|-----------|---------|
| Files | snake_case | conversation_controller.dart |
| Classes | PascalCase | ConversationController |
| Providers | camelCase with Provider suffix | conversationControllerProvider |
| Freezed models | PascalCase | ConversationMessage |
| Enums | PascalCase (type), camelCase (values) | InferenceStatus.ready |
| Folders | snake_case | model_download/ |
| Test files | same name + _test suffix | conversation_controller_test.dart |

### Package boundaries

Unlike Unity asmdefs, Flutter uses a single package with logical layer separation.
Import rules are enforced by lint rules (no circular imports) and code review, not compiler.

Key constraint: screens never import from services directly - they go through providers.
This keeps the UI layer testable and the service layer swappable.

### Assets organization

- `assets/prompts/` - versioned prompt templates (v1.txt, v2.txt, etc.)
- `assets/fixtures/` - fake engine responses for development and testing
- Assets registered in pubspec.yaml under `flutter.assets`

### Generated code

- Freezed models: `lib/models/*.freezed.dart` and `*.g.dart`
- Generated files are NOT committed to git (keep repo clean and small)
- `.gitignore` includes `*.freezed.dart`, `*.g.dart`
- Developers run `dart run build_runner build --delete-conflicting-outputs` after cloning or after model changes
- This is a one-time local step, not a CI concern (no CI pipeline exists for this project)

## Key decisions

- Single package (no multi-package monorepo) - simplest for a focused app
- Generated files excluded from git - keeps diffs clean and repo small; regeneration is a fast local command
- Screens access services only through providers - enforces testability
- Prompts as assets (not hardcoded strings) - enables versioning and hot-reload during dev
