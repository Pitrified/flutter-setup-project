---
status: in progress
---

# Phase 02 - Check it on the workstation

## Overview

A skill is only known to load when a session has loaded it. This needs the workstation, since a cloud session does not install dotfiles yet (`24_cloud_sessions` phase 1).

## Plan

- Merge or check out the dotfiles branch, run the installer, and confirm `~/.claude/skills/tracked-development/scripts/plans.py` exists.
- With this repo's `.claude/skills/managing-plan-folders/` moved aside, ask a Claude Code session "what should I work on next" and check that `tracked-development` triggers and runs the script.
- Run `scripts/check.sh` and read the skew line from phase 03.

## Done when

- Both checks above are seen, and logged with the date.
