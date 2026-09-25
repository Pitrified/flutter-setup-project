---
status: done
---

# Phase 5 - The failure paths, in the automated journey

## Overview

Phase 2 verified the 401 and malformed paths by hand, by restarting the mock in each mode. This makes
them part of the one journey, which was small enough to do immediately rather than to collect into a
separate effort. Context: [`00_start.md`](00_start.md), extends
[`03_feat_integration_tests.md`](03_feat_integration_tests.md).

## Goals

1. The test can put the mock into a scenario without the harness restarting it.
2. The 401 path and the malformed path are asserted in the journey.

## Plan

- `POST /_control {"scenario": "..."}` on the mock, validated against the scenario list, switching the
  default for subsequent requests.
- The test calls it over plain `HttpClient`, deriving the control URL from the same
  `OPENAI_BASE_URL` the app was built with, so it cannot drift to a different server.
- Two more stages in the journey: 401 shows the key message; a non-JSON 200 shows the
  not-in-the-expected-format line and **not** the model's prose.

## Out of scope

- `ratelimit` and `slow`. They exist in the mock and are useful by hand; neither has app behaviour
  that differs from the 401 path in a way a test would catch today.

## Done when

- `scripts/e2e.sh` is green with both failure stages in it.

## What the implementation found

Done 2026-09-25 in about half an hour, which is why it was not worth its own folder.

**The mock could not read the test's request body.** Dart's plain `HttpClient` sends a chunked body
with no `Content-Length`, and the handler read `Content-Length` only, so it saw an empty body and
rejected the scenario as `None`. `_read_body` now handles both framings. `openai_dart` always sent a
length, which is why this only showed up once something other than the app talked to the mock.

**The navigation assumption was wrong again**, the same way as in phase 3: Back from Settings returns
to the conversation it was opened from, not to the welcome screen. Two of the three test failures in
this effort were my assumptions about where the app goes, not the app going somewhere wrong.

The malformed stage asserts both halves: that the error line appears, and that the model's prose does
not. Asserting only the first would have passed before
[`../09_ui_tweaks/10_malformed_reply_display.md`](../09_ui_tweaks/10_malformed_reply_display.md) was
fixed, since the prose was the message.
