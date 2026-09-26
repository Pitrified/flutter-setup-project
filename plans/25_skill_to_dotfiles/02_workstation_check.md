---
status: done
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

## What the implementation found

Run on the workstation on 2026-09-26, from a session started on this branch after commit `4a57daa`, with dotfiles on `feat/tracked_development_uplift` and the installer run. The session was read-only and left `git status` clean.

- **Loaded:** `tracked-development` from `~/.claude/skills/tracked-development`, a symlink into dotfiles. `managing-plan-folders` was not in the skill list.
- **Ran the script:** asked "what should I work on next" and told to use whatever skill applied, it chose `tracked-development`, read `SKILL.md` and `reference/plans-script.md`, and ran this repo's `scripts/plans.py list`, which is the copy the reference says to prefer.
- **Not shown:** that the skill triggers unprompted. The prompt told the session to pick a skill, and the session said so itself.
- **Skew:** the two copies compare equal and both print `plans.py 1.0.0`; `check.sh` ended `all gates passed` with no note.
- **Conventions:** it answered the spin-off, cross-branch link, reopened-decision and no-script cases from the skill's text, quoting it.
- **One gap in the skill, fixed:** it did not say which branch a spin-off's first commit goes on. Dotfiles `5f90cbf` adds that it is the spin-off's own `feat/<NN_name>`, cut from the default branch.
- **One doc bug, fixed:** the repo instructions said every phase folder owns a `tracking.md`; drafts do not, and `check` agrees with the skill. The line now says so.
- **One false positive in its answer:** it called `09_ui_tweaks` status drift (`in progress`, 9/9 phases done). That folder's log says it stays open until item 08 gets a sub-plan, so the status is deliberate. Read from the listing alone, it looks wrong; the log is what settles it.
- **Known and kept:** the diary and planning sections exist both in the repo instructions and in the skill. Copilot reads only the repo file, which is why the inventory in `00_start.md` keeps them there. They can drift; nothing checks that.
