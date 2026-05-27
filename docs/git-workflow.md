# Git Workflow

## Branch strategy

| Branch | Purpose | Lifetime |
|--------|---------|----------|
| main | Stable, releasable code | Permanent |
| dev | Integration branch for in-progress work | Permanent |
| feature/\<name\> | Single feature or plan file execution | Until merged |
| fix/\<name\> | Bug fix | Until merged |

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
