---
status: draft
---

# Phase 03 - Write fala-language-tutor

## Overview

A fresh session, pointed at the new empty repo, reads a plan and this repo and writes the tutor. Shape only until the audit reports.

## Sketch

- The repo exists and is in the Claude GitHub App installation (Q4).
- The plan for it is written from the audit's `fala` and `both` rows and lives in the new repo as its first plan folder, so the session that builds it finds it there.
- Minimal set to keep the tutor running, cloud engine only, the mock OpenAI server and the e2e harness copied in, gates and CI from day one, and the fresh-session note from phase 01.
- Done when its own gates pass in CI and the tutor runs on the Pixel.
