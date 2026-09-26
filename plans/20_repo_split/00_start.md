---
status: planned
priority: 1
description: |
  Split fala out into its own repo, fala-language-tutor, written fresh by a Claude session
  from a plan, with only what the tutor needs and no local LLM. This repo becomes the Flutter
  guide: setup from zero, a working app with the patterns other projects actually use,
  skills, scaffolding, and distribution approaches. An audit decides what goes where.
---

# Split the skeleton from the app

Raised 2026-09-25 as a draft; brainstormed 2026-09-26 and phases derived, see [`tracking.md`](tracking.md).

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

## Brainstorm, 2026-09-26

The user's framing, condensed; "the audit will guide scope decisions" covers all of it.

- **Three stages.** An audit, the split-off of the new repo, the clean-up of this one.
- **This repo becomes a guide.** How to set up Flutter from zero, both headless and for a person.
  A working app with a gallery of useful patterns, but not all of them: "a giant gallery will immediately go stale".
  Only what is actually used in other projects is lifted here, and a pattern can be a link to the project using it rather than a copy.
  Plus useful AI skills, guides and scaffolding, and distribution information and approaches. This app will not be distributed.
- **The new repo is `fala-language-tutor`.** The minimal set of things that keeps the tutor running. No local LLM.
- **No bootstrap script.** A Claude session is pointed at a new empty repo with a plan, reads this repo and whatever else it needs, and writes all the code.
  That is how fala-language-tutor gets built.
- **The LLM testing machinery is duplicated for now**: the mock OpenAI server and the emulator end-to-end harness go into both repos.
  At the third copy of the pattern, in a second new app, it gets assessed. The expectation is that something suitable exists online; if not, it becomes its own package and repo in the Python stack, not a feature here.
- **Environment.** Work happens in the current cloud environment, set up by hand, for the next couple of days.
  Until the setup script exists, both repos carry a brief note in their docs saying what to install in a fresh session.

### What this settles, and what it does not

- The cheaper alternatives above are not taken: this is a split, with the guide staying here under its current name and the product leaving.
  Alternative 3, extracting a package, is the stance for the LLM testing machinery at its third copy, not for now.
- **Order.** fala-language-tutor is written while this repo still holds the full working tutor, since that is what the session reads.
  The clean-up of this repo comes after fala-language-tutor runs, not before.
- **Git history.** fala-language-tutor starts with no history: it is written fresh, not extracted. This repo keeps its own. That answers Q2.
- **What "used in other projects" means today.** After the split, fala-language-tutor is the other project, so a pattern it uses qualifies. The audit is where each one is judged.
- **Interplay with other folders.**
  `16_cloud_first_engine` removes the on-device engine from this repo; with the split it is superseded: fala-language-tutor never has the engine, and the guide keeps it as a gallery pattern (Q5).
  `23_dependency_upgrades` depends on this folder, as it already records.
  `24_cloud_sessions` replaces the fresh-session note with a setup script later.
  `07_release`, `13_key_distribution`, `14_audio_io` and `19_apk_distribution` are about the product and follow it (Q3).

## Open questions

- Q1: is there a second project that wants the skeleton, or is this tidiness?
  Recommended: answer honestly before doing anything. Tidiness is a reason to rename, not to split.
  ANS: from the brainstorm: not tidiness. This repo becomes the guide a Claude session reads when bootstrapping a new app, and fala-language-tutor is the first one built that way.
- Q2: if it splits, does the skeleton repo keep history?
  Recommended: no. A fresh repo with a pointer costs an afternoon; a filtered history costs days and
  is read by nobody.
  ANS: from the brainstorm, reframed: the skeleton stays here with its history, and fala-language-tutor starts fresh because a session writes it rather than extracting it.
- Q3: what happens to `plans/`?
  Recommended: plans follow their code, and the folders that span both are copied to both, marked as
  such. Reasoning is cheap to duplicate and expensive to lose.
  ANS: decided per folder by the audit (phase 02).

### Second batch (2026-09-26)

- Q4: who creates `fala-language-tutor` on GitHub, and when?
  A session can only push to repos in the Claude GitHub App installation, which is set to selected repositories (`24_cloud_sessions/00_start.md`, "GitHub access").
  Recommended: the user creates it empty and adds it to the installation before phase 03 starts.
  ANS: done by the user on 2026-09-26: https://github.com/Pitrified/fala-language-tutor, added to the app.
- Q5: `16_cloud_first_engine` removes the on-device engine from this repo. With the split, is it superseded?
  a. superseded: fala-language-tutor is written without it, and the guide's clean-up drops `flutter_gemma` unless the audit finds another use.
  b. kept, and done here before the split, so the session writing fala-language-tutor reads a smaller repo.
  Recommended: a. b removes code from a repo that is about to lose it anyway, and the plan for fala-language-tutor can simply say "no local LLM".
  ANS: a, superseded, with one change to the recommendation: removed in fala-language-tutor, kept in the guide. The on-device engine is a gallery pattern here, not a `drop`.
- Q6: what is "the working app" in the guide after the clean-up?
  a. a neutral demo shell whose screens are the lifted patterns.
  b. a stripped chat over `FakeInferenceEngine`, keeping the streaming and structured-output path as the demonstration.
  Recommended: decide after the audit. b keeps the patterns fala-language-tutor uses runnable here, but it is a second copy of the product's shape.
  ANS: a working app whose screens are the gallery: the router and navigation, basic pages, some components, secure storage or whatever storage applies, and so on. Closest to a; the audit lists the items.
