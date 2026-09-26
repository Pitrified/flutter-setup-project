# tracked-development uplift - implementation tracking

The `managing-plan-folders` skill, its frontmatter reference and `plans.py` move into `tracked-development` in dotfiles, which is brought in line with the conventions this repo's plan folders grew.
This repo keeps a vendored copy of the script for CI, and its local gate reports when that copy differs from the dotfiles one.
Analysis, the inventory and the six answered questions are in [`00_start.md`](00_start.md).

## Key decisions

- **Inside `tracked-development`** (Q1). One skill, one description to trigger on; the script and the reference live in its folder.
- **The script's canonical copy is in the skill** (Q2), reopening `21_plans_query_skill/00_start.md` Q8. Each repo vendors a copy.
- **Skew is each repo's to catch** (Q6). A `VERSION` constant, a byte comparison by the skill, and a non-failing line in the local gate. Reconciliation flows from dotfiles into the repo, never back.
- **This repo's `00_start.md` frontmatter wins** (Q3) over `tracked-development`'s "not status-tracked".
- **The repo copy of the skill is deleted** (Q4), after cloud sessions install dotfiles skills.
- **This folder is the uplift** (Q5): the three queued items plus the nine under "What the uplift covers".

## Phases

| #  | Phase                                  | Plan                                                         | Status  |
| -- | -------------------------------------- | ------------------------------------------------------------ | ------- |
| 01 | Uplift `tracked-development` in dotfiles | [`01_uplift_in_dotfiles.md`](01_uplift_in_dotfiles.md)     | done    |
| 02 | Check it on the workstation            | [`02_workstation_check.md`](02_workstation_check.md)         | in progress |
| 03 | The skew line in the local gate        | [`03_skew_gate.md`](03_skew_gate.md)                         | done    |
| 04 | Delete this repo's copy of the skill   | [`04_delete_repo_copy.md`](04_delete_repo_copy.md)           | in progress |

Status values: draft / planned / in progress / done / superseded / discarded.

## Log

Append-only. Newest at the bottom.

- 2026-09-25 : spun off as a draft from a cloud session while planning `24_cloud_sessions`; six questions raised and answered the same day, 21 Q8 flipped.
- 2026-09-25 : phases derived. Dotfiles attached to the session with push access and cloned; its default branch is `master`, and larger work there goes on `feat/` branches.
- 2026-09-25 : phase 1 - `tracked-development` in dotfiles took the script (`VERSION` 1.0.0), the frontmatter reference, a new `reference/plans-script.md`, and the twelve conventions. Pushed on dotfiles `feat/tracked_development_uplift`, not merged. This repo's `scripts/plans.py` got the same `VERSION` edit and compares equal to the skill's copy.
- 2026-09-25 : phase 3 - the non-failing skew note in `scripts/check.sh`, seen absent, differing and matching, and described in the repo instructions' "Gates" section.
- 2026-09-25 : phase 2 needs the workstation and phase 4 waits on it and on `24_cloud_sessions` phase 1; both stay `planned`.
- 2026-09-26 : phase 4's deletion pulled ahead of phase 2, on the user's call: `.claude/skills/managing-plan-folders/` removed on this branch so the workstation test sees exactly the future state, with only the dotfiles skill present. No other file outside `plans/` named the skill. Phase 4 stays `in progress` until a cloud session installs dotfiles skills (`24_cloud_sessions` phase 1); until then a cloud session on this branch has no plan-folder skill.
