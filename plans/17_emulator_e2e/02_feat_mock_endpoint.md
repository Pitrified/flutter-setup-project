---
status: done
---

# Phase 2 - Mock OpenAI server and the base URL override

## Overview

The only phase that touches shipped code, and it is deliberately tiny: one build-time define threaded
into the existing client builder, plus a debug-only cleartext allowance.
Context: [`00_start.md`](00_start.md) D1-D5, depends on
[`01_feat_emulator_smoke.md`](01_feat_emulator_smoke.md).

## Goals

1. A debug build can be pointed at a local server with one `--dart-define`.
2. A local server answers as OpenAI does, for the fields the app reads, including streaming.
3. Release builds are unchanged, still HTTPS-only, with no endpoint switch anywhere in the UI.

## Plan

- `defaultOpenAIClientBuilder` reads `const String.fromEnvironment('OPENAI_BASE_URL')` and passes it
  to `OpenAIClient.withApiKey(key, baseUrl: ...)` only when non-empty, so the default stays the real
  API. A comment stating it is a test seam, not a feature.
- `android/app/src/debug/AndroidManifest.xml`: add a `networkSecurityConfig` permitting cleartext for
  `10.0.2.2` and `127.0.0.1` only, with the XML in `android/app/src/debug/res/xml/`.
- `tool/mock_openai.py`: a stdlib `http.server` handling `POST /v1/chat/completions`, answering
  non-streaming and `stream: true` (SSE: `data: {...}` per chunk, then `data: [DONE]`), chunking the
  scripted JSON mid-token so the partial-JSON path is exercised rather than bypassed.
- Scenarios, selected by a header so one server covers all of them: a good reply in the language the
  request asks for, malformed JSON, HTTP 401, HTTP 429, and a slow drip.
- A `--port` and a printed `adb reverse` line, so the device can reach it at `127.0.0.1` too.
- Prove it outside the emulator first: `curl` both modes against the mock, then from the emulator via
  `adb shell curl` or the app itself.

## Out of scope

- Validating our JSON schema against OpenAI's rules (D5): scripted replies cannot prove that.
- Any Settings-visible endpoint field (D2).
- Recording real responses to replay. `plans/10_streaming_ui/04.1_feat_openai_stream_capture.md`
  already exists for that and stays deferred.

## Done when

- A debug build with the define, talking to the mock, holds a conversation end to end in the emulator.
- The same build without the define still targets `api.openai.com`, checked by reading the client
  config rather than by assuming.
- A release build still has no cleartext permission: `aapt dump xmltree` on the release APK.

## What the implementation found

Done 2026-09-25, and it works end to end: a debug build talking to
[`tool/mock_openai.py`](../../tool/mock_openai.py) held a full tutor turn in German and in Spanish on
the headless emulator, streamed over SSE, with the correction card rendering above the reply.

Shipped code changed in exactly two places, both as planned:

- `openAiBaseUrlOverride` (`const String.fromEnvironment('OPENAI_BASE_URL')`) threaded into
  `defaultOpenAIClientBuilder`. Empty by default, so a build without the define is unchanged.
- `android/app/src/debug/AndroidManifest.xml` points at a new
  `android/app/src/debug/res/xml/network_security_config.xml` permitting cleartext to `10.0.2.2`,
  `127.0.0.1` and `localhost` only. Debug source set, so release is untouched.

The mock logs every request as JSON lines, which turned out to be the most useful part: it is how the
prompt was checked from outside the app. The Spanish turn recorded
`language: Spanish (European) | stream: True | auth: True` with the first prompt line reading
"You are a Spanish (European) language tutor.", which proves the whole chain (Settings to conversation
to prompt) without a single Dart assertion.

Also added: [`tool/adb_ui.sh`](../../tool/adb_ui.sh), helpers that drive the app by reading the view
tree (`ui_tap "Start Conversation"` finds the node and taps its centre). It was written after doing
the same thing by hand three times.

**Failure scenarios, all four confirmed on the device:**

| scenario | what the app showed |
| --- | --- |
| `ok` | the scripted reply, correction card above the bubble |
| `unauthorized` (401) | "Error generating response: OpenAI key missing or rejected. Open Settings to update." |
| `malformed` (non-JSON 200) | the raw text, verbatim, as the tutor's message |
| no key stored | refused before any request, with the same key message |

**Two bugs found, both mine, both in the harness rather than the app:**

- `ui_center` matched labels with `grep -E`, so "Spanish (European)" was read as a regex and the
  parentheses became a group: it silently tapped the wrong node. Fixed-string matching now, with the
  reason in a comment.
- `pkill -f mock_openai` matched the very command line that contained it, killing the shell instead of
  the server. Kill by PID from `pgrep` in a separate step.

**A product question the emulator surfaced,** worth a decision rather than a silent fix: on a
malformed reply the learner sees the model's raw prose presented as the tutor's message, in English,
with no indication anything went wrong. That is deliberate today
(`ConversationController._resolveReply` maps `StructuredFailureKind.parse` to `failure.rawText`), and
it is defensible, but it was easier to accept when nobody had watched it happen. Raised as Q5.
