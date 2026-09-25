---
status: draft
priority: 0
description: |
  Jira-lite for the plan folders: a skill that parses the frontmatter and answers
  queries by status, priority and phase index, plus a plans-checker script the
  assistant runs for mechanical correctness. Includes a one-pass normalisation of
  the older folders, so there is nothing to be tolerant of, and cross-branch folder
  numbering with a scripted rename for the collision, and a check that no code or
  doc cites a plan file, because plans are a diary and docs are the as-is. Written
  here, built to move to dotfiles: every path is an argument.
---

# Jira-lite: querying and checking the plan folders

Status: draft spin-off, raised 2026-09-25. No phases derived. Born here, expected to end up in
dotfiles alongside `tracked-development`.

## Where this came from

The ask: a spin-off skill "which parses our tracked development frontmatter and has some basic
queries enabled on state enum, index range `NN_feat`, and a new priority field. All priorities are
born at 0, if a feature is more important we just bump it up by one so we can sort them easily with a
one line of diff in the `00_start`. When done it's bumped back to 0 as the state goes to done."

## Two pieces, one feature

1. **The query skill** (jira-lite): what is in progress, what is next by priority, what a phase range
   contains.
2. **The plans-checker script**: mechanical correctness of the plan files themselves, run by the
   assistant rather than re-derived from memory every time. Checking and querying read the same files
   with the same parser, so they ship together.

## The priority convention, as given

- Every plan is born `priority: 0`.
- More important means bump by one. Sorting is descending by priority.
- Done means back to `0`, so a finished feature never sits at the top of the list.
- The point is the diff: raising a priority is one line in `00_start.md`, reviewable and revertible,
  rather than a reshuffle of some index file.

First uses, applied when this was raised:
[`../16_cloud_first_engine/00_start.md`](../16_cloud_first_engine/00_start.md) at `priority: 1`, the
other new drafts at `0`.

## The description field

Frontmatter also gains a `description`, a multiline block of a few lines saying what the thing is and
why, readable cold by someone who has not opened the folder:

```yaml
---
status: draft
priority: 0
description: |
  Jira-lite for the plan folders: queries over status, priority and phase index,
  plus a checker for mechanical correctness.
---
```

Required on a folder's `00_start.md`. Optional on phase files, where the `## Overview` already says
it. It exists so a listing can show one line per feature without opening anything, which is what makes
the query output readable at all.

## What the data actually looks like (re-checked 2026-09-25)

A folder-by-folder pass over `plans/`, which found more variation than the first look reported.
Corrected here rather than left standing, because the normalisation pass is sized from this list.

- **Frontmatter on `00_start.md` exists in five folders only**: 14, 16, 18, 19, 20, 21. It is absent
  from 01, 12, 13, 15 and 17, including the two most recently completed features. So the convention
  the newer folders were written to is the `status:` line on *phase* files, not on the start file.
- **`00_start.md` itself is not universal.** Folders 02-09 and 99 have no start file; they use a
  `README.md` plus numbered files. Folder 10 has `00.1_initial_research.md` and
  `00.2_structured_streaming_asis.md` and no start file. Folder 11 calls it `00_intro.md`.
- **`tracking.md` exists in 10, 12, 15, 17.** Folder 11 calls it `00_tracking.md`. Everything else
  has none, which is correct for a draft and wrong for 09, which is live work.
- **Phase file naming is `NN_feat_*.md` in 10, 15 and 17 only.** Folder 12 uses bare
  `NN_name.md` plus a `99_fix_merge.md`; 09 uses `NN_name.md` with a gap at 08; 02-08 use
  `NN_name.md` throughout.
- **Decimal numbering is in use**: `00.1_`, `00.2_`, `01.1_`, `04.1_` in folder 10, `00.1_` in 01
  and 02, `03.1_`/`03.2_` in 08. These are side-documents deliberately sorted next to their parent,
  and a checker that only knows `NN_` will report every one of them.
