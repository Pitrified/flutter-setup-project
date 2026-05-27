---
status: draft
depends_on: [02_foundation/02_project_structure.md]
produces: [template for docs/library/*.md]
---

# Plan: System Specs Template

## Goal

Define a reusable template for all system documentation in docs/library/.
Every system spec follows the same structure so AI can learn the pattern once
and generate code from any spec consistently.

However, remember that `foolish consistency is the hobgoblin of little minds`,
so the template can be adapted if needed.

## Target output: template used across docs/library/*.md

### Template structure

Each system spec in docs/library/ follows these sections in this order:

```markdown
# SystemName

## Overview

1-3 sentences describing the system's core role and why it exists.

## Responsibilities

Bulleted list of what this system owns. 5-10 items maximum.
Each item is a verb phrase (e.g., "Manage message history").

## Ownership and Lifetime

- Created by: [what creates it]
- Lifetime: [app-wide singleton | session-scoped | transient]
- Managed via: [Riverpod provider type]

## Public Interface

The primary methods/properties this system exposes.
Use Dart-style signatures (not full implementation):

- `Future<void> initialize()` - description
- `Future<StructuredOutput> predict(String prompt)` - description
- `void dispose()` - description

## State

What this system holds internally:

- stateField1: type - description
- stateField2: type - description

## Interactions

### Uses
- [SystemA](system-a.md) - what it gets from A
- [SystemB](system-b.md) - what it gets from B

### Used by
- [SystemC](system-c.md) - what C gets from this system

## Constraints

What this system CANNOT do (explicit boundaries):

- No UI rendering
- No direct file I/O (delegates to repository)
- No model-specific logic (delegates to engine)

## Failure Handling

| Failure | Detection | Recovery |
|---------|-----------|----------|
| failure_case_1 | how detected | what happens |
| failure_case_2 | how detected | what happens |
```

### Rules for writing system specs

1. Each spec is self-contained - readable without other docs
2. The "Uses/Used by" section creates a dependency graph across specs
3. Constraints prevent scope creep (AI checks constraints before adding features)
4. Public Interface uses Dart signatures (not pseudocode)
5. No implementation details - only contracts and behavior
6. Failure handling is explicit (AI generates error handling from this table)

### Systems to document (from functional-specs.md section 6)

| System | File | Priority |
|--------|------|----------|
| AppController | docs/library/app-controller.md | Phase 03 (scaffold) |
| InferenceEngine | docs/library/inference-engine.md | Phase 04 (core) |
| ConversationController | docs/library/conversation-controller.md | Phase 05 (loop) |
| StructuredOutputSystem | docs/library/structured-output-system.md | Phase 04 (core) |
| ConversationRepository | docs/library/conversation-repository.md | Phase 04 (core) |
| RuntimeModelManager | docs/library/runtime-model-manager.md | Phase 04 (core) |
| PromptManager | docs/library/prompt-manager.md | Phase 04 (core) |

System specs are written as part of their respective phase plans (not all upfront).
The template is established here; actual specs are produced during implementation phases.

## Key decisions

- Dart signatures in interface (not pseudocode) - AI can generate directly from them
- No implementation details in specs - specs define WHAT, code defines HOW
- Failure handling as a table - structured format AI can parse deterministically
- Specs written alongside implementation (not all upfront) - avoids spec drift
