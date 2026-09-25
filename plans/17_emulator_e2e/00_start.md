---
status: done
priority: 0
description: |
  A headless emulator on this box plus a mock OpenAI server, so the three paths that
  flutter_test cannot reach are covered by an integration test that runs a whole journey against
  scripted replies.
---

# End-to-end on a headless emulator, with a mocked OpenAI endpoint

Status: bootstrap. The emulator is being installed as this is written; nothing in the app is changed
yet.

## Where this came from

Two things arriving together on 2026-09-25:

1. Phase 15 finished with three paths verified by reading rather than running: the cold-start language
   default, the chip's double write, and any real conversation in a non-Portuguese language. See
   [`../15_target_language/03_feat_language_ui.md`](../15_target_language/03_feat_language_ui.md)
   under "What is not covered by tests". `flutter_test` cannot reach them: a `testWidgets` body runs
   on a fake clock, so the Hive writes behind `startConversation` never complete inside it.
2. The ask: run an emulator on this box, and mock the endpoint rather than spend a real API key,
   "intercept the call as it exits the emulator and fire up a server which will answer with scripted
   responses in the correct protocol".

The emulator itself is a box-level concern and is planned in
`~/repos/plans/2026-09-25_00_install_android_emulator.md`. This folder is the repo half: what the app
and the test harness need in order to use it.

## Facts checked before choosing (2026-09-25)

- **The engine already has the seam.** `defaultOpenAIClientBuilder` in
  [`lib/services/inference/openai_inference_engine.dart`](../../lib/services/inference/openai_inference_engine.dart)
  calls `OpenAIClient.withApiKey(apiKey)`, and the package signature is
  `OpenAIClient.withApiKey(String apiKey, {String? baseUrl, ...})`
  (`openai_dart-6.0.0/lib/src/client/openai_client.dart:161`), defaulting to
  `https://api.openai.com/v1` on line 173. So pointing the app at a local server is a one-argument
  change, not a fork.
- `OpenAIConfig` also reads an `OPENAI_BASE_URL` environment variable
  (`.../client/config.dart:112`), which is useless on Android: there is no environment to set. A
  `--dart-define` is the equivalent that works.
- **`127.0.0.1` inside the emulator is the emulator.** The host is reachable at the QEMU alias
  `10.0.2.2`. The literal loopback the ask described works only with `adb reverse tcp:8080 tcp:8080`,
  which forwards a device port to the host, and that is worth having anyway because it survives a
  change of emulator networking and works identically on a real Pixel over USB.
- **Cleartext HTTP is blocked by default** on API 28+, and the app sets no
  `usesCleartextTraffic`. So `http://10.0.2.2:8080` fails until a debug-only manifest permits it.
  There is already an `android/app/src/debug/AndroidManifest.xml` (it exists to add the INTERNET
  permission for the tooling), which is the right place: release builds stay strict.
- **The AOSP image allows `adb root` and a writable `/system`**, so the hosts-file route is available.
  It is not the first choice, see D1.
- The engine constrains output with `response_format: json_schema` (strict) and streams via
  `createStream`, so the mock has to speak SSE: `data: {"choices":[{"delta":{"content":"..."}}]}`
  lines terminated by `data: [DONE]`.
- Driving the emulator needs no new tooling: `adb shell input tap/text/keyevent`,
  `adb shell uiautomator dump` to find a node rather than guess a pixel, and
  `adb exec-out screencap -p` for a screenshot. `integration_test` + `flutter drive` gives the same
  control in Dart, by widget finder rather than coordinate.

## Decisions

- **D1: intercept by base URL, not by hosts file.** A `--dart-define`d base URL pointed at a local
  server is one argument, needs no root, no CA, no TLS, and works the same on the Pixel. The hosts
  hijack (`adb root; adb remount; push /system/etc/hosts`) plus a CA trusted only in debug is the
  fallback if something ever bypasses the configured client, and is worth nothing extra until then:
  it would also mean serving TLS with a cert the app trusts, which is two more moving parts in the
  place where the test is supposed to be boring.