- **Three folders are not features at all**: `00_drafts`, `01_plan_polishing` and `99_notes`. Whatever
  the checker does about pre-convention folders, these are a separate case: they have no status
  because they are not work with a status.
- `plans/00_tracking.md` sits at the top level and covers phases 00-09, which is a fourth shape.

So the normalisation is bigger than "add a priority field": it is a rename of `00_intro.md` and
`00_tracking.md`, a `00_start.md` and `tracking.md` for folders that have neither, frontmatter on
eleven start files, and a decision on the decimal files and the three non-feature folders. Doing it in
one pass is what lets the parser be strict: after it, a file without frontmatter is a bug rather than
a variation.

## Queries worth having

- By status: what is `in progress` right now, across every folder.
- By priority: the sorted list, which is the closest thing this project has to a roadmap. Note there
  is no roadmap document today, and this output is meant to be it rather than a second file to keep in
  sync by hand.
- By index range: `NN` and `NN_feat_*`, so "what is phase 15 made of" is one command.
- Health: files with no frontmatter, statuses that are not in the enum, and phase files missing from
  their `tracking.md` table (the check klide implements as `scripts/gates/plan_status.py`, which this
  repo does not have).

## What the checker checks

Mechanical things only: facts a script can be sure about, each naming the file and line, in the shape
the existing gates use.

- Frontmatter exists, parses, and carries `status`, `priority` and (on `00_start.md`) `description`.
- `status` is in the enum: draft / planned / in progress / done / superseded / discarded.
- `priority` is a non-negative integer, and a `done` folder is back at 0 (the convention's own rule,
  which is exactly the kind of thing nobody remembers).
- Every phase file appears in its `tracking.md` table, and the table's status matches the file's
  frontmatter. This is klide's `scripts/gates/plan_status.py`, which this repo never adopted.
- File naming: `00_start.md`, `tracking.md`, `NN_feat_*.md`, numbers unique within a folder.
- No `NEW_ANS:` left in a folder whose phases are all done, since an unanswered question in finished
  work is either forgotten or finished.

- Folder numbers are unique **across branches**, not just in the working tree. See below.

Relative links are already covered by `scripts/gates/links.py` and are not re-checked here.

## Plans are a diary, not documentation

Given as a rule while this was being written, and it is the rule the repo is furthest from:

> Plans are a diary of development, not docs. If a script, doc or comment needs to point to a
> decision, that decision should live in a docs file. Docs are the latest snapshot of the as-is of the
> project.

`flutter-setup-project` predates the rule and breaks it twenty times. The distinction that makes the
count meaningful, because the two cases want opposite treatment:

- **Citations of a specific decision, which have to go.** Thirteen of them, and they read the same way
  everywhere: a `Qn`/`Dn` id from a plan file, quoted from code that the reader cannot then check
  without opening a diary entry. `lib/models/target_language.dart:12`,
  `lib/services/inference/openai_inference_engine.dart:24`,
  `lib/services/conversation/conversation_controller.dart:41` and `:240`, `tool/mock_openai.py:15`,
  `scripts/e2e.sh:9`, `integration_test/app_test.dart:94` and `:160`,
  `test/services/conversation_controller_test.dart`, `docs/prompt-engineering.md:161`, and
  `docs/build-and-release.md` three times.
- **Pointers to the plans tree as a place work is tracked, which are fine.** Seven, all in the
  "how we work" files: `.github/copilot-instructions.md` twice, `docs/ai-development-playbook.md` four
  times (naming `plans/<phase>/` as a template location), `docs/README.md` once. These cite no
  decision; they say where the diary is kept, which is exactly what an instruction file is for.

The rule the checker can enforce is therefore narrower than "no `plans/` outside `plans/`": a path to
the tree or a folder is allowed, a reference to a *file* inside it, or to a `Qn`/`Dn`/`TLn` id, is not.
A rule stated as the broad version would fail `copilot-instructions.md` for documenting the
convention, and a gate that fires on its own instructions gets deleted rather than obeyed.

This lands on the feature in four places:

