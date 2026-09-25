---
status: done
---

# Phase 05 - Document the field

## Overview

The field exists and is checked; this phase makes it findable by someone who has not read this folder.
Last, because documenting a field before its rules settle means writing it twice.
Depends on [`04_soft_rule_cross_ref.md`](04_soft_rule_cross_ref.md).

## Goals

1. The skill's frontmatter reference describes `depends_on`, its severities, and what is not checked.
2. A reader knows that a phase file's `depends_on` is from an older convention and is ignored.
3. The convention is recorded where it will move to the `tracked-development` skill with the rest.

## Plan

- `.claude/skills/managing-plan-folders/reference/frontmatter.md`: the field in the schema table, the
  rules in the "what `check` reports" list split by severity, and the two things deliberately not done
  (no `superseded_by`, no phase-level dependencies).
- The skill's own workflows: "what should I work on next" reads the `needs` column before recommending
  anything, and a warning about a prerequisite on another branch is something to raise when the folder is
  being worked, not a line to skip.
- One line in the folder 21 queue for the `tracked-development` uplift, since this is one more convention
  that belongs in that skill rather than in this repo.
- `docs/` gets nothing. This is plan-folder tooling, not a fact about the app.

## What the implementation found

- **The markers needed a table, not a sentence.** `20`, `20*` and `20?` mean three different next actions,
  and the reference now says which, because "not startable" collapses two cases that want different work.
- **The skill's "what should I work on next" needed a line**, not just the reference: read `needs`, do not
  recommend a marked row, and raise a `?` on a folder already `in progress` unprompted. That is the point
  where this tooling earns anything.
- **"What is not checked" gained the `superseded_by` decision**, since a reader wondering why the checker
  cannot say what to repoint at deserves the answer in the same file as the rules.
- `docs/` got nothing, as planned. This is plan-folder tooling, not a fact about the app.

## Out of scope

- Adding `depends_on` to folders other than 23. A dependency nobody has a reason for is noise, and the
  field is optional exactly so that most folders carry nothing.
- The move into `tracked-development` itself, which waits for that uplift.

## Done when

- The reference file describes the field, and someone reading only it could write a correct
  `depends_on` and predict what the checker would say.
- `scripts/check.sh` green, links gate included.
