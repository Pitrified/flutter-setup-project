---
status: in progress
priority: 0
description: |
  The tracked-development uplift: fold the managing-plan-folders skill and its script
  into tracked-development in dotfiles, bring that skill in line with the conventions
  this repo's plan folders grew, and settle what stays here: the vendored script and the gate.
comment: |
  The step that deletes this repo's copy waits for the cloud-session layer that installs
  dotfiles skills (24_cloud_sessions, first phase). A depends_on on the whole folder would
  hold the move back for the Flutter and release work too, so the ordering lives here.
---

# Move the plan-folder skill to dotfiles

Spun off 2026-09-25. Phases in [`tracking.md`](tracking.md).

## Where this came from

The ask: "spin off a folder with the skill move to dotfiles - if not already present - from feature 21. we need to plan what moves, what stays."

It is not already present. Dotfiles `main` at `b23ea22` has six skills under `claude/`, and `managing-plan-folders` is not one of them.

The move was always the plan.
[`../21_plans_query_skill/00_start.md`](../21_plans_query_skill/00_start.md) Q3 built it here first, to be moved once it had been used, and Q14 queued three items for the move.
It is also what makes the skill available in cloud sessions, which load skills from dotfiles rather than from claude.ai (`24_cloud_sessions` Q4, on its own branch).

## Inventory

What exists in this repo today, and where each piece goes.

| Piece | Where it is | Proposed | Why |
| ----- | ----------- | -------- | --- |
| The skill: `SKILL.md`, 95 lines | `.claude/skills/managing-plan-folders/` | moves | The workflows are the same in every repo that uses the convention |
| `reference/frontmatter.md`, 133 lines | same folder | moves | The schema, the status enum and the checker's rules belong to the convention, not to Flutter |
| `scripts/plans.py`, 797 lines | `scripts/` | copied, and stays | Q2: the canonical copy goes into the skill so another repo can adopt it, and this repo keeps a vendored copy so CI runs it with no dotfiles checkout |
| The `plans` gate | `scripts/check.sh` line 57 | stays | Same reason |
| The diary rule | `.github/copilot-instructions.md`, "Plans are a diary, docs are the as-is" | copied, and stays | Copilot reads only that file, not skills. The general rule goes into `tracked-development`; this repo keeps its paragraph |
| `feat/<NN_name>` branches, and merge is not the closing act | `docs/git-workflow.md` | copied, and stays | The skill gets the convention; the repo doc keeps its own git workflow |
| `depends_on` and `comment` | `reference/frontmatter.md` | moves with the reference | Added by `22_plan_dependencies`, already in the file that moves |

## What the move has to reconcile

- **`tracked-development` disagrees with this repo about `00_start.md`.**
  The dotfiles skill says that file "is append-and-refine, not status-tracked".
  Here it carries `status`, `priority`, `description` and optionally `depends_on`, and `plans.py check` fails a start file without them.
  One of the two is changed by the move. The frontmatter reference is the newer and the one a gate enforces.
- **Inside or beside.** 21 Q14 says the skill "belongs inside `tracked-development` rather than beside it, since it is the tooling for that skill's own convention".
  Inside means `tracked-development` gains a reference file and a section on the script; beside means two skills whose descriptions have to say which one triggers when.
- **A repo without `scripts/plans.py`.** Today the skill says to report that rather than write a one-off script, which is a dead end: nothing tells that repo where the script is.
  With the script in the skill (Q2), the skill gains an adoption workflow instead: copy the script into `scripts/`, add the gate to the repo's check, run `check` and fix what it reports.
  Dotfiles itself is such a repo: its `plans/` uses `NN-name` folders and flat `NN-feat-name.md` files, which the checker would reject.
  So does `Pitrified/plans`, unchecked.
- **Two copies of the script.** The skill's copy is canonical and a repo's copy is vendored. 21 Q8 rejected this layout as "version skew nobody will look for", so the move needs the looking done by a mechanism (Q6).
- **The repo copy after the move.** Two copies drift. Deleting this repo's copy is safe on the workstation, which has dotfiles.
  In a cloud session it is safe only once the setup script installs dotfiles skills, which is why the delete waits (frontmatter `comment`).

## What the uplift covers

Q5 makes this folder the "broader uplift of `tracked-development`" that 21 Q14 deferred to.
The three queued items are the diary rule, the branch convention, and the skill itself with `depends_on` and `comment`.
Comparing dotfiles `tracked-development` at `b23ea22` against this repo's plan folders, the managing skill, its reference and the "Planning" section of `.github/copilot-instructions.md` turned up nine more.
Each carries the proposed resolution; none is decided until the phase is written.

1. **`00_start.md` frontmatter.** `tracked-development` says the file is not status-tracked; here it carries `status`, `priority`, `description`, `depends_on`, `comment`. This repo's rule wins (Q3).
2. **Phase file names.** `tracked-development` specifies `NN_feat_name.md`; 21 Q20 settled on `NN_<name>.md`, with `feat` part of the placeholder, and said to amend the skill rather than rename fifty files.
3. **Side-documents.** `NN.M_name.md`, a research note or capture belonging to phase NN with no status, exists in the frontmatter reference and not in `tracked-development`.
4. **Choosing a spin-off's number.** `tracked-development` says "create the next-numbered folder". The managing skill says to list the numbers on every branch and ask, because two branches taking the same free slot is how collisions happen. The managing skill's rule replaces the old one.
5. **Linking a spin-off across branches.** Found while writing this folder. `tracked-development` has the originating folder and the spin-off link to each other.
   With one branch per folder, the spin-off is on a branch the originating folder is not, and a relative link to it fails the link gate.
   Folder 24 names this folder instead of linking it. Proposed rule: link within a branch, name across branches, and add the links when both are on the same branch.
