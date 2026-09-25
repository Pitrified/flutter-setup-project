---
status: planned
---

# Phase 1 - Parser and query command

## Overview

The parser that reads a plan folder, and the command that answers questions with it. Written against
the folders exactly as they are today, before any normalisation, because the only way to know what the
parser has to recognise is to run it over the real thing. Its output is then the to-do list for
phase 2: every hole in the listing is a folder that needs work.
Context: [`00_start.md`](00_start.md).

## Goals

1. One parser, used later by the checker and the rename, so there is never a second one to drift.
2. A command that prints the whole tree sorted by priority, and narrows by status or phase index.
3. Every path an argument, so the same file works from a dotfiles checkout (`00_start.md`, "Portability").

## Plan

- `scripts/plans/parse.py`: a folder becomes a small record (number, name, start file, frontmatter,
  phase files with their statuses, `tracking.md` presence). Frontmatter parsing is hand-rolled over the
  `---` block, the way `scripts/gates/links.py` and klide's `plan_status.py` do it: no PyYAML, because a
  dependency for six keys is not worth it and the box has stdlib only.
- `scripts/plans/query.py`: the command.
  - default: every folder, sorted by `priority` descending then number ascending, one line each with
    number, name, status, priority and the first line of `description`.
  - `--status <s>`: only folders or phases at that status, across the tree.
  - `--index NN` or `--index NN-MM`: what those folders contain, phase files and their statuses.
  - `--root <dir>`: the plans directory. Defaults to `$(git rev-parse --show-toplevel)/plans`, resolved
    by running git rather than by walking up from `__file__`.
  - `--out <file>`: write the same listing as markdown or HTML by extension (Q4), untracked.
- A `.gitignore` line for the generated listing, since it is a message and not a file in the tree.
- Missing data prints as `-` rather than raising. This is the one place tolerance is right: phase 1 runs
  before normalisation by design, and a parser that dies on folder 02 cannot produce the list of what to
  fix. The strictness lives in the checker (phase 3), which runs after.

## Decisions

- **All three scripts live in `scripts/plans/`**, not `scripts/gates/`. They share the parser, and a
  gate under `scripts/gates/` importing from `scripts/plans/` would need `sys.path` fixing to do it.
  `scripts/check.sh` calls `python3 scripts/plans/check.py` in phase 3; the gates directory is where the
  standalone one-file gates live, and nothing in `check.sh` requires a path.
- **No `--json`.** The consumer is an assistant reading a table. A third output format with no caller is
  the generality the simplicity rule rejects; add it when something needs to parse the output.

## Out of scope

- Any edit to any plan file. This phase only reads (phase 2 writes).
- The checker's rules (phase 3) and the cross-branch scan (phase 5).
- Python unit tests. There is no pytest here and adding one needs approval; the verification below is
  the real tree against a hand-built inventory, which is a fixture nobody had to invent.

## Done when

- `python3 scripts/plans/query.py` lists all 22 folders, and its output agrees with the inventory table
  in `00_start.md` under "What the data actually looks like": five folders with start-file frontmatter,
  the rest showing holes.
- `--status "in progress"`, `--index 15`, `--index 09-12` and `--out /tmp/roadmap.md` each work.
- Run once with `--root` pointing at a copy of `plans/` outside the repo, proving no path is derived
  from the script's own location.
- `scripts/check.sh` still green.
