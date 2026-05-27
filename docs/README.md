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
- [getting-started.md](getting-started.md)

### AI workflow

- [ai-development-playbook.md](ai-development-playbook.md)

### Guides (created during implementation)

- guides/prompts.md - On-device prompt engineering
- guides/model-management.md - Download, cache, validate model files
- guides/structured-output.md - Schema validation pipeline

### System specs (created during implementation)

- library/app-controller.md
- library/inference-engine.md
- library/conversation-controller.md
- library/structured-output-system.md
- library/conversation-repository.md
- library/runtime-model-manager.md
- library/prompt-manager.md

### Build and release (created during Phase 07)

- build/build-and-release.md
- build/google-play-alpha.md

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

1. Define/update the feature in [functional-specs.md](functional-specs.md) and the relevant library/ spec
2. Write a focused prompt (see [ai-development-playbook.md](ai-development-playbook.md) section 5)
3. Review the diff against the [review checklist](ai-development-playbook.md#6-review-checklist-per-ai-diff)
4. Run tests; verify on emulator
5. Update [plans/00_tracking.md](../plans/00_tracking.md)
6. Update the relevant guide with usage instructions and examples.
7. HUMAN: Commit.

## Ground rules

- [functional-specs.md](functional-specs.md) is the source of truth
- Do not implement features not defined there
- Update docs BEFORE implementing, not after
- Docs link to each other - never duplicate content
- If something is unclear, clarify by asking questions to the users, then update the docs before implementation
