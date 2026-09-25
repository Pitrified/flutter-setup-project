# Plan file frontmatter and the rules a checker enforces

## Contents

- Frontmatter schema
- The status enum
- File naming
- What `check` reports
- What is deliberately not checked

## Frontmatter schema

`00_start.md`, one per feature folder, carries all three:

```yaml
---
status: in progress
priority: 0
description: |
  Two or three lines saying what this feature is and why, readable by someone who
  has not opened the folder. It is what a listing shows, one line per feature.
---
```

`NN_name.md`, one per phase, carries `status` only. `description` is allowed and usually redundant,
since the file's own `## Overview` says it. `tracking.md` carries no frontmatter: the phase table holds
the statuses.

`priority` lives on `00_start.md` only. Phases inside a feature are already ordered, so a per-phase
priority would be a second ordering to keep in sync. Born at 0, bumped by one when a feature matters
more, back to 0 when the folder is `done`. The point is the diff: raising a priority is one reviewable
line, not a reshuffle of an index.

Other keys are ignored rather than rejected. Some older folders carry `depends_on` and `produces`.

## The status enum

| Status | Meaning |
| ------ | ------- |
| `draft` | sketched, not yet agreed as the plan of record |
| `planned` | agreed and sequenced, not started |
| `in progress` | actively being worked |
| `done` | goals met and the "Done when" criteria verified |
| `superseded` | replaced by a different plan; name which one in the body |
| `discarded` | abandoned; keep the file and note why |

Nothing else. `complete`, `not-started` and `planned (deferred)` are what this enum exists to stop: a
status column with two facts in one cell is a status nobody can filter on.

## File naming

| Name | Role |
| ---- | ---- |
| `00_start.md` | the origin document: idea, analysis, decisions, questions. A folder without one is not a feature and is skipped entirely |
| `tracking.md` | the index: phase table plus an append-only log |
| `NN_name.md` | one phase. The `feat` in `NN_feat_name.md` is part of the placeholder, not a required word |
| `NN.M_name.md` | a side-document of phase NN: research, an analysis, a capture. Carries no status |

Numbers are unique within a folder and need not be contiguous.

## What `check` reports

Each finding names the file, and the line where a line applies.

- frontmatter missing, or opening with `---` and never closing
- `status`, `priority` or `description` missing from a `00_start.md`; `status` missing from a phase file
- a status, in a file or in a table row, that is not in the enum
- a priority that is not a non-negative integer, or a `done` folder not back at 0
- a phase file missing from its `tracking.md` table, or a table row naming a file that does not exist
- a table status that disagrees with the file's own frontmatter
- a duplicate phase number, or a file name that is not one of the four above
- `NEW_ANS:` left in a folder whose phases are all `done`
- with `--citations`: a reference to a specific plan folder from outside `plans/`

## What is deliberately not checked

- **Relative links**, which have their own gate. Two gates checking links is one too many.
- **Anything requiring judgement**: whether a description is good, whether a phase is really done,
  whether the phases are the right ones. A checker that guessed at those would be ignored.
- **Nothing is edited.** `check` and `list` are read-only, and there is no `--fix`: a gate that can edit
  the files it judges cannot be trusted about them. `rename` is the only writer, and it writes only when
  a person has given it a number.
