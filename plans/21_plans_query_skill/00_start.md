---
status: draft
priority: 0
---

# A skill that can answer questions about the plan folders

Status: draft spin-off, raised 2026-09-25. No phases derived. Born here, expected to end up in
dotfiles alongside `tracked-development`.

## Where this came from

The ask: a spin-off skill "which parses our tracked development frontmatter and has some basic
queries enabled on state enum, index range `NN_feat`, and a new priority field. All priorities are
born at 0, if a feature is more important we just bump it up by one so we can sort them easily with a
one line of diff in the `00_start`. When done it's bumped back to 0 as the state goes to done."

## The priority convention, as given

- Every plan is born `priority: 0`.
- More important means bump by one. Sorting is descending by priority.
- Done means back to `0`, so a finished feature never sits at the top of the list.
- The point is the diff: raising a priority is one line in `00_start.md`, reviewable and revertible,
  rather than a reshuffle of some index file.

First uses, applied when this was raised:
[`../16_cloud_first_engine/00_start.md`](../16_cloud_first_engine/00_start.md) at `priority: 1`, the
other new drafts at `0`.

## What the data actually looks like (checked 2026-09-25)

The folders are not uniform, and the skill has to cope or the repo has to be normalised first:

- `status:` frontmatter exists on phase files in the newer folders (10 onward) and on some
  `00_start.md` files, but not all. `13_key_distribution/00_start.md` has none;
  `14_audio_io/00_start.md` has `status: draft` and no priority.
- `tracking.md` exists in 10, 12, 15, 17; phase 11 calls it `00_tracking.md`; the older folders
  (02-09) use a `README.md` and numbered files with no frontmatter at all.
- Statuses in use: draft, planned, in progress, done, superseded, discarded (the
  `tracked-development` list), plus the folder-level ones written in prose.

So "parse the frontmatter" means "parse the frontmatter where it exists, and report where it does
not", which is itself one of the useful queries.

## Queries worth having

- By status: what is `in progress` right now, across every folder.
- By priority: the sorted list, which is the closest thing this project has to a roadmap. Note there
  is no roadmap document today, and this output is meant to be it rather than a second file to keep in
  sync by hand.
- By index range: `NN` and `NN_feat_*`, so "what is phase 15 made of" is one command.
- Health: files with no frontmatter, statuses that are not in the enum, and phase files missing from
  their `tracking.md` table (the check klide implements as `scripts/gates/plan_status.py`, which this
  repo does not have).

## Shape

A small script plus a skill that knows how to call it. Python and stdlib only, the way the gates here
are, so it runs on this box with nothing installed. Read-only: it reports, it does not edit
frontmatter, because a priority bump should stay a hand-written one-line diff.

Where it lives is the open part: it is written here against real data, and belongs in dotfiles once it
works, next to `tracked-development` whose convention it reads. The sibling repo (klide) has the
closest prior art.

## Open questions

- Q1: normalise the existing folders first, or make the skill tolerant of missing frontmatter?
  Recommended: tolerant first, and let its own health query drive the normalisation. Fixing eighteen
  folders by hand before the tool exists is the wrong order.
  NEW_ANS:
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
