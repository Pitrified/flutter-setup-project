---
status: in progress
---

# Phase 04 - Write fala-language-tutor

## Overview

Done in this session rather than a fresh one, on the user's call: the plan was written into the new repo first as if for a fresh session, then carried out here. The plan and its log are in fala-language-tutor, `plans/01_bootstrap/`.

## Sketch

- The repo exists and is in the Claude GitHub App installation (Q4).
- The plan for it is written from the audit's `fala` and `both` rows and lives in the new repo as its first plan folder, so the session that builds it finds it there.
- Its plan folders are numbered from 01; the product folders that move (07, 09, 13, 14, 19) are renumbered there (Q8).
- Minimal set to keep the tutor running, cloud engine only, the mock OpenAI server and the e2e harness copied in, gates and CI from day one, and the fresh-session note from phase 01.
- Done when its own gates pass in CI and the tutor runs on the Pixel.

## What the implementation found

- **The audit was wrong about `AppController`.** It was marked `guide` as on-device startup, but it initializes whichever engine is selected, and the welcome screen and router depend on its state. fala-language-tutor keeps it without the model check; the audit table here is left as written, and this is the correction.
- **The format gate had a hole**, found because the new repo had nothing tracked yet: it saw only tracked files, so a new file escaped it until committed. Fixed in both repos to include untracked files that are not ignored.
- **Result in fala-language-tutor, branch `feat/01_bootstrap`:** the baseline copied from `db87b69`, the on-device engine removed (829 lines out, 166 tests), docs rewritten, the open product folders renumbered 02 to 07. Gates pass in the tree and in a clean clone. The privacy policy there changed and its hosted copy needs updating before a release.
- **CI:** run 1 on fala-language-tutor, `feat/01_bootstrap` at `1446ada`, succeeded.
- **Not done yet:** the branch is not merged into that repo's `main`, and the tutor has not been run on the Pixel.