- **D2: the base URL is a build-time define, not a Settings field.** A visible "API endpoint" box in a
  shipped app is a phishing lever, and the value is a test fixture rather than a user preference.
  `--dart-define=OPENAI_BASE_URL=...`, read once, defaulting to empty (meaning the real API).
- **D3: cleartext stays debug-only**, granted through a network security config that permits exactly
  `10.0.2.2` and `127.0.0.1`, referenced from the debug manifest. No release manifest change.
- **D4: the mock is a small Python server in the repo**, run by hand or by the harness, with scripted
  scenarios chosen by a header or a path: a good reply per language, a malformed-JSON reply, a 401, a
  429, and a slow drip to exercise the streaming UI. Python because it is on the box and needs no
  build step.
- **D5: the mock does not validate the request against the JSON schema.** It answers with scripted
  text whatever it is asked. Ceiling, stated rather than discovered later: these tests prove the app
  handles a well-formed OpenAI response, not that our schema is one OpenAI accepts. Only a real call
  proves that, and that stays a manual check with a real key.

## Open questions

- Q1: what drives the emulator in the tests?
  a. `integration_test` + `flutter drive`: Dart, widget finders, runs in the app process.
  b. `adb shell input` plus `uiautomator dump`: language-agnostic, no app changes, brittle about
     coordinates and slower to write.
  Recommended: a, because the three untested paths are Flutter-level (a provider default, a double
  write, a rebuild) and finders name widgets rather than pixels. Keep b for the smoke check that the
  APK installs and launches at all, which needs no Dart.
  ANS: a. Note that b already paid for itself: phase 1 closed two of the three gaps by hand with
  `uiautomator dump`, before any Dart was written.
- Q2: how does the key get onto the emulator, given the engine refuses to call without one?
  a. The mock accepts any non-empty key, and the harness writes a dummy one into secure storage
     through the app's own Settings screen as a test step.
  b. A `--dart-define`d dummy key that the engine falls back to when storage is empty, debug only.
  Recommended: a, because it exercises the real key path (secure storage, the Settings field) instead
  of adding a debug-only bypass to the one part of the app that handles a secret.
  ANS: a.
- Q3: does the emulator harness run in CI later?
  a. No. Local only, run by hand or by an agent session on this box.
  b. Yes, wire it into `scripts/check.sh` or a separate CI job.
  Recommended: a for now. A KVM-accelerated emulator in GitHub Actions is slow and flaky, and
  `check.sh` must stay fast enough that nobody skips it. Revisit if the harness proves stable.
  ANS: a. `scripts/e2e.sh` stays a separate, slow command.
- Q4: how far should the mock go in imitating OpenAI?
  a. Minimal: the fields our engine reads (`choices[].delta.content`, `choices[].message.content`,
     and the error shapes for 401/429).
  b. A faithful subset, including `usage`, `finish_reason`, ids and timestamps.
  Recommended: a. Anything the app does not read is a fixture nobody validates. Add fields when the
  app starts reading them.
  ANS: a.

### Third batch, raised by watching phase 2 run (2026-09-25)

- Q5: on a malformed (non-JSON) reply, `ConversationController._resolveReply` shows the model's raw
  text to the learner as the tutor's message. On the emulator this read as the tutor suddenly writing
  English prose about JSON, with no error styling and no correction card.
  a. Keep it. Something is better than nothing, and it only happens when the model breaks its schema.
  b. Show it as a failed turn, the way an inference error already is, with a retry.
  c. Keep the text but mark it visually as unparsed.
  Recommended: b, because the current behaviour is indistinguishable from the tutor answering, and a
  learner cannot tell that the correction they did not get was lost rather than not needed. The
  scenario is now reproducible on demand (`--scenario malformed`), which is what makes it cheap to fix.
  ANS: b, and it belongs in the existing small-fixes folder rather than here:
  [`../09_ui_tweaks/10_malformed_reply_display.md`](../09_ui_tweaks/10_malformed_reply_display.md).
  Done there, minus the retry, which no failure has today. This folder's job was to make it
  reproducible and then to cover it.
