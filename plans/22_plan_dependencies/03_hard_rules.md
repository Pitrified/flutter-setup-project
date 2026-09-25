---
status: planned
---

# Phase 03 - The hard rules, and the cascade

## Overview

The four checks that fail the gate, including the one this folder exists for: a priority that drifted
above its own prerequisite. All of them read the edges parsed in
[`02_depends_on_field.md`](02_depends_on_field.md); none of them reads a git ref, which is phase 04.
Context: [`00_start.md`](00_start.md), "What it is for" and "Discarding cascades".

## Goals

1. A plan that cannot be started is not presented as the next thing to do.
2. Discarding a feature cannot be done without seeing what it breaks.
3. Every rule names the file, and is demonstrated failing before it counts.

## Plan

Four findings, exit 1:

- **A name that resolves nowhere.** Not a folder in the tree, and not on any ref (phase 04 supplies the
  second half; until then, not in the tree). The message carries
  `difflib.get_close_matches` output, so `20_repo_splt` suggests `20_repo_split`.
- **A cycle.** Necessary because numbers no longer rule it out: `20` may depend on `21`, and the pair
  depending on each other is what nothing else will catch. Report the cycle as the path found, not as a
  boolean.
- **A prerequisite that is not `done`, on a dependent that is `in progress` or `done`.** A folder cannot
  be finished before something it needs is.
- **A priority above a prerequisite's.** The drift this folder was created for: a folder at `priority: 2`
  whose prerequisite sits at `0` sorts to the top of `list` and cannot be started. Failing, per Q3, and
  left failing until it proves annoying.

Plus the cascade, which is the same rule read the other way:

- **A `discarded` or `superseded` folder that something still depends on**, reported from the discarded
  folder's side and naming every dependent:
  `20_repo_split/00_start.md: discarded, and 23_dependency_upgrades depends on it`.
- No automatic repointing and no `superseded_by` key (Q5). The message says what is broken; a person
  decides whether the dependent repoints, depends on nothing, or is discarded too, and the checker fails
  again for whatever depended on *that* until the tree is consistent.

## Out of scope

- Anything involving refs or warnings (phase 04). Every rule here fails.
- Suggesting the replacement for a superseded folder.

## Done when

- Each of the five rules demonstrated failing on a copy of `plans/` outside the repo, one break at a
  time, in the shape folder 21 phase 3 used: that is what makes them gates rather than assumptions.
- The cycle case covered both ways: a two-folder cycle and a three-folder one, since a naive check catches
  the first and misses the second.
- `scripts/check.sh` green on the real tree. Folder 23 depends on folder 20, both `draft` at priority 0,
  so no rule here fires on it, which is worth confirming rather than assuming.
