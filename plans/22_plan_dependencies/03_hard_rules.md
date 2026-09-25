---
status: done
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

## What the implementation found

- **Six demonstrations, one break each**, on copies named after the rule they break: an unresolved name
  with the close match (`20_repo_splt` suggests `20_repo_split`), a dependent `in progress` whose
  prerequisite is `draft`, a priority of 2 above a prerequisite's 0, a `discarded` prerequisite reported
  from its own side and naming its dependent, and two cycles.
- **The three-folder cycle was worth testing separately.** The two-folder case passes with almost any
  implementation; the walk here reports the path (`19 -> 23 -> 20 -> 19`) rather than a boolean, and a
  `frozenset` of the path keeps the same cycle from being reported once per folder in it.
- **The cycle message named a folder, not a file**, which breaks the repo's own rule that a gate names the
  file and the line. Fixed to the folder's `00_start.md` before the phase closed.
- **The real tree fires nothing**, which was worth confirming rather than assuming: 23 is `draft` so the
  not-done rule does not apply to it, and its priority equals folder 20's.
- The unresolved-name finding is raised in `cmd_check` rather than inside `check_dependencies`, because
  phase 04 narrows exactly that case to a warning when the name exists on another ref, and keeping it at
  the call site is what makes that a small change.

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
