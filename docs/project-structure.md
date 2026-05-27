# Project Structure

## Folder layout

```
fala/                                 # Flutter project root
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

## Layer rules

| Layer | Path | Can depend on | Cannot depend on |
|-------|------|---------------|------------------|
| Models | lib/models/ | Nothing (pure data) | Everything else |
| Config | lib/config/ | Models | Services, Screens, Providers |
| Services | lib/services/ | Models, Config | Screens, Widgets |
| Providers | lib/providers/ | Services, Models, Config | Screens |
| Screens | lib/screens/ | Providers, Widgets, Models | Services directly |
| Widgets | lib/widgets/ | Models | Services, Providers, Screens |
| Utils | lib/utils/ | Nothing | (used by all layers) |

Key constraint: screens never import from services directly - they go through providers.

## Naming conventions

| Item | Convention | Example |
|------|-----------|---------|
| Files | snake_case | `conversation_controller.dart` |
| Classes | PascalCase | `ConversationController` |
| Providers | camelCase + Provider suffix | `conversationControllerProvider` |
| Freezed models | PascalCase | `ConversationMessage` |
| Enums | PascalCase type, camelCase values | `InferenceStatus.ready` |
| Folders | snake_case | `model_download/` |
| Test files | same name + _test | `conversation_controller_test.dart` |

## Assets

- `assets/prompts/` - versioned prompt templates (`v1.txt`, `v2.txt`, etc.)
- `assets/fixtures/` - fake engine responses for development and testing
- Registered in `pubspec.yaml` under `flutter.assets`

## Generated code

- Freezed output: `*.freezed.dart` and `*.g.dart`
- **Not committed to git** (gitignored)
- Regenerate locally: `dart run build_runner build --delete-conflicting-outputs`

## Package boundaries

Single package with logical layer separation. No multi-package monorepo.
Import rules enforced by lint (no circular imports) and layer conventions above.
