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
- **One meaning per key** (Q6). The 27 legacy phase-level `depends_on` values are converted rather than
  tolerated: they fold up to two feature-level edges, doc dependencies and empty lists are dropped, and
  what is worth keeping moves to a new freeform `comment:` that nothing checks.

## Phases

| #  | Phase                            | Plan                                                     | Status  |
| -- | -------------------------------- | -------------------------------------------------------- | ------- |
| 01 | Frontmatter as a typed object    | [`01_typed_frontmatter.md`](01_typed_frontmatter.md)     | done    |
| 02 | The field, the legacy keys, list  | [`02_depends_on_field.md`](02_depends_on_field.md)       | done    |
| 03 | The hard rules, and the cascade  | [`03_hard_rules.md`](03_hard_rules.md)                   | done    |
| 04 | The soft rule, across branches   | [`04_soft_rule_cross_ref.md`](04_soft_rule_cross_ref.md) | done    |
| 05 | Document the field               | [`05_document_the_field.md`](05_document_the_field.md)   | done    |

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
- 2026-09-26 : Q6 answered by converting the legacy keys, with the conversion measured first: folding all
  27 up to feature level yields two edges, 04 needing 03 and 05 needing 04. The other 25 were intra-folder
  ordering the phase numbers already give, dependencies pointing at docs a phase had produced, or empty.
  That measurement is also the best evidence for Q1. Phase 02 absorbed the conversion, and the frontmatter
  gains a freeform `comment:` for what is worth keeping and should not be checked.
- 2026-09-26 : phase 01 - `Frontmatter` dataclass, problems collected per file rather than raised on the
  first. Two bugs, both found by diffing the four captured outputs and neither by reading the code:
  `priority: 0` is falsy so the presence check reported every folder as missing it, and the `pri` column
  broke once the value was an int. `list`, `check --citations` and both broken copies now produce output
  identical to before, which was the phase's entire success condition.
- 2026-09-26 : phase 02 - `depends_on` and `comment` parsed, a `needs` column with two markers, and the 27
  legacy keys converted: they folded to the two predicted edges (04 needs 03, 05 needs 04), 18 phase files
  gained a `comment: after ...` holding the intra-folder ordering, and the doc dependencies and empty lists
  went. No phase file carries `depends_on` now, so the validator needs no special case for it.
- 2026-09-26 : phase 03 - five findings and a cycle check, each demonstrated failing on its own copy of
  `plans/`. The three-folder cycle needed its own case, since the two-folder one passes with almost any
  implementation. The cycle message named a folder rather than a file and was fixed before closing: this
  repo's gates name the file.
- 2026-09-26 : phase 04 - severities. A prerequisite living on another ref is a warning that names the ref
  and does not fail the gate; one existing nowhere stays a finding with the close match. Demonstrated on a
  clone with the prerequisite on a second branch, including the stronger wording when the dependent is
  itself in progress. The claim that the passing path reads no refs was measured with strace rather than
  asserted: zero `ls-tree` calls clean, 117 once a name is missing.
- 2026-09-26 : phase 05 - the field documented in the skill's frontmatter reference, including a table for
  the three `needs` markers because they call for three different next actions, and a line in the skill's
  "what to work on next" workflow saying not to recommend a marked row. `depends_on` and `comment` added to
  folder 21's queue for the `tracked-development` uplift.
- 2026-09-26 : all five phases done. Folder closed, priority back to 0. Not merged: the branch waits, per
  `docs/git-workflow.md`.
