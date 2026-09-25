---
status: planned
---

# Phase 01 - Uplift tracked-development in dotfiles

## Overview

The dotfiles side of the move, on a dotfiles branch: the managing skill, its reference and the script go into `tracked-development`, and that skill takes on the conventions listed in `00_start.md`.

## Goals

1. `claude/claude__skills__tracked-development.symlink/` holds `scripts/plans.py`, `reference/frontmatter.md` and a reference for the script's workflows.
2. `SKILL.md` covers the three queued items (diary rule, branch convention, the tooling with `depends_on` and `comment`) and the nine items under "What the uplift covers".
3. A repo without the script gets an adoption workflow; a repo with one gets the skew check (Q6 a and b).
4. `plans.py` gains a `VERSION` constant and `--version`, in the skill's copy and, byte-identical, in this repo's.

## Plan

- `scripts/plans.py`: copied from this repo, with `VERSION` and `--version` added. Nothing else in its behaviour changes (out of scope in `00_start.md`).
- `reference/frontmatter.md`: moved as is. Its wording is already repo-neutral.
- `reference/plans-script.md`: the managing skill's workflows (next work, spin-off, collision, finishing), plus adoption and skew.
- `SKILL.md`: the description gains the query triggers; the body gets the frontmatter on `00_start.md`, `NN_<name>.md`, side-documents, the numbering rule, cross-branch linking, cross-file `Qn` references, reopening from another folder, how a plan is written, the diary rule, the branch convention, and session recovery starting from `plans.py list`. Kept under 500 lines by pushing detail into the references.
- This repo: `scripts/plans.py` replaced by the skill's copy, so the two compare equal.

## Out of scope

- Merging the dotfiles branch into `master`. That is the user's call, since it changes every workstation that runs the installer.
- Dotfiles' own `plans/` convention.

## Done when

- The dotfiles branch is pushed, and `cmp` of its `plans.py` against this repo's reports no difference.
- `python3 <skill>/scripts/plans.py --root plans check --citations` passes against this repo's tree, and `--version` prints the version.
- This repo's `scripts/check.sh` passes.
