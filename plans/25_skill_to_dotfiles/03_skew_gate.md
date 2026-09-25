---
status: done
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

## What the implementation found

- The line sits after the gates and outside `run`, so it adds no gate and cannot change the exit code.
- Seen in all three cases on 2026-09-25 by linking `~/.claude/skills/tracked-development` by hand: absent, silent; a copy with `VERSION` bumped to 1.0.1, one note naming both versions and the file to copy from; the dotfiles branch's copy, silent. `all gates passed` and exit 0 each time.
- The rule went into the "Gates" section of `.github/copilot-instructions.md`, since `docs/` has no plan-tooling doc and that section is where `check.sh` is described.
