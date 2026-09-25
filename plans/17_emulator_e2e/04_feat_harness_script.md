---
status: done
---

# Phase 4 - One command to run it all

## Overview

Wrap what phases 1 to 3 established into a single script, once it works by hand. Draft on purpose: a
harness written before the pieces work hides which piece broke.
Context: [`00_start.md`](00_start.md).

## Goals

1. One command boots the emulator, starts the mock, runs the integration tests, and tears down.
2. It is honest about failure: the exit code is the tests', not the script's last command.

## Plan

- `scripts/e2e.sh`: boot the AVD if not running, wait on `sys.boot_completed`, start the mock on a
  free port, `adb reverse`, `flutter drive` with the define, then kill the mock and optionally the
  emulator.
- Keep it out of `scripts/check.sh` per Q3: minutes, not seconds.
- Leave logs and screenshots in the scratch directory, named by test, since a headless failure is
  otherwise invisible.

## Out of scope

- Parallel emulators, device matrices, CI.

## Done when

- One command, from a clean box state, produces a pass or a named failure.
- The gates section of `docs/getting-started.md` mentions it as the slow path next to `check.sh`.

## What the implementation found

Done 2026-09-25. `scripts/e2e.sh` boots the AVD if it is not already up, waits on
`sys.boot_completed`, starts the mock, wires `adb reverse`, runs the journey, and cleans up. It exits
with the test's status (`${PIPESTATUS[0]}`, not tee's), and leaves `build/e2e/` holding `test.log`,
`mock.log`, `emulator.log` and `requests.jsonl`.

`--stop-emulator` shuts the emulator down afterwards, and only when the script booted it: killing an
emulator someone else was using is a rude default.

The cleanup kills the mock **by PID**, with a comment saying why. `pkill -f mock_openai` matches the
command line that started it, so it kills the script instead of the server. That mistake cost three
runs during this work, which is why the comment is in the file rather than in a plan.

Left out of `scripts/check.sh` per Q3: this takes minutes and needs an emulator.
