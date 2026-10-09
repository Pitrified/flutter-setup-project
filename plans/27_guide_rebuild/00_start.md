---
status: draft
priority: 0
description: |
  Rebuild this repo into the Flutter guide now that the tutor lives in fala-language-tutor:
  drop the product, write a small working gallery app, and turn the docs into setup from zero
  (headless and for a person), a pattern index, and distribution approaches.
---

# Rebuild this repo into the guide

Draft spin-off, raised 2026-09-26. No phases derived.

## Where this came from

Phase 05 of `20_repo_split`, "Clean this repo into the guide", split out on the user's call: it is a feature of its own, larger than the rest of that folder, and its content should be agreed before it is built.
The reasoning it starts from is in that folder: the brainstorm in its `00_start.md` (2026-09-26), the answers to its Q5 and Q6, and the audit table `02.1_audit_table.md` with its "Gallery candidates" and "What the guide says that is not written yet" sections.

## What is settled already

From `20_repo_split/00_start.md`:

- **What the guide is** (brainstorm): setup from zero, headless and for a person; a working app with a gallery of the patterns other projects actually use, not all of them, since "a giant gallery will immediately go stale"; a pattern can be a link to the project that uses it rather than a copy; AI skills, guides and scaffolding; distribution information and approaches. This app is not distributed.
- **The on-device engine stays here** as a gallery pattern (Q5): `flutter_gemma`, the model download, the model check.
- **The app is a working gallery** (Q6): router and navigation, basic pages, some components, storage including secure storage.
- **Its own `applicationId`** (Q7), for example `com.pitrified.flutter_setup`, so it cannot replace the tutor on a phone.
- **No bootstrap script**: a session reads this repo and a plan and writes a new app, as fala-language-tutor was written.

## What is not settled

To be raised as questions when this is picked up. Starting points:

- Which tutor code stays as a gallery item, which goes and is linked from fala-language-tutor, and which goes entirely. The audit's `fala` rows are the list to judge; its `AppController` row was wrong (`20_repo_split/04_fala_repo.md`).
- The gallery's first screens, and what "used by another project" means while fala-language-tutor is the only other project.
- The shape of the docs: one getting-started for both audiences or two, and where the pattern index lives.
- The plan folders about the tutor that stay here as history: whether the guide's README says so, and how.
- How a session bootstrapping a new app is meant to use this repo, written down, since that is the guide's main reader.
