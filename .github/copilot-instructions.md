# Project: fala

## Overview

On-device language-tutoring app. User chats in Portuguese, receives structured
corrections + conversational replies. Runs Gemma 3 1B entirely on the phone
(Android only). Fully offline after model download.

## Source of truth

- Architecture, scope, constraints: [docs/functional-specs.md](../docs/functional-specs.md)
- Folder layout and naming: [docs/project-structure.md](../docs/project-structure.md)
- Coding rules: [docs/coding-standards.md](../docs/coding-standards.md)
- AI collaboration: [docs/ai-development-playbook.md](../docs/ai-development-playbook.md)
- System specs: [docs/library/](../docs/library/)
- Progress: [plans/00_tracking.md](../plans/00_tracking.md)

If a request contradicts these, the docs win. Stop, highlight the contradiction, and ask for clarification.

## Stack (locked)

Flutter (Dart) - Riverpod - GoRouter - Hive - flutter_gemma (swappable) -
freezed + json_serializable - Android only - min API 26

## Hard rules

- Follow layer boundaries in [project-structure.md](../docs/project-structure.md)
- No business logic in widgets - go through providers
- No `print`/`debugPrint` - use project logger
- No new dependencies without explicit approval
- No features not in [functional-specs.md](../docs/functional-specs.md)
- No iOS, web, or desktop code
- Touch only the files explicitly listed in the request
- Use FakeInferenceEngine for all tests
- Trailing commas on multi-line argument lists
- Generated files (*.freezed.dart, *.g.dart) are gitignored, not committed

## Output style

- Small atomic diffs. One concern per change.
- Public types/methods get `///` doc comments.
- Tests for non-trivial logic.
- Ask one clarifying question if scope is ambiguous; do not invent scope.
- No em dashes, curly quotes, or other fancy punctuation.

## Permanent chat

At the end of all tasks assigned, always ask a follow-up question using the tool #askQuestions to let the user give feedback and guide next steps.
