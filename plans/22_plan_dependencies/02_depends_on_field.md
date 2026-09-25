---
status: planned
---

# Phase 02 - The field, the legacy keys, and the listing

## Overview

`depends_on` on a feature folder's `00_start.md`: parsed, held as edges, and shown. The 27 legacy
phase-level keys are converted to the same convention in the same phase, because a field with two
meanings in the tree is worse than either. No rules yet beyond the shape of the value, so that the graph
can be looked at before anything starts failing over it.
Context: [`00_start.md`](00_start.md), Q6 and "What the 27 legacy keys actually say".
Depends on [`01_typed_frontmatter.md`](01_typed_frontmatter.md).

## Goals

1. `depends_on: [20_repo_split]` parses into a list of folder names on the folder that declares it.
2. One meaning for the key in the whole tree: folder level, on `00_start.md`.
3. `list` shows prerequisites, and marks a row whose prerequisites are not all `done`.

## Plan

- Parse the inline list form (`[a, b]`). One shape, not three: the block-sequence form is another case for
  no benefit while every real value fits on a line.
- Read it **only from `00_start.md`**, which after the conversion below is the only place it appears.
- **Convert the 27 legacy keys** (Q6), by the rules given there:
  - a sub-phase dependency folds up to the feature it names, which produces exactly two edges:
    `04_core_systems` needs `03_scaffold`, and `05_controllers` needs `04_core_systems`. Those go on the
    two `00_start.md` files.
  - a dependency on a doc is dropped. The doc was produced by a phase, so the arrow pointed the wrong way,
    and no rule is made out of it.
  - `[]` is dropped.
  - intra-folder ordering that is worth keeping moves to the new `comment:` key, which nothing checks:
    `05_integration.md` came after the other five phases in its folder, and that is history rather than a
    constraint.
  - `depends_on` then exists on no phase file, so nothing is silently ignored and no special case is
    needed in the validator.
- `comment:` in the typed object as a plain string, absent from `list` output and from every rule.
- `Folder.depends_on: list[str]`, and a module-level function returning the reverse edges, which phase 03
  needs for the cascade message and which is a one-pass inversion of the same data.
- `list` gains a `needs` column showing the prerequisite numbers, and marks a row that is not startable.
  Two markers, not one: a prerequisite missing from the tree needs a merge, and one present but unfinished
  needs work (`00_start.md`, "Two severities").

## Out of scope

- Every check over the graph (phases 03 and 04). Parsing a field and failing a build over it are separate
  steps, and doing them together means the first failure is also the first time anyone sees the data.
- `produces:`, which stays exactly as it is on all 27 files. It is a record of what each phase made, it is
  accurate, and nothing here reads it.

## Done when

- `list` shows `23_dependency_upgrades` needing `20` and marked as not startable, `04_core_systems`
  needing `03`, `05_controllers` needing `04`, and every other row unchanged.
- No phase file carries `depends_on`, and the two doc dependencies and two empty lists are gone.
- `scripts/check.sh` green, with the checker still reporting nothing on the real tree.
