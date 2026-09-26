---
status: planned
---

# Phase 01 - Fresh-session note in this repo

## Overview

For the next few days work happens in one cloud environment set up by hand, and a new session starts without Flutter.
Until `24_cloud_sessions` provides a setup script, a short note in the docs says what to install. fala-language-tutor gets the same note when it is created (phase 03).

## Goals

1. A section in `docs/getting-started.md` for a fresh cloud session: install Flutter at the version CI pins, put it on `PATH`, fetch packages, run `scripts/check.sh`.
2. It reads the Flutter version from `.github/workflows/checks.yml` rather than repeating it, so the pin stays in one place.

## Out of scope

- The setup script and the environment itself (`24_cloud_sessions`).
- The Android SDK: no APK is built in the cloud yet.

## Done when

- The commands in the note, pasted into a shell on a container without Flutter, end with `scripts/check.sh` passing. This session installed Flutter that way on 2026-09-25, so the note is a transcription of a run that worked, re-run once to check.
