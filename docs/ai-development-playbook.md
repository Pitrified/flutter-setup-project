# AI Development Playbook

## 1. Philosophy

- AI writes ~90% of the code; human reviews architecture and validates on-device behavior
- AI never invents scope - only implements what [functional-specs.md](functional-specs.md) defines
- Docs are updated BEFORE code, not after
- Small atomic diffs. One concern per change.

## 2. Tooling Stack

- GitHub Copilot (VS Code) for inline generation and chat
- `.github/copilot-instructions.md` for project context (links to docs/)
- No MCP server needed (no scene editing, no Unity)

## 3. Configuration Files

| File | Purpose | Size |
|------|---------|------|
| [../.github/copilot-instructions.md](../.github/copilot-instructions.md) | AI entry point | ~80 lines, links to docs/ |
| [functional-specs.md](functional-specs.md) | Source of truth for scope | Unlimited |
| [project-structure.md](project-structure.md) | Where files go | Unlimited |
| [coding-standards.md](coding-standards.md) | How to write code | Unlimited |

Rule: copilot-instructions.md is a navigation aid, not a full reference.

## 4. AI Usage Levels

| Level | Scope | Review cost | Examples |
|-------|-------|-------------|----------|
| 1 | Models, utilities, tests | Low | Freezed models, logger, extensions |
| 2 | Services, providers | Medium | InferenceEngine impl, repository |
| 3 | Screens, navigation | Medium | Conversation screen, routing |
| 4 | Build config, signing, publish | High | Release build, Play Store config |

## 5. Prompting Pattern

Every non-trivial request to the AI should include:

```
## Context
- Tech stack: [relevant subset]
- Relevant docs: [links to system spec, coding standards section]
- Current state: [what exists, what's been built]

## Task
[One concrete change - single responsibility]

## Constraints
- Touch only files: [explicit list]
- Follow: [relevant coding standards section]
- No new dependencies unless listed
- Use FakeInferenceEngine for testing
```

## 6. Review Checklist (per AI diff)

- [ ] Scope: matches the task? No extra features?
- [ ] Structure: files in correct locations per [project-structure.md](project-structure.md)?
- [ ] Standards: follows [coding-standards.md](coding-standards.md)?
- [ ] Dependencies: no new packages unless approved?
- [ ] Layer rules: no imports violating boundaries?
- [ ] Error handling: expected failures return Result, not throw?
- [ ] Tests: non-trivial logic tested with FakeInferenceEngine?
- [ ] Logging: uses project logger, not print?

## 7. Forbidden Actions

AI must never:

- Add packages not in the approved dependency list
- Implement features not in [functional-specs.md](functional-specs.md)
- Use `print` or `debugPrint`
- Create circular imports between layers
- Put business logic in widgets
- Skip error handling on async operations
- Access services directly from screens (go through providers)
- Modify pubspec.yaml dependencies without explicit approval
- Use platform channels or native code without explicit approval

## 8. When AI Is Wrong

- Do not re-prompt the same approach
- Check: does the relevant doc cover this case? If not, update docs first
- Check: is the constraint realistic? Dart/Flutter may differ from assumptions
- Try an alternative approach or ask for options with tradeoffs
- If stuck: ask AI to explain its reasoning, then correct the assumption

## 9. Human Interaction Handoff

After a feature is implemented, produce a clean file with manual steps for the user.
Place it in `plans/<phase>/` and link from the tracking doc.
Use checkboxes (`- [ ]`) for the user to complete.
Examples: install a tool, create an account, enter credentials, test on physical device.

## 10. Docs Maintenance

After each significant implementation:

1. Verify docs still match reality
2. Update copilot-instructions.md if new systems or patterns emerged
3. Update tracking in [../plans/00_tracking.md](../plans/00_tracking.md)
4. If a doc and code disagree, the doc is wrong - fix the doc

## 11. Testing with Fake Engine

- All development and testing uses FakeInferenceEngine by default
- Real model testing is done manually on-device only
- No automated tests load a real model
- FakeInferenceEngine responses cover: valid structured output, invalid JSON,
  empty response, slow response (simulate timeout)
