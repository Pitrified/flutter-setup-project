---
status: done
---

# Phase 3 - The checker, and the gate

## Overview

The mechanical-correctness checks, in the shape the other gates here use: name the file and the line,
be fast, and fail on facts a script can be sure about. It can only run after
[`02_normalisation.md`](02_normalisation.md), because before that it would fail on day one for reasons
that are nobody's mistake. The rules are listed in [`00_start.md`](00_start.md) under "What the checker
checks"; the noise question that decides whether the citation rule ships is answered under "Can this be
scripted without noise".

## Goals

1. `python3 scripts/plans.py check` reports every mechanical fault in `plans/`, or nothing.
2. It runs in `scripts/check.sh`, which `.githooks/pre-commit` already execs, so a bad plan file is
   caught before the push rather than in a CI log (Q6).
3. The citation rule is written and measured here, and armed in phase 4.

## Plan

- Frontmatter exists, parses, and carries `status`, `priority` and, on `00_start.md`, `description`.
- `status` in the enum; `priority` a non-negative integer, and 0 on a folder whose phases are all done.
- Every phase file appears in its `tracking.md` table with a matching status, and every table row names
  a file that exists. This is klide's `scripts/gates/plan_status.py`, reimplemented on the shared parser
  rather than copied, since it computes its root from `__file__` in a way that does not survive the move
  to dotfiles.
- File naming: `00_start.md`, `tracking.md`, `NN_<name>.md`, numbers unique within a folder. Decimal
  side-documents and folders with no start file are recognised, not reported (Q9).
- No `NEW_ANS:` in a folder whose phases are all `done`.
- **The citation rule**, `--citations`: any `plans/NN_something` outside `plans/`, skipping paths that
  contain `<`. Written here, run here, and left out of `check.sh` until phase 4 empties it.
- Wire the structural checks into `scripts/check.sh` as one line, after they pass.
- Relative links stay with `scripts/gates/links.py`. Two gates checking links is one gate too many.

## Out of scope

- Editing anything. No `--fix`: a gate that can edit the files it judges is the anti-pattern this is
  meant to prevent, and a priority bump stays a hand-written one-line diff.
- The cross-branch scan, which is phase 5 and stays behind a flag (Q10).

## Done when

- Run over the normalised tree, it reports nothing, and `scripts/check.sh` includes it and is green.
- Demonstrated failing, once per rule, by breaking a copy of `plans/` outside the repo: a status that
  disagrees with its table, a missing `description`, a `done` folder at `priority: 2`, a duplicate
  number. A rule nobody has seen fail is an assumption, not a gate.
- `--citations` reports exactly the measured set and nothing else: 28 references in 13 files, being
  fourteen citations, twelve README rows and the two `plans/00_tracking.md` pointers (the last two gone
  by then, so 26 in 12 if phase 2 has landed). If it cannot hit the set with no false positive, it does
  not ship as a gate and the rule stays prose in the skill.

## What the implementation found

- **Renamed the flag to `--citations`.** `--no-citations` reads as switching the check off.
- **The checker found three real faults on the first run**, all invisible to a reader: `10_streaming_ui`
  had a table status of `planned (deferred)`, which is not in the enum and is what a status column looks
  like when someone needs two facts in one cell; and two phase files, `10/07_audit.md` and
  `12/99_fix_merge.md`, existed with a status and appeared in no table. Fixed, and the deferral is now in
  the phase name where it belongs.
- **One rule was too lax.** A table row naming a side-document skipped status validation, which is how
  `planned (deferred)` survived the first pass. Every row's status is validated now, whatever it names.
- **A malformed frontmatter aborted the run and hid every other finding.** It is a finding now, per file,
  because a broken file must not mask the rest of the tree. That was found by testing the rule rather
  than by reading the code.
- **Thirteen rules, each demonstrated failing** on two copies of `plans/` outside the repo: status not in
  the enum, a negative priority, a done folder not back at 0, a missing description, a phase file with no
  frontmatter, a table that disagrees with a file, a table row naming a file that does not exist, a phase
  file missing from its table, a file name that is not a plan file name, `NEW_ANS:` in a finished folder,
  a duplicate phase number, frontmatter that never closes, and a citation from outside `plans/`.
- **`--citations` reports 33 in 14 files**, up from the 28 measured during planning: the renames turned
  README rows into `plans/NN_*/00_start.md` links, and three of the new ones are mine from today, in
  `scripts/plans.py`, `scripts/check.sh` and `docs/git-workflow.md`. A rule that catches its author the
  day it is written is the right kind of rule.
