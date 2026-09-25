---
status: done
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

## What the implementation found

- **Demonstrated on a clone** with `24_someone_elses_work` created on a second branch: `check` warns,
  names the ref, and exits 0 with "23 folder(s) agree with the convention, 1 warning(s)".
- **The in-progress wording fires** and reads as something to act on: "in progress, and needs
  24_someone_elses_work, which is only on feat/24_someone_else. That merge is what this work is waiting
  for."
- **Renaming it to something nobody has** turns it back into a finding with the close-match suffix, which
  is the phase-03 behaviour narrowed rather than replaced.
- **The passing path makes no ref calls**, measured with `strace -e trace=execve` rather than asserted:
  zero `ls-tree` and zero `for-each-ref` on a clean tree, against 13 `for-each-ref` and 117 `ls-tree`
  execs once one name is missing. The only git call on the clean path is the `rev-parse` that finds the
  root.
- Warnings print above findings and are labelled `warning:`, so a reader scanning output does not have to
  infer severity from the exit code.

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
