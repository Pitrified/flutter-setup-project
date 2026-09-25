---
status: done
---

# Phase 3 - Integration tests for what unit tests could not reach

## Overview

Execute the three paths phase 15 left verified-by-reading. Draft until Q1 and Q2 are answered, since
they decide the driver and how the key gets there. Context: [`00_start.md`](00_start.md), depends on
[`02_feat_mock_endpoint.md`](02_feat_mock_endpoint.md).

## Goals

1. The cold-start default: a conversation opened with no prior conversation uses the stored language.
2. The chip's double write: picking a language updates both the conversation and the app default.
3. A full turn in a non-Portuguese language, against the mock, with the reply rendered.

## Plan

- Add `integration_test` as a dev dependency and `integration_test/app_test.dart`.
- Test 1: set the default through the Settings screen, restart the app, assert the conversation's
  language by what the UI says (the hint text names the language).
- Test 2: pick a language from the chip on a conversation with messages, confirm the dialog, assert the
  new conversation is in that language and that reopening Settings shows the new default.
- Test 3: a turn against the mock, asserting the reply bubble renders the scripted content and the
  correction card appears above it (the ordering phase 10 settled).
- Also assert the prompt the mock received names the right language. The mock can log the request body
  for the test to read, which checks the wiring the widget tests cannot see.
- Failure scenarios from phase 2 as two more tests: 401 shows the key message, malformed JSON shows the
  parse failure rather than a crash.

## Out of scope

- The on-device engine.
- Running in CI (Q3).
- Screenshot comparison. Golden images on a software GPU are a fight worth avoiding.

## Done when

- The three gaps named in `15_target_language/03_feat_language_ui.md` are covered by tests that run.
- That file's "What is not covered by tests" is updated to say where they now live.

## What the implementation found

Done 2026-09-25. `integration_test/app_test.dart` runs the real app against the mock and passes in
about 27 seconds.

**It is one test, not four.** Written first as four (key, language, turn, switch), which failed in two
ways that are worth recording because both look like app bugs and are not:

- Calling `app.main()` at the start of each test starts a **second app over the first**. The old
  tree's controllers keep streaming into widgets the finders no longer reach, and an exception from
  the previous test surfaces during the next one. One `main()` and one ordered journey holds.
- Waiting for `find.text('fala')` and then tapping "Start Conversation" is a race: "fala" is the title
  of both the welcome screen and the conversation app bar, and it renders while the app is still
  deciding whether the engine is ready. Wait for the control you are about to tap, not for a title.

**`pumpAndSettle` cannot be used on the conversation screen.** The typing indicator ticks while a
reply streams, so the frame queue never empties. The `waitFor` helper polls with fixed pumps instead.

**A third assumption was wrong, and the app was right:** the test expected a restarted app to still
hold the previous conversation, so that switching language would prompt. It does not: the controller
has no current conversation after a restart, so the screen starts a fresh empty one, and an empty
conversation switches in place with no prompt. The test now sends a turn first.

**The run found a real bug in the prompt.** The mock's request log showed the app sending
*"You are a Italian language tutor"*: the template hardcoded the article, which is wrong for every
vowel-initial language (Italian, and English when it arrives). `v3.txt` now reads
"You are a language tutor for {{target_language}}.", which needs no article at all. The mock's regex
and the unit test moved with it. A language-teaching prompt with a grammar error in its first line is
exactly the kind of thing that only shows up when you read what actually went over the wire.

Not covered here: the 401 and malformed scenarios, which were verified by hand in phase 2 but are not
in the automated journey, because each needs the mock restarted in a different mode. The hook exists
(`X-Mock-Scenario`), and adding them means teaching the test to set a header per turn.