1. **A new check.** A grep, not a parse: it needs the repo root as well as the plans directory, so the
   script takes both, the root defaulting to the plans directory's parent.
2. **The rename script shrinks.** The repo-wide sweep described below was justified by those thirteen
   citations. Once they are gone, a rename only has to fix links inside `plans/`, and the outside world
   has nothing to fix because it was never allowed to point there. The sweep survives as an assertion,
   not a rewrite.
3. **Migration work that is not this feature's.** Removing the thirteen means finding each decision a
   home in the topical doc that owns the subject, which is a docs change with product judgement in it,
   not a mechanical pass. Scope question below.
4. **The convention belongs in the skill.** `tracked-development` in dotfiles does not say this today;
   it is where the rule should live, next to where this skill will.

## Numbering across branches

Folder numbers are allocated by whoever spins a folder off, and a branch that has not merged yet is
invisible to anyone counting folders in the working tree. Two people each taking "22" is not a
hypothetical; it is what the counting rule produces the first time two branches are open at once.

So the checker scans refs, not only the checked-out tree. Read-only and cheap, with no checkout:

```bash
git for-each-ref --format='%(refname)' refs/heads refs/remotes
git ls-tree -d --name-only <ref> plans/
```

Each number maps to a set of (ref, folder name). A number with more than one distinct folder name
behind it is a collision; the same folder name on five refs is just a branch that has not merged.

Run by hand over this repo's five local refs (2026-09-25): no collision. Every number maps to exactly
one name, and the three stale branches (`feat/abi-split`, `backup/g4-abi-split`,
`feat/language-setting-and-e2e`) hold strict prefixes of main's list rather than folders of their own.
That is the expected shape most of the time, and it is why this check belongs at folder-creation time
rather than in every run: it will say "nothing" for months and then save a merge.

When a collision is found, the fix is mechanical and gets a script, because doing it by hand is where
the dangling reference comes from. A rename is more than `git mv`: sibling folders point at each other
by `../NN_name/`, and those break. Outside `plans/` nothing should point at a plan file at all (see
above), so the script asserts that instead of rewriting it: if the grep finds a citation, the rename
stops and says which file to fix first, rather than quietly editing code to keep a diary reference
alive.

What it does **not** do is choose the new number. In a single-developer repo picking `max + 1` is
obvious enough to automate, but two developers renaming into the same free slot on their own branches
reproduces the collision one number along. So the script takes the target number as an argument and
the skill prompts a person for it, saying which numbers are taken and on which refs. A tool that
silently renumbers someone else's branch is worse than the collision it fixes.

## Portability: born here, lives in dotfiles

This is written against real folders in this repo and is expected to move to
`~/dotfiles/claude/claude__skills__*` next to `tracked-development`, which is the convention it reads.
That destination constrains the design now, not later:

- **No relative path from the skill to a repo.** klide's `scripts/gates/plan_status.py` computes its
  root as `Path(__file__).resolve().parents[2]`, which is correct for a script that lives in the repo
  it checks and wrong for one that lives in dotfiles. The script takes the plans directory as an
  argument instead, and defaults to `$(git rev-parse --show-toplevel)/plans` when the argument is
  absent, so it is usable in either position.
- **The skill knows its own directory.** Claude Code injects a `Base directory for this skill:` line
  ahead of the body, so `<skill dir>/scripts/plans_check.py` is a resolvable absolute path at call
  time, with no `$HOME` guess and no symlink chasing. That is what makes "given a script and some
  args, run it" work.
- **Arguments over conventions.** Every path the script needs is an argument with a documented
  default. No environment variables, no config file, nothing read from the repo it is pointed at.
- **The caller is a competent assistant, not a menu.** The skill documents the script's arguments and
  its output shape, and lets the assistant compose the call. Per the skill-authoring guidance, that is
  the low-freedom part (a specific script, exact flags) while deciding *which* query answers the
  question at hand is the high-freedom part, and the two get written differently.

