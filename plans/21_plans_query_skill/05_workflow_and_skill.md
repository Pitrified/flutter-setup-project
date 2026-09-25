---
status: planned
---

# Phase 5 - Folder-creation workflow, and the skill

## Overview

The two pieces that are only ever used through a conversation rather than through a gate: the
cross-branch numbering scan, and the rename that fixes a collision. Then the `SKILL.md` that drives all
of it, written last because a skill written before its scripts exist documents a guess.
Context: [`00_start.md`](00_start.md), "Numbering across branches" and "Portability".
Depends on [`01_parser_and_queries.md`](01_parser_and_queries.md) for the parser.

## Goals

1. Spinning off a folder can check that its number is free across every branch, not just this tree.
2. A collision is fixed mechanically, with the new number chosen by a person.
3. A skill an assistant can follow cold: which script answers which question, and with which arguments.

## Plan

- `scripts/plans.py branches`: read refs rather than the working tree, with no checkout:
  `git for-each-ref refs/heads refs/remotes` then `git ls-tree -d --name-only <ref> plans/`. Each number
  maps to a set of names; more than one name behind a number is a collision, the same name on five refs
  is a branch that has not merged. Behind a flag, not on every run (Q10): a gate that fails because of
  someone else's unmerged branch is a gate that gets skipped.
- `python3 scripts/plans.py rename <old> <new>`: `git mv`, then rewrite `../NN_name/` links between plan folders,
  then print a summary of what changed. It refuses to run while `--no-citations` reports anything, rather
  than editing code to keep a diary reference alive (Q11). It does not choose the number: two people
  renaming into the same free slot reproduce the collision one number along, so the target is an argument
  and the skill asks a person, listing which numbers are taken and on which refs.
- `SKILL.md`, per the published authoring guidance: name and a description naming its triggers (plan
  folders, phase status, what to work on next, priority); a body under 500 lines; the frontmatter schema
  and status enum in one reference file one level deep rather than inline; exact commands for the
  deterministic parts and judgement left free for choosing which query answers the question.
- The skill states the two conventions that belong to it rather than to this repo: plans are a diary and
  nothing outside `plans/` cites one, and a feature folder is worked on in `feat/<NN_feat_name>`.

## Out of scope

- Moving the skill to dotfiles (Q3): it is used here first. The scripts stay in this repo either way
  (Q8), and the skill calls what it finds in the repo it is pointed at.
- Writing the diary rule into `tracked-development` (Q14, deferred). It lives in
  `.github/copilot-instructions.md` and `docs/git-workflow.md` for now.

## Done when

- `--branches` runs over this repo's refs and reports no collision, matching the result recorded in
  `00_start.md`.
- The rename is demonstrated both ways on a scratch clone: a real collision renamed with its inbound
  links fixed, and a refusal while a citation still exists.
- The skill is invoked once end to end on a question nobody has scripted an answer to, such as "what is
  next by priority and what does it depend on", and answers it without the transcript needing a
  correction.
