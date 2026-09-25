---
status: planned
---

# Phase 02 - The field, parsed and listed

## Overview

`depends_on` on a feature folder's `00_start.md`: parsed, held as edges, and shown. No rules yet beyond
the shape of the value, so that the graph can be looked at before anything starts failing over it.
Depends on [`01_typed_frontmatter.md`](01_typed_frontmatter.md).

## Goals

1. `depends_on: [20_repo_split]` parses into a list of folder names on the folder that declares it.
2. `list` shows prerequisites, and marks a row whose prerequisites are not all `done`.
3. The one folder already carrying the field, `23_dependency_upgrades`, reads correctly.

## Plan

- Parse the inline list form (`[a, b]`) and the empty list. One shape, not three: the block-sequence form
  is another case for no benefit while every real value fits on a line.
- Read it **only from `00_start.md`** (Q6, pending): a phase file's `depends_on` belongs to the older
  convention, names phase paths or doc paths, and is left alone.
- `Folder.depends_on: list[str]`, and a module-level function returning the reverse edges, which phase 03
  needs for the cascade message and which is a one-pass inversion of the same data.
- `list` gains a `needs` column showing the prerequisite numbers, and marks a row that is not startable.
  Two markers, not one: a prerequisite missing from the tree needs a merge, and one present but unfinished
  needs work (`00_start.md`, "Two severities").

## Out of scope

- Every check over the graph (phases 03 and 04). Parsing a field and failing a build over it are separate
  steps, and doing them together means the first failure is also the first time anyone sees the data.
- Any `depends_on` on a phase file, in any direction.

## Done when

- `list` shows `23_dependency_upgrades` needing `20`, marked as not startable, and every other row
  unchanged.
- A `depends_on` on a phase file changes nothing in any output.
- `scripts/check.sh` green, with the checker still reporting nothing on the real tree.
