---
status: done
---

# Phase 2 - Normalise every folder

## Overview

One pass over `plans/`, content and names, so that afterwards a file without frontmatter is a bug
rather than a variation. This is what Q1 chose instead of a tolerant parser, and Q5 extended to every
folder rather than folder 10 onward. The per-folder moves are decided already: see
[`00_start.md`](00_start.md), "Start files, folder by folder" and "What `plans/00_tracking.md` holds".
Depends on [`01_parser_and_queries.md`](01_parser_and_queries.md), whose output is this phase's work
list.

## Goals

1. Every feature folder has `00_start.md` with `status`, `priority` and `description`, and a
   `tracking.md`.
2. Every phase file has a `status` that matches its row in `tracking.md`.
3. `plans/00_tracking.md` is gone, and nothing it held is lost.

## Plan

In this order, because the last step consumes the others' inputs:

- **Start files**, per the table: rename `README.md` to `00_start.md` in 02-07 and 09, `00_intro.md` in
  11, `00_coalesced_plan.md` in 08; write a new minimal `00_start.md` for folder 10 pointing at its two
  research files; rename `11_apple_integration/00_tracking.md` to `tracking.md`.
- **Frontmatter** on the five start files that have none (01, 12, 13, 15, 17) and on the renamed ones.
  `priority: 0` throughout: every folder here is either done or not yet picked up.
- **`description`** on every `00_start.md` (Q7), taken from the `Produces` column of
  `plans/00_tracking.md` where it covers the folder, and from the folder's own opening lines otherwise.
- **`tracking.md`** for the eight folders without one, with the phases table built from
  `plans/00_tracking.md`'s per-phase tables and a Log seeded with what that file records. Folder 08's
  six step rows, which describe work with no file, go in its Log.
- **Statuses**, mapping that file's vocabulary onto the enum: `complete` to `done`, `in-progress` to
  `in progress`. Two are not mechanical: `07_release` stays `in progress` because the Play Store steps
  are outstanding, and `08_llm_integration/04_api_key_distribution_production.md` becomes `superseded`
  with a line pointing at [`../13_key_distribution/00_start.md`](../13_key_distribution/00_start.md).
- **Delete `plans/00_tracking.md`**, and change the two references to it in `docs/README.md` and
  `docs/ai-development-playbook.md` to the general shape (Q18).
- Run `scripts/gates/links.py` after the renames, which is what catches anything that pointed at an old
  name.

## Out of scope

- Renaming `NN_name.md` to `NN_feat_name.md`. Q20 settled that the `feat` segment is a placeholder, so
  about fifty files stay as they are.
- Folding the decimal side-documents (`00.1_`, `04.1_`) into their parents. Q9 settled that they are a
  valid convention the parser recognises.
- `00_drafts` and `99_notes`, which are reference dumps and not features.
- Rewriting the content of any finished plan. Frontmatter, names and the files listed above only.

## Done when

- `python3 scripts/plans.py list` prints no `-` in the status, priority or description columns for any
  feature folder.
- `plans/00_tracking.md` does not exist, and its `Produces` text is findable in the descriptions.
- `scripts/gates/links.py` green, and `scripts/check.sh` green.
- A spot check by hand on three folders: 07 still says the Play Store work is outstanding, 08's log
  holds the six steps, 13 is named as what superseded 08's deferred plan.

## What the implementation found

- **The statuses in the pre-convention folders were stale in three vocabularies.** Folder 02 said
  `draft` and folder 03 said `not-started` for work that shipped in July; folders 04 and 05 said
  `complete`. 27 files, none of them in the enum. The only accurate record was `plans/00_tracking.md`,
  the file this phase deletes, which is the argument for the checker in one sentence.
- **Folders 02-05 already carried `depends_on` and `produces` keys.** The inventory in `00_start.md` had
  said frontmatter on phase files started at folder 10; wrong, and in the useful direction, since
  `produces` is the `Produces` column already structured. Both keys are left alone, and the checker
  validates the keys it knows rather than rejecting the rest.
- **101 files carry a status**: 21 start files and 79 phase files, plus one side-document. Per folder it
  is four to ten; it is twenty-two folders that make the number.
- **`01_plan_polishing/README.md` was a third shape**, a two-row index with a "Status: Active" line
  wrong since July. Removed, with its one useful pointer moved into `00_start.md`.
- The links gate earned its place twice: 23 broken links after the renames, one more after removing that
  README. Every one was in a file nobody would have thought to check.
