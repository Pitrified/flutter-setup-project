---
status: planned
---

# Phase 03 - The skew line in the local gate

## Overview

Q6 c: when a dotfiles copy of `plans.py` is installed, `scripts/check.sh` says whether this repo's copy differs from it. It never fails the run, and it prints nothing extra where no dotfiles copy exists, which is CI and cloud sessions today.

## Plan

- A step in `scripts/check.sh` after the gates, outside `run`, so it cannot fail the result: compare `scripts/plans.py` with `$HOME/.claude/skills/tracked-development/scripts/plans.py` using `cmp -s`.
  On a difference, print both `--version` outputs and the reconcile direction: copy from dotfiles into this repo.
- The rule itself goes in the doc whose topic it is (`docs/` has no plan-tooling doc; the gate list in the repo instructions is where `check.sh` is described).

## Done when

- Seen silent with no dotfiles copy, seen reporting with a copy that differs, and seen silent with a copy that matches.
- `scripts/check.sh` still exits 0 in all three.
