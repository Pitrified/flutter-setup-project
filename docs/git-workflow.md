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

## Commit cadence

Commit as the code is written, in logical chunks of functionality, rather than
saving everything for one commit at the end. A reader should be able to follow
how the work was built, not just what it ended up as.

How that maps to a plan folder is left to judgement:

- A sub-phase can be several commits when it adds distinct pieces (a model, then
  the UI that uses it).
- A sub-phase can be one commit when it is one coherent change.
- A sub-phase can be zero commits of its own when the whole feature is small
  enough to read as one, or when it only produced plan text that ships with the
  next code commit.

What does not vary: a commit compiles and its tests pass, one concern per commit,
and the message says why the change was made rather than restating the diff.

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
