---
status: planned
---

# Phase 04 - The soft rule, across branches

## Overview

A prerequisite may live on a branch that has not merged, because someone else may be implementing it and
merging their plans in so that a reference resolves is overkill. That makes it the checker's first
warning: printed, not fatal.
Context: [`00_start.md`](00_start.md), Q4 and "Two severities". Depends on
[`03_hard_rules.md`](03_hard_rules.md), whose "resolves nowhere" finding this phase narrows.

## Goals

1. A prerequisite on another branch reports as a warning and does not fail the gate.
2. The warning says which refs it was found on, so the next action needs no search.
3. `check` reads refs only when a name fails to resolve in the tree.

## Plan

- Severity in the checker: findings set exit 1, warnings print and do not. The output distinguishes them
  in words, since a reader scanning a gate's output should not have to count exit codes.
- On a name that is not a folder in the tree, consult the refs with the machinery `branches` already has
  (`git for-each-ref` plus `git ls-tree -d`). Found on a ref: warning, naming the refs. Found nowhere:
  the finding from phase 03, with the close match.
- **Only on the miss.** A tree where every prerequisite resolves makes no extra git calls, which is what
  keeps this compatible with folder 21's Q10 decision to keep ref-reading out of every run.
- Stronger wording when the dependent folder is itself `in progress`: the merge is then what the current
  work is waiting on rather than housekeeping, and the line should read as something to act on. Still a
  warning, because the person who has to act may not be the one running the gate.

## Out of scope

- Failing on a prerequisite that is only on another branch. That was the recommendation and it was
  overridden, for a good reason recorded in Q4.
- Any new git call on the passing path.

## Done when

- Demonstrated on a clone with a prerequisite created on a second branch: `check` warns, names the ref,
  and exits 0, and `scripts/check.sh` stays green.
- The same prerequisite renamed to something that exists nowhere: `check` fails with the close match.
- With the dependent set to `in progress`, the warning's wording changes and the exit code does not.
- Instrumented once to confirm the passing path makes no `git ls-tree` call.
