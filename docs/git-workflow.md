# Git Workflow

## Branch strategy

| Branch | Purpose | Lifetime |
|--------|---------|----------|
| main | The trunk: everything lands here | Permanent |
| feature/\<name\> | Planning and implementation of one feature folder | Until merged |
| fix/\<name\> | Bug fix | Until merged |

There is no `dev`. One repo, one person, one box: an integration branch between
the work and `main` is ceremony with nothing on the other side of it.

**Straight to main**, no branch:

- A draft spin-off folder (a `00_start.md` at `status: draft` recording work that
  surfaced but is out of scope).
- Small docs edits, and changes to the instructions or conventions themselves.

**Its own branch**: the planning *and* implementation of a feature folder, from
`00_start.md` through the last sub-phase.

Feature branches merge with `--no-ff`, always, even when `main` could fast
forward:

```bash
git checkout main
git merge --no-ff feature/<name>
```

The merge commit is the point. It keeps the feature's commits grouped and shows
the detour in the graph, so `git log --graph` reads as a list of features rather
than as one undifferentiated line of commits.

## Commit conventions

Format: `<type>(<scope>): <short description>`

The scope is the part of the project the change is about (`language`, `gates`,
`plans`, `android`, ...). It is optional when a change has no obvious one, but
the history mostly carries it.

Types:
- `feat` - new feature or capability
- `fix` - bug fix
- `docs` - documentation only
- `chore` - tooling, deps, config
- `refactor` - code change that neither fixes a bug nor adds a feature
- `test` - adding or updating tests
- `style` - formatting, lint fixes (no logic change)

Examples:
- `feat(models): add ConversationMessage freezed model`
- `docs(plans): write Phase 03 scaffold plans`
- `chore: configure analysis_options.yaml`
- `fix(models): correct DateTime serialization in ConversationMessage`

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
- Feature branches merge to `main` with `--no-ff` (see "Branch strategy")

## Generated code

Generated files are gitignored. After cloning or pulling, regenerate:

```bash
dart run build_runner build --delete-conflicting-outputs
```

This is also documented in docs/getting-started.md (Section 7).

## Tags

Release tags follow: `v<major>.<minor>.<patch>+<build>`
Example: `v0.1.0+1` (first internal alpha)
