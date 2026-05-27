---
status: draft
depends_on: [02_foundation/01_functional_spec.md, 02_foundation/02_project_structure.md, 02_foundation/03_coding_standards.md, 02_foundation/04_ai_development_playbook.md]
produces: [.github/copilot-instructions.md]
---

# Plan: Copilot Instructions

## Goal

Rewrite `.github/copilot-instructions.md` to give AI assistants full project context
in a compact format. This file is the entry point - it links to docs/ for details,
never duplicates content.

## Target output: .github/copilot-instructions.md

### Structure

```markdown
# Project: [app-name]

## Overview
On-device language-tutoring app. User chats in target language,
receives structured corrections + conversational replies. Runs a 0.6B-3B
LLM entirely on the phone (Android only). Fully offline after model download.

## Source of truth
- Architecture, scope, constraints: [docs/functional-specs.md](docs/functional-specs.md)
- Folder layout & naming: [docs/project-structure.md](docs/project-structure.md)
- Coding rules: [docs/coding-standards.md](docs/coding-standards.md)
- AI collaboration: [docs/ai-development-playbook.md](docs/ai-development-playbook.md)
- System specs: [docs/library/](docs/library/)
- Progress: [plans/00_tracking.md](plans/00_tracking.md)

If a request contradicts these, the docs win.

## Stack (locked)
Flutter (Dart) - Riverpod - GoRouter - Hive - flutter_gemma (swappable) -
freezed + json_serializable - Android only - min API 26

## Hard rules
- Follow layer boundaries in [project-structure.md](docs/project-structure.md)
- No business logic in widgets - go through providers
- No `print`/`debugPrint` - use project logger
- No new dependencies without explicit approval
- No features not in [functional-specs.md](docs/functional-specs.md)
- No iOS, web, or desktop code
- Touch only the files explicitly listed in the request
- Use FakeInferenceEngine for all tests
- Trailing commas on multi-line argument lists

## Output style
- Small atomic diffs. One concern per change.
- Public types/methods get `///` doc comments.
- Tests for non-trivial logic.
- Ask one clarifying question if scope is ambiguous; do not invent scope.
- No em dashes, curly quotes, or other fancy punctuation.

## Permanent chat
At the end of all tasks assigned, always ask a follow-up question using
#askQuestions to let the user give feedback and guide next steps.
```

### Design principles for this file

1. Under 80 lines total
2. Every claim links to its source doc (no orphan assertions)
3. Hard rules are categorical (no gray zone)
4. Stack section is a one-liner (details in functional-specs.md)
5. Updated after each major phase (not frozen)

## Key decisions

- Keep it minimal - AI reads docs/ for details
- Clickable links to all referenced docs
- Matches the pattern from unity-setup-project (proven effective)
- "Permanent chat" section ensures iterative feedback loop
