---
name: managing-plan-folders
description: Query, check and renumber the tracked-development plan folders under plans/ - answers what is in progress, what to work on next by priority, and what a phase folder contains, and validates frontmatter, statuses and tracking tables. Use when asked what to work on next, when spinning off or finishing a plan folder, when a plan file fails a gate, or when two branches have claimed the same folder number.
---

# Managing plan folders

`plans/` is a development diary kept in the shape the `tracked-development` skill describes: one
numbered folder per feature, a `00_start.md` holding the reasoning, a `tracking.md` holding the phase
table and log, and `NN_name.md` per phase. This skill is the tooling over that: read it with one
command instead of opening twenty folders, and check it mechanically instead of remembering the rules.

The frontmatter schema, the status enum and every rule the checker enforces are in
[reference/frontmatter.md](reference/frontmatter.md). Read that file when writing or fixing a plan
file; this one is the workflows.

## The script

One file, standard library only, in the repo being worked on:

```bash
cd "$(git rev-parse --show-toplevel)"
python3 scripts/plans.py list                      # every folder, by priority
python3 scripts/plans.py list --status "in progress"
python3 scripts/plans.py list --index 15           # or 09-12: what those folders contain
python3 scripts/plans.py list --out /tmp/roadmap.md   # or .html, to attach in chat
python3 scripts/plans.py check                     # mechanical faults, file and line
python3 scripts/plans.py check --citations         # also: nothing outside plans/ cites a plan
python3 scripts/plans.py branches                  # folder numbers across every branch
python3 scripts/plans.py rename 21_old_name 22     # renumber, and fix sibling links
```

`--root <dir>` points it at a plans directory anywhere; without it the root is
`$(git rev-parse --show-toplevel)/plans`. If `scripts/plans.py` does not exist in the repo, that repo
has not adopted this tooling: say so rather than writing a one-off script.

## Workflows

### What should I work on next

`list` sorts by priority descending, then by number. Priority is the only ordering: every folder is
born at `priority: 0`, a more important one is bumped by one, and a folder going to `done` goes back to
0 so a finished feature never sits at the top. Read the `status` and `phases` columns before
recommending anything: a folder at `in progress` with `3/5` is a better answer than a `draft` at the
same priority.

Read the `needs` column too, and do not recommend a row marked `*` or `?`: the first is waiting on another
feature, the second on a merge. A `?` on a folder that is already `in progress` is the one to raise
unprompted, because that merge is what the current work is waiting for.

There is no roadmap document. This output is it.

### Spinning off a new folder

1. `python3 scripts/plans.py branches`. It reads refs, not the working tree, because a number is
   claimed the moment someone creates the folder and an unmerged branch is invisible otherwise.
2. **Ask the person which number to use**, telling them which are taken and on which refs. Do not take
   `max + 1` silently: two people picking the same free slot on their own branches reproduce the
   collision one number along.
3. Create `plans/NN_name/00_start.md` with full frontmatter (`status: draft`, `priority: 0`, a
   `description` block) and the note of where the idea came from. A draft needs no `tracking.md` until
   it is picked up.
4. Work on it in a branch named after it: `feat/<NN_name>`.

### A number is used twice

`branches` prints `COLLISION` and the refs. Ask the person for the new number, then
`rename <folder> <NN>`. It refuses while anything outside `plans/` cites a plan folder, since renaming
would otherwise mean editing code to keep a diary reference alive. Afterwards run the repo's gates and
commit: `branches` reads refs, so it keeps reporting the collision until the rename is committed.

### Before committing a plan change

`check` is one of the repo's gates and runs in the pre-commit hook, so normally there is nothing to do.
Run it directly after editing several plan files at once, and read its output as a list of files to fix
rather than as advice: every rule is mechanical.

### Finishing a folder

Set the phase to `done` in both its frontmatter and the `tracking.md` row, append a dated line to the
log saying what was actually done, and when the last phase closes set the folder's `00_start.md` to
`done` and its `priority` back to `0`. `check` catches all four if one is forgotten.

Then stop. Do not merge the branch as the closing act: an effort ends with its last phase, and work
discovered in the meantime often belongs on that same branch. Merging is a person's decision, made when
they know nothing else is coming.

## Two conventions this carries

- **Plans are a diary; docs are the as-is.** Nothing outside `plans/` may cite a specific plan folder or
  a `Qn`/`Dn` id. When a comment, script or doc needs to lean on a decision, put the decision in the
  docs file whose topic it is and point there. `check --citations` enforces it. A decision with no
  obvious doc means a missing doc, not an exception.
- **A feature folder is worked on in `feat/<NN_name>`**, so the branch list sorts the way the plans do
  and a branch name answers what it is for with a folder to read.
