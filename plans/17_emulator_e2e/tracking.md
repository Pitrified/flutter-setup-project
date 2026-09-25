# implementation tracking

Run the app end to end on a headless emulator on this box, against a local server that answers as
OpenAI would, so the paths phase 15 could not test get executed and no real API key or device is
needed. Facts, options and decisions in [`00_start.md`](00_start.md).

## Key decisions

- Intercept by base URL (`--dart-define=OPENAI_BASE_URL`), not by hosts file or a proxy CA (D1, D2).
- Cleartext HTTP permitted for `10.0.2.2` and `127.0.0.1` in **debug builds only** (D3).
- The mock is a small Python server with scripted scenarios, including the failure ones (D4).
- The mock does not validate our JSON schema, so schema conformance still needs one real call (D5).
- The emulator install itself is box-level: `~/repos/plans/2026-09-25_00_install_android_emulator.md`.

## Phases

| #  | Phase                                  | Plan                                                          | Status  |
| -- | -------------------------------------- | ------------------------------------------------------------- | ------- |
| 1  | Emulator smoke: install, launch, shoot | [`01_feat_emulator_smoke.md`](01_feat_emulator_smoke.md)       | done |
| 2  | Mock OpenAI server + base URL override | [`02_feat_mock_endpoint.md`](02_feat_mock_endpoint.md)         | done |
| 3  | Integration tests for the gaps         | [`03_feat_integration_tests.md`](03_feat_integration_tests.md) | done |
| 4  | One-command harness                    | [`04_feat_harness_script.md`](04_feat_harness_script.md)       | done |
| 5  | Failure paths in the journey           | [`05_feat_failure_scenarios.md`](05_feat_failure_scenarios.md) | done |

Status values: draft / planned / in progress / done / superseded / discarded.

Sequencing rationale: phase 1 proves the emulator runs this APK at all, with no app changes, so a
failure there is the emulator's and not ours. Phase 2 is the only phase that touches shipped code, and
it is one argument plus a debug manifest. Phase 3 is where the phase-15 gaps actually get executed.
Phase 4 only earns its place once the pieces work by hand.

## Log

Append-only. Newest at the bottom.

- 2026-09-25 : bootstrapped from the ask to mock the endpoint, alongside the box-level emulator
  install. Checked first: `OpenAIClient.withApiKey` takes a `baseUrl`
  (`openai_dart-6.0.0/lib/src/client/openai_client.dart:161`), our `defaultOpenAIClientBuilder` is the
  seam, cleartext HTTP is blocked by default on API 28+ and a debug manifest already exists, and
  `127.0.0.1` in the emulator is the emulator so the host is `10.0.2.2` (or `adb reverse`). Four
  phases drafted, Q1-Q4 open.
- 2026-09-25 : emulator installed (box note `2026-09-25_00`), AVD `fala_api36` booted headless, and
  phase 1 **done**. Debug x86_64 APK built (229 s), installed, launched, screenshotted. Two of the
  three phase-15 gaps were executed by hand on the emulator and both behave as designed: the
  cold-start language default, and the chip's double write including the "Start over in German?"
  confirmation and its decline path. Learned: Flutter surfaces as `content-desc` rather than `text` in
  `uiautomator dump`, and a cold boot puts a "System UI isn't responding" dialog on top for a while.
- 2026-09-25 : Q1-Q4 answered as recommended (integration_test as the driver, the key typed into the
  real Settings field, no CI, a minimal mock). Phase 2 **done**: `OPENAI_BASE_URL` define, debug-only
  cleartext config, `tool/mock_openai.py` with five scenarios and a JSON-lines request log, and
  `tool/adb_ui.sh` for driving the UI by view tree. Full turns verified on the emulator in German and
  Spanish, plus the 401, malformed and no-key paths. The request log proves the prompt named the right
  language. Two harness bugs of my own fixed (regex-vs-fixed-string label matching, and a `pkill`
  pattern that killed its own shell). New Q5 raised: a malformed reply is shown to the learner as if
  the tutor had written it.
- 2026-09-25 : phases 3 and 4 **done**. `integration_test/app_test.dart` is one ordered journey (key,
  language, a turn, a declined switch) passing in ~27 s, and `scripts/e2e.sh` runs the whole thing with
  one command. Three test assumptions were wrong before it held: `app.main()` per test stacks a second
  app over the first; "fala" titles both screens so waiting on it races the button; and a restarted app
  opens a *fresh* conversation, so there is nothing to confirm switching away from. **The run found a
  real prompt bug**: the app was sending "You are a Italian language tutor", since the template
  hardcoded the article. `v3.txt` now says "You are a language tutor for {{target_language}}."
  Fast gates green: 167 tests, analyze clean.
- 2026-09-25 : effort complete. All three paths `15_target_language` could not test are now executed
  automatically.
- 2026-09-25 : Q5 answered (b) and done in the small-fixes folder as
  [`../09_ui_tweaks/10_malformed_reply_display.md`](../09_ui_tweaks/10_malformed_reply_display.md): a
  parse failure now reads as a failed turn instead of the model's prose, with the raw text going to the
  log. Phase 5 **done** alongside it: the mock gained `POST /_control` so the test can switch scenario
  at runtime, and the journey now asserts the 401 line and the malformed line (and that the prose is
  absent). Fixing the mock to read Dart's chunked request body was the only surprise. Journey ~36 s,
  fast gates green at 167 tests.