6. **Cross-file question references.** `Qn` and `Dn` are local to the file that raised them, so a reference from elsewhere names the file, as `21_plans_query_skill/00_start.md` Q8. The rule is in the repo instructions, and the skill has no version of it.
7. **Reopening a decision from another folder.** `tracked-development` says an answer is never rewritten, which covers a file's own questions.
   It does not cover a later folder overturning a done folder's answer, which happened today with 21 Q8. What was done: a note under the old answer naming the new file and question, and a line in the done folder's log. The folder stays `done`.
8. **How a plan is written.** The repo's "Planning" section: points written at the strength they have ("for now", "until X"), "never" reserved for fixed constraints, offhand remarks weighted as signals rather than promoted to constraints.
   These are about planning in general, not about this repo.
9. **Recovering a session.** `tracked-development` says to read `tracking.md` first. With the script, `plans.py list` comes before that: it is the roadmap across folders, and there is no roadmap document.

Stays in this repo: that folders up to 09 predate the convention, and the Flutter-specific parts of the instructions.

## Out of scope

- Converting dotfiles' own `plans/` to this convention. A separate decision for that repo.
- Any change to what the script does, beyond the version constant Q6 adds.

## Candidate phases

Not derived yet.

1. In dotfiles: fold the skill, its reference and `plans.py` into `tracked-development` (Q1). Add the diary rule, the branch convention, the adoption workflow for a repo without the script, and the nine items under "What the uplift covers".
2. On the workstation: run the dotfiles installer, check that the skill triggers from `~/.claude/skills/` in this repo with the repo copy renamed out of the way.
3. In this repo: the non-failing comparison against the dotfiles copy in `scripts/check.sh` (Q6), silent when no dotfiles copy exists, as in CI.
4. In this repo, after `24_cloud_sessions` installs dotfiles skills in the cloud: delete `.claude/skills/managing-plan-folders/`, and check `.github/copilot-instructions.md` still names the skill correctly.

## Open questions

- Q1: inside `tracked-development`, or a sibling skill in dotfiles?
  a. inside: `tracked-development` gains `reference/frontmatter.md` and a section on the script.
  b. beside: `managing-plan-folders` as its own skill folder, as it is here.
  Recommended: a, as 21 Q14 decided. The convention and its tooling then change in one place, and there is one skill description to trigger on.
  ANS: a.
- Q2: does `scripts/plans.py` stay only in this repo?
  21 Q8 answered b, canonical copy in the repo, before any other repo used the convention. Cloud sessions make a second repo more likely, not yet real.
  a. stays here only; another repo that wants the gate copies it deliberately.
  b. a canonical copy in dotfiles as well, run from the skill against any repo's `plans/`, with the gate still vendored per repo.
  Recommended: a, until a second repo actually adopts the convention. b is the version skew 21 Q8 rejected.
  ANS: b, reopening 21 Q8 on new evidence. A separate repo that wants the skill has no way to find the script if it lives only here.
  So the script goes in the skill for other repos to copy, and a copy stays here so CI passes without fetching dotfiles.
  The duplication is accepted; the skew it causes is Q6.
- Q3: which `00_start.md` rule wins, `tracked-development`'s "not status-tracked" or this repo's frontmatter?
  Recommended: this repo's. It is what the checker enforces, and `list` needs `status`, `priority` and `description` on the start file to show a folder at all.
  ANS: this repo's.
- Q4: the repo copy of the skill after the move?
  a. delete it, once cloud sessions install dotfiles skills.
  b. keep it, as a second copy.
  c. replace it with a stub that points at dotfiles.
  Recommended: a. b drifts, and c is a skill that triggers and then says to go elsewhere.
  ANS: a.
- Q5: 21 Q14 said the queued items wait for "a broader uplift of `tracked-development`". Is this folder that uplift, or only the move?
  Recommended: only the move and the three queued items. Anything else found while in that file gets its own note.
  ANS: this is the uplift. The findings beyond the three queued items are listed under "What the uplift covers".

### Second batch (2026-09-25)

- Q6: how is skew between the skill's `plans.py` and a repo's copy caught?
  CI cannot compare them, since it has no dotfiles checkout.
  a. a `VERSION` constant in the script, printed by `plans.py --version`; the skill's workflow compares the repo's version with its own and says when they differ.
  b. the same, plus a byte comparison: the skill runs `cmp` on the two files, so an edit made in the repo copy without a version bump is caught too.
  c. a non-failing line in `scripts/check.sh` that compares against `~/.claude/skills/.../plans.py` when that file exists, and prints a warning. Silent in CI.
  Recommended: b and c together. b is what an assistant using the skill sees, and c is what a person running the gates sees, with no network and no failure in CI.
  Edits go to the skill's copy first and are copied into the repo in the same change.
  ANS: a, b and c, without the last line. An edit cannot be assumed to reach every repo in the same change: changing the skill and this repo together still leaves every other user of the skill drifting, and nobody can track them all.
  So each repo checks itself. Its local checker, not CI, prints the mismatch when a dotfiles copy is available, and the differences are reconciled from dotfiles into that repo.
  Dotfiles is the direction of flow; a repo does not push its copy back.
