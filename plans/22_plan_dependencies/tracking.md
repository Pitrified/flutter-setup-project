# depends_on - implementation tracking

An optional `depends_on` on a feature folder's `00_start.md`, and the checks over it: a prerequisite
that is not finished, a priority that drifted above one, a cycle, and a discarded folder something else
still depends on. Analysis, the five answered questions and the complexity budget are in
[`00_start.md`](00_start.md).

## Key decisions

- **Folders, not phases** (Q1). The working unit is a whole feature, so a prerequisite is a folder being
  finished rather than a phase inside one being reached.
- **Two severities** (Q4). A prerequisite that resolves nowhere is a finding; one that exists on another
  branch is a warning, because it is somebody else's merge on their schedule.
- **A discard is hard and cascades** (Q2). Depending on `discarded` or `superseded` fails, and the message
  is written from the discarded folder's side, naming what depends on it.
- **Numbers are identity, not order.** A prerequisite may be numbered higher; cycles are what has to be
  checked once the numbers stop ruling them out.
- **The script's case budget** is how many branches a reader must hold to predict it. Rare cases go to
  whoever reads the output (Q5).

## Phases

| #  | Phase                            | Plan                                                     | Status  |
| -- | -------------------------------- | -------------------------------------------------------- | ------- |
| 01 | Frontmatter as a typed object    | [`01_typed_frontmatter.md`](01_typed_frontmatter.md)     | planned |
| 02 | The field, parsed and listed     | [`02_depends_on_field.md`](02_depends_on_field.md)       | planned |
| 03 | The hard rules, and the cascade  | [`03_hard_rules.md`](03_hard_rules.md)                   | planned |
| 04 | The soft rule, across branches   | [`04_soft_rule_cross_ref.md`](04_soft_rule_cross_ref.md) | planned |
| 05 | Document the field               | [`05_document_the_field.md`](05_document_the_field.md)   | planned |

Status values: draft / planned / in progress / done / superseded / discarded.

## Log

Append-only. Newest at the bottom.

- 2026-09-25 : spun off as a draft while closing folder 21, whose phase 5 ended by using the new skill on
  "what is next by priority and what does it depend on" and finding the second half unanswerable.
- 2026-09-25 : Q1-Q5 answered while still a draft: folders only, hard failure on a discarded prerequisite
  with a cascading reverse-lookup message, a warning for a prerequisite living on another branch, no
  `superseded_by` key, and a stated budget for how many cases the script gets to have.
- 2026-09-26 : reviewed before deriving phases, per the skill's five questions. One finding, raised as Q6:
  `depends_on` is already in frontmatter on 27 phase files in three shapes (22 phase paths, 3 doc paths, 2
  empty), against exactly one `00_start.md` using the new folder-level form. The collision is clean by
  file role, so it wants a decision rather than a rename. Two claims checked and held: `difflib` is
  stdlib, and the reverse lookup for the cascade is free once the forward edges are parsed.
- 2026-09-26 : phases derived, five sub-plans written. Nothing implemented.
