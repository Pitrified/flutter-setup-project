---
status: draft
priority: 0
description: |
  Jira-lite for the plan folders: a skill that parses the frontmatter and answers
  queries by status, priority and phase index, plus a plans-checker script the
  assistant runs for mechanical correctness. Includes a one-pass normalisation of
  the older folders, so there is nothing to be tolerant of.
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

## What the data actually looks like (checked 2026-09-25)

The folders are not uniform. They get normalised rather than tolerated (Q1):

- `status:` frontmatter exists on phase files in the newer folders (10 onward) and on some
  `00_start.md` files, but not all. `13_key_distribution/00_start.md` has none;
  `14_audio_io/00_start.md` has `status: draft` and no priority.
- `tracking.md` exists in 10, 12, 15, 17; phase 11 calls it `00_tracking.md`; the older folders
  (02-09) use a `README.md` and numbered files with no frontmatter at all.
- Statuses in use: draft, planned, in progress, done, superseded, discarded (the
  `tracked-development` list), plus the folder-level ones written in prose.

Normalisation is part of this feature, in one pass, and it touches names as well as content:
`11_apple_integration/00_tracking.md` becomes `tracking.md`, folders without frontmatter get it, and
the older README-driven folders (02-09) either gain the convention or are explicitly marked as
pre-convention history so the checker stops reporting them. Doing it in one pass is what lets the
parser be strict: after it, a file without frontmatter is a bug rather than a variation.

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

Relative links are already covered by `scripts/gates/links.py` and are not re-checked here.

## Shape

A small script plus a skill that knows how to call it. Python and stdlib only, the way the gates here
are, so it runs on this box with nothing installed. Read-only: it reports, it does not edit
frontmatter, because a priority bump should stay a hand-written one-line diff.

Once normalisation has run, the checker is cheap enough to join `scripts/check.sh` as a gate. It
cannot join before, because it would fail on day one for reasons that are not anybody's mistake.

Where it lives is the open part: it is written here against real data, and belongs in dotfiles once it
works, next to `tracked-development` whose convention it reads. The sibling repo (klide) has the
closest prior art.

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
