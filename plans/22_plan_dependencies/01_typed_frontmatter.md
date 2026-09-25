---
status: done
---

# Phase 01 - Frontmatter as a typed object

## Overview

Before a non-scalar field arrives, the frontmatter stops being a dict of strings that every caller pokes
at by key. One dataclass, built once, validating as it is built, so that "`priority` is a non-negative
integer" lives in one place instead of at each use.
Context: [`00_start.md`](00_start.md), "The frontmatter is growing".

No new field and no new rule in this phase: it is a refactor whose success condition is that nothing
changes.

## Goals

1. A `Frontmatter` dataclass with the four current keys as fields, and unknown keys kept as they are.
2. Validation in one place, raising the named error the checker already reports per file.
3. Identical output from `list` and `check` before and after.

## Plan

- `Frontmatter` with `status`, `priority`, `description` and `extra: dict[str, str]`, plus a classmethod
  that builds it from the `---` block and collects its own problems rather than raising on the first one.
  A file with two faults should report two.
- `priority` becomes an `int | None` at the boundary, so the "non-negative integer" rule is one parse
  rather than a string test at the point of use.
- `Folder` and `Phase` hold a `Frontmatter`, and `folder.status` / `folder.priority` keep working as
  properties so the checker's code is untouched.
- The unknown keys stay: 27 phase files carry `depends_on` and `produces` from an older convention, and
  the checker validates what it knows and ignores the rest.

## What the implementation found

- **`priority: 0` is falsy**, and the presence check was `not getattr(front, key)`, so every folder in the
  tree reported "no priority in frontmatter". Twenty-two findings from a refactor that was supposed to
  change nothing. `Frontmatter.missing()` now tests `priority_raw is None` and the comment says why.
- **The `pri` column broke** once the value was an int, because `print_table` measures with `len`. It
  formats at the boundary now.
- Both were caught by diffing the four captured outputs rather than by reading the code, which is the
  whole argument for capturing them first: a refactor whose success condition is "nothing changes" needs
  something to compare against, or it is just a rewrite nobody checked.

## Out of scope

- `depends_on` in any form (phase 02).
- Changing what any rule reports. A different message is a change to a gate's output, and this phase is
  supposed to be invisible.

## Done when

- `scripts/check.sh` green, and `list` output byte-identical to before the change (captured beforehand
  and diffed).
- The two broken copies of `plans/` from folder 21 phase 3 still produce the same thirteen findings, in
  the same words. That is the regression test, and it is a real one because it was built by breaking one
  rule at a time.
- A file with two faults reports two: `priority: -2` and no `description` gives two findings from one
  file. Corrected from "a malformed block and a missing description", which cannot both be reported: if
  the block does not parse there is no way to know whether `description` was there.
