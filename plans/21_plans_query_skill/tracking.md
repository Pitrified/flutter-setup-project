# Jira-lite for the plan folders - implementation tracking

A parser for the `tracked-development` frontmatter, a query command that answers "what is in progress"
and "what is next by priority", and a checker that holds the plan folders to their own convention. The
folders are normalised to fit it rather than the parser being made tolerant of them. Analysis, the
twenty answered questions and the per-folder normalisation table are in [`00_start.md`](00_start.md).

## Key decisions

Full reasoning in `00_start.md`; these are the ones that cut across phases.

- **No tolerant parser** (Q1). The old folders get their content and names normalised in one pass, so
  after phase 2 a file without frontmatter is a bug rather than a variation.
- **Scripts live in this repo** (Q8), because the checker is a gate and the hook and CI have to run it.
  The skill is prose plus the argument contract, and moves to dotfiles later (Q3).
- **Every path is an argument** with a documented default, since this ends up in dotfiles where no
  relative path to a repo is meaningful. No environment variables, no config file.
- **Query and check are read-only** (Q4 keeps the roadmap a command, not a tracked file). The rename in
  phase 5 is the only writer, it takes the target number from a person, and it is a separate script.
- **Plans are a diary, docs are the as-is.** Nothing outside `plans/` names a specific plan folder or a
  `Qn`/`Dn` id; a decision worth citing lives in the docs file whose topic it is (Q12, Q15, Q16). The
  rule is in `.github/copilot-instructions.md` until it moves to `tracked-development` (Q14).
- **`priority` on `00_start.md` only** (Q2), born at 0, bumped by one, back to 0 when done.
- **`NN_<name>.md`** (Q20): the `feat` segment is part of the placeholder, not a required word.

## Phases

| #  | Phase                              | Plan                                                          | Status  |
| -- | ---------------------------------- | ------------------------------------------------------------- | ------- |
| 1  | Parser and query command           | [`01_parser_and_queries.md`](01_parser_and_queries.md)         | done    |
| 2  | Normalise every folder             | [`02_normalisation.md`](02_normalisation.md)                   | planned |
| 3  | The checker, and the gate          | [`03_checker_and_gate.md`](03_checker_and_gate.md)             | planned |
| 4  | The repo stops citing the diary    | [`04_stop_citing_the_diary.md`](04_stop_citing_the_diary.md)   | planned |
| 5  | Folder-creation workflow and skill | [`05_workflow_and_skill.md`](05_workflow_and_skill.md)         | planned |

Status values: draft / planned / in progress / done / superseded / discarded.

## Log

Append-only. Newest at the bottom.

- 2026-09-25 : folder spun off as a draft while raising the wider roadmap; the ask was a skill parsing
  the `tracked-development` frontmatter with queries over status, phase index and a new priority field.
- 2026-09-25 : brainstormed to a close on branch `feat/plans-jira-lite`. Twenty questions raised and
  answered. Gained a plans-checker script, a `description` frontmatter field, cross-branch folder
  numbering with a scripted rename, and the rule that nothing outside `plans/` cites a plan. Two
  conventions written into this repo's docs pending a move to the skill: the diary rule
  (`.github/copilot-instructions.md`) and `feat/<NN_feat_name>` branch naming (`docs/git-workflow.md`).
- 2026-09-25 : measured rather than assumed twice, and both measurements corrected the plan. The
  cross-branch scan over five local refs found no collision. The citation grep found 28 references in
  13 files, after two hand-counts had said fifteen and thirteen; it also caught a false positive on a
  template path, which is why the pattern skips paths containing `<`.
- 2026-09-25 : reviewed the plan before writing the phases (the skill's five questions). Findings
  became Q19 and Q20, both about how large normalisation is: eight folders have no `00_start.md`, and
  the `feat` segment would have cost about fifty renames for a word no parser reads. Both answered
  before the phases were written, which is why phase 2 is a table rather than a guess.
- 2026-09-25 : phases derived, `tracking.md` and the five sub-plans written. Nothing executed yet.
- 2026-09-25 : phase 1 - `scripts/plans.py` with a `list` subcommand. Revised the layout decision first:
  one small file with subcommands, not a `scripts/plans/` package, and no test framework. Verified
  against the hand-built inventory, with `--index`, `--status`, `--out` in both formats, `--root`
  pointing at a copy outside the repo, and a named error when run outside a git repo with no `--root`.
  The listing covers eleven folders and names the twelve it skips, which is phase 2's work list.
