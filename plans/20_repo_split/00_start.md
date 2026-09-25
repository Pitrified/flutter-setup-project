---
status: draft
priority: 0
---

# Split the skeleton from the app

Status: draft spin-off, raised 2026-09-25. No phases derived.

## Where this came from

The ask: "a feature to split in two repos, the flutter setup goes back to a skeleton setup with a
gallery of useful patterns, the real fala keeps only the minimal subset."

## Why the repo is like this

It is named `flutter-setup-project` and it holds `fala`. The repo began as a scaffolding exercise
(phases 02-03 produced documentation and structure before any product code) and a product grew inside
it. Both halves are now real:

- **Skeleton and patterns**: the docs set (project structure, coding standards, AI playbook, system
  spec template), the plan-folder conventions, the gates, the mock server and emulator harness, the
  streaming and structured-output machinery, the settings/provider patterns.
- **Product**: the tutor itself, its prompts, its screens, its store listing and privacy policy.

The split is attractive because the first half is what gets reused on the next project, and the
second half is what nobody else should inherit.

## The hard parts, named early

- **Git history.** A clean split means deciding whether the skeleton repo keeps history (`git filter-repo`
  on a subset of paths) or starts fresh with a note pointing back. Keeping history is more faithful and
  much more work.
- **The plans folder is the shared thing.** Eighteen phase folders, some pure skeleton (02, 03, 12,
  17), some pure product (08, 09, 13, 14, 15), some both. Splitting them is a judgement call per
  folder, and the losing side loses the reasoning that explains its own code.
- **What is actually generic** is smaller than it looks. `InferenceEngine`, the structured-output
  parser and the streaming layer are generic. The prompt manager is nearly generic. The conversation
  controller is not.
- **Two repos means two maintenance streams**, and this is a one-person project. A gallery repo nobody
  updates is worse than a messy single repo.

## Cheaper alternatives, to rule out first

1. Rename this repo to `fala` and extract only the genuinely reusable bits later, when a second
   project actually needs them. Reuse pressure is the honest trigger.
2. Keep one repo, add a `gallery/` or `patterns/` folder that documents the reusable pieces in place.
3. Extract the parts that are already libraries (the inference interface, the partial JSON parser)
   into a package, and leave the docs where they are.

## Open questions

- Q1: is there a second project that wants the skeleton, or is this tidiness?
  Recommended: answer honestly before doing anything. Tidiness is a reason to rename, not to split.
  NEW_ANS:
- Q2: if it splits, does the skeleton repo keep history?
  Recommended: no. A fresh repo with a pointer costs an afternoon; a filtered history costs days and
  is read by nobody.
  NEW_ANS:
- Q3: what happens to `plans/`?
  Recommended: plans follow their code, and the folders that span both are copied to both, marked as
  such. Reasoning is cheap to duplicate and expensive to lose.
  NEW_ANS:
