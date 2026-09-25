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

### Two severities

This introduces the first soft rule in the checker: the thirteen rules it has today all fail, and this
one only reports.

- **Finding, exit 1.** A name that resolves nowhere: not in the tree and not on any ref. That is a typo
  or a folder that was never created, and the close-match suggestion belongs here.
- **Warning, exit 0.** A name that is not in this tree but exists on another ref. Someone is working on
  it, and the plan is correct about depending on it; what is missing is a merge, on their schedule.

The warning's text carries the refs the folder was found on, so the reader's next action is obvious
(`git log <ref>` or ask whoever owns it). When the dependent folder's own status is `in progress`, the
warning says so in stronger terms: at that point the merge is not housekeeping, it is what the current
work is waiting for, and an assistant reading the output should raise it rather than note it.

This also settles a tension with
[`../21_plans_query_skill/00_start.md`](../21_plans_query_skill/00_start.md) Q10, which kept the
cross-branch scan behind a flag so that `check` does not read every ref on every run. It still does not:
refs are consulted **only** when a name fails to resolve in the tree, which is the rare path. A tree
where every prerequisite resolves makes no git calls beyond the one it already makes.

Practical consequence for `list`: a row whose prerequisite is not in the tree is marked as not startable
here, distinctly from one whose prerequisite is present but unfinished. The first needs a merge, the
second needs work, and they are not the same message.

### What a name resolves against

The set of legal names is the set of folders the tooling already finds: a numbered directory holding a
`00_start.md`, in the working tree, the same set `list` prints. Not a registry file listing the legal
names, because that is a second copy of something the directory already is, and it would be wrong within
a month. So a name resolves if and only if the plan it names can actually be read, which is the property
worth having.

A name that does not resolve in the tree is looked for across the refs before anything is reported, per
the severities above. If it exists nowhere it is a finding, naming the file and the unknown name, with
the closest existing folder suggested: `difflib.get_close_matches` is in the standard library and a typo
in `20_repo_splt` should not cost anyone a search.

### Numbers are identity, not order

The checker must **not** require a prerequisite to have a lower number, and this is the part worth being
explicit about because it looks like an obvious rule and is wrong.

A folder's number is its creation order. Execution order is what `depends_on` records, and the two
routinely disagree: `20_logging` gets picked up, and in the course of it a real prerequisite is
discovered and spun off as `21_backend_setup`. The order is now 21 then 20, and that is the normal way
work is found rather than a mistake to correct. Renumbering to keep the numbers sorted would mean
rewriting every inbound link, the branch name and the commit history's references, for an aesthetic.

Two consequences:

- No rule about the relative size of numbers. A prerequisite may be numbered anywhere.
- Cycles have to be detected, since the numbers no longer rule them out. `20` depending on `21` is fine;
  `20` depending on `21` which depends on `20` is not, and nothing but a cycle check will say so.

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
  ANS: fail. Left to see how annoying it gets in practice before relaxing it: if it fires on something
  that turns out to be legitimate, that is evidence about the rule rather than a reason to soften it in
  advance.
- Q4: may `depends_on` name a folder that exists only on another branch, not in the working tree?
  a. No. A name resolves against the folders in the tree, and a prerequisite you cannot read is not one
     you can check anything about. `branches` is the tool for what exists elsewhere.
  b. Yes, with the checker treating an unresolvable name as unknown rather than wrong.
  Recommended: a, on the grounds that b's "unknown rather than wrong" is a status that never gets
  revisited. A prerequisite living on an unmerged branch is a real situation, and the honest handling is
  that the dependent plan waits for that branch to land before it can say so.
  ANS: b, overriding the recommendation. Someone else may be implementing the prerequisite, and merging
  their plans into ours so that a reference resolves is overkill: let them finish, then the merge brings
  it in. So an unresolvable name that exists on another ref is a **warning**, not a gate failure. The
  case the recommendation worried about is handled by who reads the warning: when the dependent folder is
  actually being worked, the missing prerequisite is the thing an assistant should notice and raise the
  now-critical merge over. See "Two severities" below.