Structure, following the published layout: a `SKILL.md` under 500 lines carrying the query and check
workflows, and `scripts/` beside it holding the executable. Reference material (the frontmatter
schema, the status enum) goes in one file one level deep rather than inline, so the body stays short.
The `description` field is what decides whether the skill is ever loaded, so it names the triggers:
plan folders, phase status, what to work on next, priority.

## Shape

A skill plus two scripts. Python and stdlib only, the way the gates here are, so it runs on this box
with nothing installed.

- **Query and check are read-only.** They report; they do not edit frontmatter, because a priority
  bump should stay a hand-written one-line diff that someone can revert.
- **The rename is the one thing that writes**, and it writes only when a person has given it a target
  number. It is a separate script for that reason, not a `--fix` flag on the checker: a gate that can
  edit the files it is judging is the anti-pattern this convention is supposed to avoid.

Once normalisation has run, the checker is cheap enough to join `scripts/check.sh` as a gate. It
cannot join before, because it would fail on day one for reasons that are not anybody's mistake.

Prior art: klide has `scripts/gates/plan_status.py` (the tracking-table check) and `links.py`, which
this repo already borrowed. `tracked-development` itself is the convention being parsed, and
`skillify` in dotfiles is the local pattern for writing a skill. The published guidance used above is
[skill authoring best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices),
whose relevant points here are progressive disclosure, matching freedom to fragility, and preferring a
script to generated code for anything deterministic.

## Open questions

- Q1: normalise the existing folders first, or make the skill tolerant of missing frontmatter?
  Recommended: tolerant first, and let its own health query drive the normalisation. Fixing eighteen
  folders by hand before the tool exists is the wrong order.
  ANS: neither. No tolerant parser: the old plans get their content **and names** updated in a single
  pass, as part of implementing this feature. A parser that accepts anything encodes the mess it was
  written around.
- Q2: does the priority live only in `00_start.md`, or on each phase file too?
  Recommended: folder level only. Priority is about which feature to pick up next; phases inside a
  feature are already ordered.
  NEW_ANS:
- Q3: does this ship as a repo script, or straight into dotfiles as a skill?
  Recommended: build it here where the data is, move it to dotfiles once its queries survive a week of
  use. A skill that has never run against real folders is a guess.
  NEW_ANS:
- Q4: should it also write the roadmap view to a file, or stay a command?
  Recommended: stay a command. A generated file in the repo is a second copy of the truth, and it goes
  stale exactly like the hand-maintained index it replaces.
  NEW_ANS:

### Second batch (2026-09-25)

- Q5: how far back does normalisation go? Folders 02-09 predate the convention, are complete, and
  several are history rather than live work.
  a. All of them, so the checker can run clean over `plans/`.
  b. Folder 10 onward, with 00-09 declared pre-convention and skipped by name.
  Recommended: a, because "skipped by name" is a list someone has to maintain, and adding three lines
  of frontmatter to a finished folder costs less than the exception does.
  NEW_ANS:
- Q6: does the checker become a gate in `scripts/check.sh`?
  Recommended: yes, after normalisation, in the same feature. A checker that has to be remembered is
  prose with extra steps.
  NEW_ANS:
- Q7: does `description` get backfilled for every existing folder during normalisation, or only for
  new ones?
  Recommended: backfill all of them. The whole point is a listing with one line per feature, and a
  listing with holes in it is not one.
  NEW_ANS:

### Third batch, raised while brainstorming the branch work (2026-09-25)

- Q8: where does the script live once the skill moves to dotfiles, given the checker is meant to be a
  gate (Q6) and CI has no dotfiles checkout?
  a. Canonical copy in the skill; the repo gate is dropped, and the check runs only where a person or
     an assistant runs it.
  b. Canonical copy in the repo at `scripts/gates/plans_check.py`; the skill calls whatever it finds
     in the repo it is pointed at, and carries no script of its own.
  c. Canonical copy in the skill, vendored into each repo that wants it as a gate, with the version
     recorded.
  Recommended: b. The queries are the part that has to work anywhere; the check is a gate, and gates
  live in the repo they guard because CI has to run them. The skill then holds prose plus a documented
  contract for the script's arguments and output, and a repo without the script gets told so rather
  than silently skipped. c trades one duplicated file for a version-skew bug nobody will look for.
  NEW_ANS:
- Q9: what happens to the decimal side-documents (`00.1_`, `04.1_`) and the three non-feature folders
  (`00_drafts`, `01_plan_polishing`, `99_notes`)?
  a. Recognise both in the parser: a decimal file is a side-document of its parent phase and carries
     no status, and a folder with no `00_start.md` is not a feature and is skipped.
  b. Normalise them away: fold the side-documents into their parents, rename the non-feature folders
     out of the numbered range.
  Recommended: a. The decimal files are a convention that works, sorting a research note next to the
  phase it belongs to, and the three folders are genuinely not features. Recognising a real pattern is
  not the same as tolerating a mess, which is what Q1 ruled out. b is a large rewrite of finished
  history for no query anyone wants.
  NEW_ANS:
- Q10: does the cross-branch scan run in the checker by default, or only on request?
  a. Always, as part of the check.
  b. Only under a flag, and always in the rename workflow.
  Recommended: b. Reading every ref is fine on this box but it inspects branches whose content is
  nobody's business during a `check.sh` run, and a gate that fails because of a folder on someone
  else's unmerged branch is a gate that gets skipped. The collision matters when a folder is being
  created, which is exactly when the skill is in use.
  NEW_ANS:
- Q11: what does the rename script rewrite? Narrowed after the diary rule above: it cannot be
  "everything that points at the folder", because outside `plans/` nothing may.
  Recommended: rewrite `../NN_name/` links between plan folders and nothing else, print a diff
  summary, and refuse to run while a citation from outside `plans/` still exists. Half a rename is the
  failure mode worth scripting away; a rename that edits Dart comments is the rule being broken by the
  tool meant to enforce it.
  NEW_ANS:

### Fourth batch, raised by the diary rule (2026-09-25)

- Q12: who removes the thirteen citations?
  a. This feature, as a phase of the normalisation pass.
  b. A spin-off folder, since each one needs a decision rehomed in a docs file and that is editing the
     as-is documentation, not the plan folders.
  Recommended: b, with this feature shipping the check that finds them and leaving it failing-known
  until the spin-off lands. The two jobs share nothing but a grep: one is renaming files nobody reads,
  the other is deciding where "the base URL is a build-time define, not a Settings field" belongs in
  `docs/`. Bundling them makes this folder the thing that rewrites nine source files.
  NEW_ANS:
- Q13: does the no-citation check go in `scripts/check.sh` as a gate, and if so, before or after the
  thirteen are removed?
  Recommended: same answer as Q6 and the same reason. It is a gate whose value is stopping the
  fourteenth, so it wants to be in `check.sh`, and it cannot go in while it fails. If Q12 goes to a
  spin-off, this check ships red-but-unwired and is armed by that spin-off's last commit.
  NEW_ANS:
- Q14: does the rule get written into `tracked-development` in dotfiles now, or when this skill moves
  there?
  Recommended: now, as a few lines in that skill, because it is a convention that applies to every
  repo using the skill and the cost is a paragraph. It also stops the next feature folder in this repo
  from adding a fourteenth citation while Q12 is still open. Separate repo, separate commit.
  NEW_ANS:
- Q15: what is the destination for a rehomed decision, once Q12 is settled?
  a. The topical doc that owns the subject (`docs/build-and-release.md` for the ABI exclusions,
     `docs/getting-started.md` for the base-URL override, `docs/prompt-engineering.md` for the prompt
     rules).
  b. One new `docs/decisions.md`, an ADR index.
  Recommended: a. b is the plans diary copied into `docs/` under a different name, and it would go
  stale the same way, whereas the topical docs are already the as-is snapshot and are what a reader
  opens. Where no topical doc exists, that is a missing doc rather than an argument for an index.
  NEW_ANS:
