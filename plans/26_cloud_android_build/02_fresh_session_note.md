---
status: done
---

# Phase 02 - Steps in the fresh-session note

## Overview

The steps from phase 01, written into "Fresh cloud session" in `docs/getting-started.md` of both repos, with the mirror script as `tool/maven-central-mirror.gradle` in each.

## Done when

- Both code blocks of the section, extracted from the doc and run unchanged with `bash -e` on a clean clone with an empty `HOME`, end with an APK built.

## What the implementation found

- Checked on 2026-09-26 on a clean clone of fala-language-tutor with `HOME` pointing at an empty directory, so no earlier install, SDK, Gradle cache or init script could help: both code blocks of the section, extracted from the doc and run with `bash -e`, installed Flutter, passed all gates, installed the SDK and built `app-debug.apk`. 5 min 57 s end to end, of which the Flutter part was about 2 min.
- The two repos carry the same section text and the same `tool/maven-central-mirror.gradle`; the check ran on the tutor's copy.
- The cold APK build was faster than in phase 1 (under 4 min against 341 s), with every Central request going to the mirror from the start rather than after a failed first build.
