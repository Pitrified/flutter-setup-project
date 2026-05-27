---
status: not-started
depends_on: [03_scaffold/03_routing_and_providers.md]
produces: [.gitignore, docs/git-workflow.md]
---

# Plan: Git Workflow

## Goal

Configure .gitignore for a Flutter/Android project with codegen, establish branch and
commit conventions, and document the workflow in docs/git-workflow.md.

## Steps

### 1. Create .gitignore

```gitignore
# Flutter/Dart
.dart_tool/
.packages
build/
.flutter-plugins
.flutter-plugins-dependencies
.pub-cache/
.pub/

# Generated code (freezed, json_serializable, riverpod_generator)
*.freezed.dart
*.g.dart

# IDE
.idea/
*.iml
.vscode/
*.swp
*.swo

# Android
android/.gradle/
android/app/debug/
android/app/profile/
android/app/release/
android/local.properties
android/key.properties
*.jks
*.keystore

# macOS (not used, but may appear)
.DS_Store

# Coverage
coverage/
*.lcov

# Misc
*.log
```

### 2. Write docs/git-workflow.md

```markdown
# Git Workflow

## Branch strategy

| Branch | Purpose | Lifetime |
|--------|---------|----------|
| main | Stable, releasable code | Permanent |
| dev | Integration branch for in-progress work | Permanent |
| feature/<name> | Single feature or plan file execution | Until merged |
| fix/<name> | Bug fix | Until merged |

## Commit conventions

Format: `<type>: <short description>`

Types:
- `feat` - new feature or capability
- `fix` - bug fix
- `docs` - documentation only
- `chore` - tooling, deps, config
- `refactor` - code change that neither fixes a bug nor adds a feature
- `test` - adding or updating tests
- `style` - formatting, lint fixes (no logic change)

Examples:
- `feat: add ConversationMessage freezed model`
- `docs: write Phase 03 scaffold plans`
- `chore: configure analysis_options.yaml`
- `fix: correct DateTime serialization in ConversationMessage`

## Rules

- One concern per commit (matches "small atomic diffs" from coding-standards.md)
- Never commit generated files (*.freezed.dart, *.g.dart)
- Never commit secrets, API keys, or keystore files
- Run `flutter analyze` before committing
- Feature branches merge to `dev` via PR; `dev` merges to `main` for releases

## Generated code

Generated files are gitignored. After cloning or pulling, regenerate:

```bash
dart run build_runner build --delete-conflicting-outputs
```

This is also documented in docs/getting-started.md (Section 7).

## Tags

Release tags follow: `v<major>.<minor>.<patch>+<build>`
Example: `v0.1.0+1` (first internal alpha)
```

### 3. Initialize git repo (if not already)

```bash
git init
git add .
git commit -m "chore: scaffold Flutter project (Phase 03)"
git branch dev
```

### 4. Validate

```bash
git status             # no generated files tracked
git diff --cached      # no *.freezed.dart or *.g.dart in staged files
flutter analyze        # still passes after gitignore changes
```

## Key decisions

- Generated code is gitignored (per coding-standards.md). Developers must run build_runner locally.
- Two permanent branches (main + dev) with feature branches for active work.
- Conventional commit types (feat/fix/docs/chore/refactor/test/style).
- No git hooks initially (no husky/lefthook). May add pre-commit in Phase 06 if needed.
- No CI/CD pipeline yet (Phase 07 concern).

## Acceptance criteria

- [ ] .gitignore excludes generated code, IDE files, Android build outputs, keystores
- [ ] docs/git-workflow.md documents branch strategy, commit format, and rules
- [ ] `git status` shows no generated files as untracked
- [ ] Project compiles after clean clone + `flutter pub get` + `build_runner build`
