---
status: done
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

- `scripts/plans.py`: one file, subcommands. A folder becomes a small record (number, name, start file,
  frontmatter, phase files with their statuses, `tracking.md` presence). Frontmatter parsing is
  hand-rolled over the `---` block, the way `scripts/gates/links.py` and klide's `plan_status.py` do it:
  no PyYAML, because a dependency for six keys is not worth it and the box has stdlib only.
- `python3 scripts/plans.py list`: the query, and the default subcommand.
  - default: every folder, sorted by `priority` descending then number ascending, one line each with
    number, name, status, priority and the first line of `description`.
  - `--status <s>`: only folders or phases at that status, across the tree.
  - `--index NN` or `--index NN-MM`: what those folders contain, phase files and their statuses.
  - `--root <dir>`: the plans directory. Defaults to `$(git rev-parse --show-toplevel)/plans`, resolved
    by running git rather than by walking up from `__file__`.
  - `--out <file>`: write the same listing as markdown or HTML by extension (Q4), untracked.
- Missing data prints as `-` rather than raising. This is the one place tolerance is right: phase 1 runs
  before normalisation by design, and a parser that dies on folder 02 cannot produce the list of what to
  fix. The strictness lives in the checker (phase 3), which runs after.

## Decisions

- **One file, `scripts/plans.py`, with subcommands** (`list`, then `check` in phase 3, `branches` and
  `rename` in phase 5). Revised from the earlier plan of a `scripts/plans/` package: these scripts stay
  small and a package is the shape they should not grow into. Subcommands share the parser by being in
  the same file, with no `sys.path` work and nothing to import. `scripts/check.sh` calls
  `python3 scripts/plans.py check`, and nothing in `check.sh` requires a particular directory.
- **No `--json`.** The consumer is an assistant reading a table. A third output format with no caller is
  the generality the simplicity rule rejects; add it when something needs to parse the output.

## Out of scope

- Any edit to any plan file. This phase only reads (phase 2 writes).
- The checker's rules (phase 3) and the cross-branch scan (phase 5).
- Python unit tests. These scripts are small enough that the verification below is the real tree against
  a hand-built inventory, which is a fixture nobody had to invent, and the checker's own rules get
  demonstrated failing in phase 3. If a script ever grows past that, it is too big.

## Done when

- `python3 scripts/plans.py list` agrees with the inventory table in `00_start.md` under "What the data
  actually looks like": five folders with start-file frontmatter, the rest showing holes.
- `--status "in progress"`, `--index 15`, `--index 09-12` and `--out` each work.
- Run once with `--root` pointing at a copy of `plans/` outside the repo, proving no path is derived
  from the script's own location.
- `scripts/check.sh` still green.

## What the implementation found

- **The listing is eleven folders, not twenty-two.** Only eleven have a `00_start.md`, and the rest are
  skipped by the rule Q19 identified. A skipped folder was silently absent, which makes a poor work
  list, so `list` ends with `no 00_start.md, so not listed: ...` naming all twelve. That line *is* phase
  2's job description, and it disappears as phase 2 lands.
- **No gitignore line was added.** `--out` takes a path, which is normally a temp directory, so an
  ignore rule would be for a filename nobody has to use. Dropped rather than guessed at.
- The `phases` column (`4/5`, `3/4`) was not planned and is the most useful thing in the output: it
  reads as progress without opening `tracking.md`.
- `12_abi_split/99_fix_merge.md` parses as phase 99 with no status. It is a real file from a merge fix,
  so it is a phase file with missing frontmatter rather than a naming fault: phase 2 gives it a status.
