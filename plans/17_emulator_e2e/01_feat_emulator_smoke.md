---
status: done
---

# Phase 1 - Emulator smoke: install, launch, screenshot

## Overview

Prove the emulator runs this app before changing any app code, so a later failure is attributable.
No Dart, no mock, no test framework. Context: [`00_start.md`](00_start.md).

## Goals

1. The AVD boots headless and `flutter devices` lists it.
2. The x86_64 release APK installs and the app reaches the welcome screen.
3. A screenshot comes back, and `adb logcat` shows no fatal Flutter error.

## Plan

- Boot with the flags from the box note: `-no-window -gpu swiftshader_indirect -no-audio
  -no-boot-anim -no-snapshot-save`, and wait on `sys.boot_completed` rather than a sleep.
- `flutter build apk --debug --target-platform android-x64` (debug, because phase 2 needs the debug
  manifest and `--dart-define`; the release split APK is a second check, not the main path).
- `adb install -r`, launch with `adb shell monkey -p com.fala.app 1` or an explicit `am start`.
- `adb exec-out screencap -p > scratch/shot.png`, and `adb shell uiautomator dump` to confirm the
  welcome text is in the view tree rather than trusting the pixels.
- Record boot time and install time in the log, once, as an order of magnitude.

## Out of scope

- Any conversation: without a key or a mock the engine refuses, which is phase 2.
- The on-device engine. It would try to download a 614 MB model into an emulator, for an engine that
  is on its way out ([`../16_cloud_first_engine/00_start.md`](../16_cloud_first_engine/00_start.md)).

## Done when

- A screenshot of the welcome screen exists, and the view tree contains the app's own text.
- The commands that got there are written down in this file, copy-pasteable.

## What the implementation found

Done 2026-09-25. The emulator runs this app, and it went further than the phase asked: it executed
two of the three paths `15_target_language` could only verify by reading.

The commands, in order:

```bash
export ANDROID_HOME="$HOME/android-sdk"
export PATH="$HOME/android-sdk/platform-tools:$HOME/flutter/bin:$PATH"

$ANDROID_HOME/emulator/emulator -avd fala_api36 \
  -no-window -gpu swiftshader_indirect -no-audio -no-boot-anim -no-snapshot-save &
adb wait-for-device
until [ "$(adb shell getprop sys.boot_completed | tr -d '\r')" = "1" ]; do sleep 5; done

flutter build apk --debug --target-platform android-x64      # ~229 s, 130 MB
adb install -r build/app/outputs/flutter-apk/app-debug.apk   # Success
adb shell am start -n com.fala.app/.MainActivity             # Fully drawn +5.3 s

adb exec-out screencap -p > shot.png
adb shell uiautomator dump /sdcard/u.xml && adb shell cat /sdcard/u.xml
```

**Read the tree, not the pixels.** Flutter widgets surface as `content-desc`, not `text`, so a
`grep 'text='` finds almost nothing while `content-desc` lists the whole UI. Tapping works by taking
a node's `bounds` and tapping its centre, which is stable across a font or layout change in a way
that a hardcoded coordinate is not.

**A cold boot shows "System UI isn't responding" before the app is reachable.** It is the emulator's
system_server being slow on a software GPU, not our app: logcat said `Fully drawn` while the ANR
dialog was still on top. `uiautomator dump` returns the topmost window, so the dialog is all you see
until it is dismissed (tap "Wait"). Worth knowing before concluding the app is broken. A saved
snapshot would avoid it, at the cost the box note explains.

**Phase-15 gaps closed here, by hand:**

1. *Cold-start default.* Settings to Spanish, `am force-stop`, relaunch: the welcome screen read
   "Learn Spanish by speaking", and a new conversation showed the `español` chip, "Say something in
   Spanish!" and "Type in Spanish...". This is the path whose unit test hung on the fake clock, and
   whose bug (the screen not passing `language`) was caught in diff review.
2. *The chip's double write.* With messages in the conversation (sending with no key stored appends
   the user message and an error reply, which is a free way to get a non-empty conversation), picking
   German offered "Start over in German?". Declining kept the Spanish conversation and its history,
   **and** left the Settings default on German. Both writes, as designed.

Not done: a real tutor turn, which needs the mock (phase 2). The engine correctly refused with
"OpenAI key missing or rejected".
