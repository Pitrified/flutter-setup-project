---
status: planned
---

# Phase 04 - Delete this repo's copy of the skill

## Overview

Q4 a. Waits for two things: phase 02 has seen the dotfiles skill trigger, and `24_cloud_sessions` phase 1 installs dotfiles skills in cloud sessions. Before both, deleting it leaves a session with no plan-folder skill.

## Plan

- Delete `.claude/skills/managing-plan-folders/`.
- Check `.github/copilot-instructions.md` and `docs/` for any mention of the old skill name, and point them at `tracked-development`.

## Done when

- The folder is gone, `scripts/check.sh` passes, and a cloud session started after the deletion has `tracked-development` loaded.
