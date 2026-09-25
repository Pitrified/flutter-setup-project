---
status: done
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

### Discarding cascades

A dependency on a `discarded` or `superseded` folder fails, and unlike the missing-prerequisite warning
this one is hard. The reason is timing: the cost of a discarded feature is not the folder, it is the plans
downstream that quietly assumed it, and the only moment anyone will think about them is the moment the
status changes.

So the message is written from the discarded folder's side rather than the dependent's, because that is
where the person is standing:

```
plans: 20_repo_split/00_start.md: discarded, and 23_dependency_upgrades depends on it
```

That needs a reverse lookup over `depends_on`, which the parser gets for free once it holds the forward
edges.

It cascades, and that is the point rather than a side effect. Repointing `23` may mean discarding it too,
which fails the same rule for whatever depended on `23`, until the tree is consistent again. Run, fix,
run: the loop ends when the checker is quiet, and every step of it was a decision someone had to make
anyway.

"For now" is doing real work in this answer. If it turns out that most discards are leaves and the rule
only ever fires on the same two folders, it should soften. That is a judgement to make after it has fired
a few times, not before.

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

Four keys now, six with `depends_on` and `comment`, and the parser hands back a dict of strings that
every caller pokes at by key. That was right for two keys and is close to the point where it is not: a typed object with the
keys as fields, built once from the block, would put the "`priority` is a non-negative integer" and
"`depends_on` is a list" rules in one place instead of at each use. Pure standard library, a dataclass
with a classmethod that validates, no dependency. Worth doing as part of this folder rather than after
it, since this is the change that adds the first non-scalar field.

## What the 27 legacy keys actually say

Folding each phase-level `depends_on` up to the folder it names, dropping doc paths and self-references,
leaves this:

```
04_core_systems      depends_on: [03_scaffold]
05_controllers       depends_on: [04_core_systems]
```

Two edges, out of 27 keys in 27 files. Everything else was one of three things: a phase in folder 02
depending on an earlier phase in folder 02, which the phase numbering already says; a dependency on a doc
(`03_scaffold/00_create_project.md` on `docs/getting-started.md`), which is backwards since the doc was
produced by a phase; or `[]`.

That is the strongest argument for Q1 that the folder has: dependency information at sub-phase level was
recorded twenty-seven times and carried almost nothing, because inside a feature the ordering is the
numbering, and between features there were two facts worth writing down.

## A freeform `comment:` key

Some of what the legacy keys held is worth keeping and has no field: `05_integration.md` recorded that it
came after the other five phases in its folder, and that is real history even though nothing should check
it.

So the frontmatter gains `comment:`, freeform, optional, separate from `description`:

- `description` is what a listing shows: what this is and why, one line per feature.
- `comment` is a note for whoever opens the file. Nothing parses it, nothing validates it, and it never
  appears in `list` output.

It exists so that the answer to "this does not fit the schema but I do not want to lose it" is a place to
put it rather than a new key with rules attached. The typed object holds it as a plain string.

## How many cases this script gets to have

Settled while answering Q5, and it applies to the rest of this folder as much as to that question.

`scripts/plans.py` is one file that already holds thirteen rules, four subcommands and two output
formats, and this folder adds a graph to it. The budget is not tokens, it is how many branches a reader
has to hold to predict what the script does. So the default answer to "could the script also handle X" is
no, twice over:

- **If the case is rare, leave it to a person or an assistant reading the output.** `superseded` happens
  once a year; the cost of handling it is permanent and the benefit is one saved file read. The output
  saying what is broken is enough for someone to act on.
- **If handling it needs a new field, the bar is higher again**, because a field is a thing every future
  plan file can carry and every reader has to know about, not just a branch in one script.

What stays in scope here: the forward edges, the reverse lookup for the cascade, the two severities, and
the cycle check. Those are load-bearing for the two faults this folder exists to catch. Everything else
is a judgement the reader makes with the output in front of them.

## Open questions

- Q1: does `depends_on` name folders only, or may it name a phase file in another folder?
  a. Folders only. A dependency between features is the thing that gets forgotten.
  b. Either, so a phase can depend on one phase elsewhere.
  Recommended: a. b is a graph that needs maintaining, and the finer it gets the more often it is wrong.
  ANS: a. Folders only. The working unit is a whole feature: the intent is to work on one folder at a
  time where possible, so a prerequisite is a folder being finished, not a phase inside one being
  reached.
- Q2: is a prerequisite that is `discarded` or `superseded` satisfied?
  Recommended: report it rather than decide it. Either the dependent plan should be reworded or the
  prerequisite's replacement should be named, and both are edits a person makes.
  ANS: no. Depending on a `discarded` or `superseded` folder is a hard failure, for now. Discarding a
  feature is exactly the moment to see what it breaks downstream, and the downstream plan then depends on
  something else, on nothing, or is discarded too. Whoever discards a feature has to think about the
  consequences; the checker's job is to make sure they cannot avoid it. See "Discarding cascades" below.
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
- Q5: `superseded` means some other folder replaced this one, and today that replacement is named in
  prose in the body (as `08_llm_integration/04_api_key_distribution_production.md` names folder 13). Does
  it become a frontmatter key, `superseded_by: 13_key_distribution`?
  a. Yes. Then the cascade message can say what to repoint to, not just that something is broken.
  b. No. The body says it, and a reader can follow it.
  Recommended: a, for one reason only: with it, the checker's output is "repoint 23 at 13" and without it
  the reader has to open the superseded folder to find out what replaced it. It is one optional key on a
  status that is rare, and the information already exists in prose, which is the argument that it is
  cheap rather than the argument that it is needed.
  ANS: b. No new key. This script will already grow enough cases to handle, and `superseded` is small and
  rare: the cascade message says what is broken, and an assistant works out what to repoint at by reading
  the folder, case by case. See "How many cases this script gets to have" below.

### Second batch, raised by the review before the phases were written (2026-09-26)

- Q6: `depends_on` is already taken. Checked in frontmatter rather than by grep: 27 phase files carry it,
  in three shapes (22 naming phase paths such as `[03_scaffold/02_generated_models.md]`, 3 naming doc
  paths such as `[docs/getting-started.md]`, 2 empty), from the convention folders 02-05 were written
  under. Exactly one `00_start.md` carries the new folder-level form, the one written yesterday in
  `23_dependency_upgrades`.
  a. Read it only from `00_start.md`. The collision is clean by file role, phase-level values stay as they
     are, and the validator has no special case. Cost: a `depends_on` typo'd onto a phase file is silently
     ignored.
  b. Rename the new field, `requires:`, leaving `depends_on` entirely to the old convention. No ambiguity
     for the price of a worse word.
  c. Normalise the 27, converting phase paths to the folder they live in and dropping the doc paths.
  Recommended: a. The two live in different files and mean different things, which is exactly the
  condition under which one name is fine, and Q1 already put the new field at folder level only. c
  rewrites 27 finished files to remove information (`produces` and `depends_on` between phases are a
  record of how those phases were sequenced) for no query anyone has asked for. The silent-ignore cost is
  real but small, because the field is optional: a missed `depends_on` leaves the status quo.
  ANS: c, with the conversion rules given rather than guessed: fold a sub-phase dependency up to the
  feature it lives in, drop a dependency on a doc entirely (you would depend on the phase that wrote it,
  and that is strange enough not to make a rule out of), and drop the empty ones. Anything worth keeping
  that the new convention has no field for goes in a new freeform `comment:` key that nothing checks.
  Measured before deciding: the 27 keys carry two feature-level edges. See below.
