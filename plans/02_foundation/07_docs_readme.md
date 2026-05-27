---
status: draft
depends_on: [02_foundation/01_functional_spec.md, 02_foundation/02_project_structure.md, 02_foundation/04_ai_development_playbook.md, 02_foundation/05_system_specs_template.md]
produces: [docs/README.md]
---

# Plan: Docs README

## Goal

Create docs/README.md as the documentation index. It gives readers (human or AI)
a reading order, a mental model of the doc set, and a workflow loop for making changes.
It links to everything but duplicates nothing.

## Target output: docs/README.md

### Structure

```markdown
# Project Documentation

All documentation needed to go from zero to a working private alpha.

## Reading order

1. [functional-specs.md](functional-specs.md) - WHAT we are building
2. [project-structure.md](project-structure.md) - WHERE code lives
3. [coding-standards.md](coding-standards.md) - HOW code is written
4. [ai-development-playbook.md](ai-development-playbook.md) - HOW we work with AI
5. [getting-started.md](getting-started.md) - Get it running locally

## Index

### Project and process
- [functional-specs.md](functional-specs.md)
- [project-structure.md](project-structure.md)
- [coding-standards.md](coding-standards.md)
- [git-workflow.md](git-workflow.md)
- [testing-strategy.md](testing-strategy.md)

### AI workflow
- [ai-development-playbook.md](ai-development-playbook.md)

### Guides
- [guides/prompts.md](guides/prompts.md)
- [guides/model-management.md](guides/model-management.md)
- [guides/structured-output.md](guides/structured-output.md)

### System specs (library)
- [library/app-controller.md](library/app-controller.md)
- [library/inference-engine.md](library/inference-engine.md)
- [library/conversation-controller.md](library/conversation-controller.md)
- [library/structured-output-system.md](library/structured-output-system.md)
- [library/conversation-repository.md](library/conversation-repository.md)
- [library/runtime-model-manager.md](library/runtime-model-manager.md)
- [library/prompt-manager.md](library/prompt-manager.md)

### Build and release
- [build/build-and-release.md](build/build-and-release.md)
- [build/google-play-alpha.md](build/google-play-alpha.md)

## Mental model

| Doc set | Question it answers |
|---------|---------------------|
| Functional spec | What are we building? |
| Project structure | Where does code live? |
| Coding standards | How do we write code? |
| AI playbook | How do we work with AI? |
| Guides | How do specific subsystems work? |
| System specs | How does each piece behave? |
| Build/release | How do we ship? |

## Workflow loop

1. Define/update the feature in functional-specs.md and the relevant library/*.md
2. Write a focused prompt (see ai-development-playbook.md prompting pattern)
3. Review the diff against the review checklist
4. Run tests; verify on emulator
5. Commit. Update plans/00_tracking.md

## Ground rules

- functional-specs.md is the source of truth
- Do not implement features not defined there
- Update docs BEFORE implementing, not after
- Docs link to each other - never duplicate content
- If something is unclear, fix the docs first
```

### Design principles

1. Under 80 lines of content (dense but scannable)
2. Every doc is listed with a clickable link
3. Mental model table answers "why should I read this?"
4. Workflow loop is the repeatable cycle for every feature
5. Ground rules prevent drift

## Key decisions

- Flat listing (no deep nesting) - easy to scan
- Guides and library are separate sections (tooling vs system behavior)
- Reading order is prescriptive (not alphabetical)
- Build docs go in a subfolder since they are only relevant at release time
