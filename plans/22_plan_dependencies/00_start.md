---
status: draft
priority: 0
description: |
  An optional depends_on in a plan folder's frontmatter, so the tooling can catch a priority that
  drifted above its own prerequisite and a feature picked up before something it needs. Also the point
  at which the frontmatter is worth modelling as a typed object rather than a dict.
---

# depends_on: prerequisites between plan folders

Draft spin-off, raised 2026-09-25 while closing
[`../21_plans_query_skill/00_start.md`](../21_plans_query_skill/00_start.md).

## Where this came from

Phase 5 of folder 21 ended by using the new skill for real, on the question "what is next by priority
and what does it depend on". It answered the first half and could not answer the second, because nothing
records a prerequisite. The field was deliberately not invented on the spot; this folder is where it
gets designed.

## What it is for

Not documentation. Two specific faults a script could catch and a person will not:

- **A priority that drifted above its prerequisite.** A folder bumped to `priority: 2` whose prerequisite
  sits at `0` and `draft` is a plan that cannot be started, and the listing currently presents it as the
  next thing to do. That is the failure the field exists to make visible.
- **A feature picked up before something it needs.** Setting a folder to `in progress` while a
  prerequisite is not `done` is a real mistake, and the only reason it does not happen often is that one
  person holds the order in their head.

First real case, written before this folder existed:
[`../23_dependency_upgrades/00_start.md`](../23_dependency_upgrades/00_start.md) depends on
[`../20_repo_split/00_start.md`](../20_repo_split/00_start.md), because the split decides which repo owns
the `pubspec.yaml` being upgraded. It carries the field already, which makes it the sample this folder is
designed against rather than an example invented for the purpose.

## Sketch

```yaml
---
status: draft
priority: 0
depends_on: [20_repo_split]
description: |
  ...
---
```

Folder level, optional, a list of folder names. Absent means no prerequisite, which is the common case
and has to stay free of ceremony.

What the checker would then report: a name that is not a folder, a cycle, a folder `in progress` or
`done` whose prerequisite is not `done`, and a folder whose priority exceeds a prerequisite's. What
`list` would show: the prerequisite in a column, and a marker on the rows that are not startable.

## The frontmatter is growing

Four keys now, five with this one, and the parser hands back a dict of strings that every caller pokes
at by key. That was right for two keys and is close to the point where it is not: a typed object with the
keys as fields, built once from the block, would put the "`priority` is a non-negative integer" and
"`depends_on` is a list" rules in one place instead of at each use. Pure standard library, a dataclass
with a classmethod that validates, no dependency. Worth doing as part of this folder rather than after
it, since this is the change that adds the first non-scalar field.

## Open questions

- Q1: does `depends_on` name folders only, or may it name a phase file in another folder?
  a. Folders only. A dependency between features is the thing that gets forgotten.
  b. Either, so a phase can depend on one phase elsewhere.
  Recommended: a. b is a graph that needs maintaining, and the finer it gets the more often it is wrong.
  NEW_ANS:
- Q2: is a prerequisite that is `discarded` or `superseded` satisfied?
  Recommended: report it rather than decide it. Either the dependent plan should be reworded or the
  prerequisite's replacement should be named, and both are edits a person makes.
  NEW_ANS:
- Q3: does the checker fail or warn on a priority that outranks its prerequisite?
  Recommended: fail. It is a gate, and the whole reason for the field is that this is invisible
  otherwise. A warning in a gate that passes is prose.
  NEW_ANS:
