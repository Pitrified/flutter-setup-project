---
status: draft
depends_on: [02_foundation/01_functional_spec.md, 02_foundation/03_coding_standards.md]
produces: [docs/ai-development-playbook.md]
---

# Plan: AI Development Playbook

## Goal

Define how AI assistants and humans collaborate on this project.
Usage levels, prompting patterns, review checklists, forbidden actions.

## Target output: docs/ai-development-playbook.md

### 1. Philosophy

- AI writes ~90% of the code; human reviews architecture and validates on-device behavior
- AI never invents scope - only implements what docs/functional-specs.md defines
- Docs are updated BEFORE code, not after
- Small atomic diffs. One concern per change.

### 2. Tooling Stack

- GitHub Copilot (VS Code) for inline code generation
- Copilot Chat for larger changes, refactors, and system implementation
- `.github/copilot-instructions.md` for project context (kept short, links to docs/)
- No MCP server needed (Flutter project, no scene editing)

### 3. Configuration Files

| File | Purpose | Max size |
|------|---------|----------|
| .github/copilot-instructions.md | Entry point for AI context | ~80 lines, links to docs/ |
| docs/functional-specs.md | Source of truth for scope | No limit |
| docs/project-structure.md | Where files go | No limit |
| docs/coding-standards.md | How to write code | No limit |

Rule: copilot-instructions.md is a navigation aid, not a full reference.
It points to docs/ for details. Never duplicate content between them.

### 4. AI Usage Levels

| Level | Scope | Review cost | Examples |
|-------|-------|-------------|----------|
| 1 | Models, utilities, tests | Low - verify compiles | Freezed models, logger, extensions |
| 2 | Services, providers | Medium - verify contracts | InferenceEngine impl, repository |
| 3 | Screens, navigation | Medium - verify UX flow | Conversation screen, routing |
| 4 | Build config, signing, publish | High - verify manually | Release build, Play Store config |

### 5. Prompting Pattern

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

### 6. Review Checklist (per AI diff)

Before accepting any AI-generated code:

- [ ] Scope: does it match the task? No extra features?
- [ ] Structure: files in correct locations per project-structure.md?
- [ ] Standards: follows coding-standards.md conventions?
- [ ] Dependencies: no new packages unless explicitly approved?
- [ ] Layer rules: no imports violating layer boundaries?
- [ ] Error handling: expected failures return Result, not throw?
- [ ] Tests: non-trivial logic has tests using FakeInferenceEngine?
- [ ] Logging: uses project logger, not print?

### 7. Forbidden Actions

AI must never:

- Add packages not in the approved dependency list
- Implement features not in functional-specs.md
- Use `print` or `debugPrint` (use project logger)
- Create circular imports between layers
- Put business logic in widgets
- Skip error handling on async operations
- Access services directly from screens (must go through providers)
- Commit generated files without running build_runner (generated files are gitignored)
- Modify pubspec.yaml dependencies without explicit approval
- Use platform channels or native code without explicit approval

### 8. When AI Is Wrong

- Do not re-prompt the same approach
- Check: does the relevant doc cover this case? If not, update docs first
- Check: is the constraint realistic? Some Dart/Flutter patterns differ from the doc assumptions
- Try an alternative approach or ask for options with tradeoffs
- If stuck: ask AI to explain its reasoning, then correct the incorrect assumption

### 9. Human Interaction Handoff

After a feature is implemented, produce a clean file for the user with a list of manual steps to perform.
Place the file in the `plans/<phase>/` folder and link to it from the tracking doc.
Use neat checkboxes like `- [ ]` for the user to check off as they complete each step.
Examples of manual steps: install a tool, create an account, enter credentials, test on physical device.

### 10. Docs Maintenance

After each significant implementation:
1. Verify docs still match reality
2. Update copilot-instructions.md if new systems or patterns emerged
3. Update tracking in plans/00_tracking.md
4. If a doc and code disagree, the doc is wrong (code is running reality) - fix the doc

### 11. Testing with Fake Engine

- All development and testing uses FakeInferenceEngine by default
- Real model testing is done manually on-device only
- CI never loads a real model (too slow, too large)
- FakeInferenceEngine responses cover: valid structured output, invalid JSON,
  empty response, slow response (simulate timeout)

## Key decisions

- No MCP server (unlike unity-setup-project, no scene editing needed)
- Level 4 (build/release) always requires human verification
- FakeInferenceEngine is the default for all automated work
- Docs-first: update spec before implementing
