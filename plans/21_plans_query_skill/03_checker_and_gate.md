---
status: planned
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

1. `python3 scripts/plans/check.py` reports every mechanical fault in `plans/`, or nothing.
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
- **The citation rule**, `--no-citations`: any `plans/NN_something` outside `plans/`, skipping paths that
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
- `--no-citations` reports exactly the measured set and nothing else: 28 references in 13 files, being
  fourteen citations, twelve README rows and the two `plans/00_tracking.md` pointers (the last two gone
  by then, so 26 in 12 if phase 2 has landed). If it cannot hit the set with no false positive, it does
  not ship as a gate and the rule stays prose in the skill.
