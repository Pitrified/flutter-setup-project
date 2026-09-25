# 10 - A malformed reply reads as a failed turn, not as the tutor talking

## The problem

`ConversationController._resolveReply` maps the two failure kinds differently:

| failure | what the learner sees |
| --- | --- |
| `StructuredFailureKind.inference` (network, key, timeout) | "Error generating response: ..." |
| `StructuredFailureKind.parse` (the model broke its own schema) | **the raw text, verbatim** |

So when the model answers with prose instead of JSON, the learner gets that prose presented as the
tutor's reply: English, mid-lesson, with no correction card and no sign that anything failed. It is
indistinguishable from the tutor simply answering, which means a learner cannot tell that the
correction they did not receive was lost rather than not needed.

It was deliberate ("parse failure -> the raw text": something beats nothing), and it survived review
because nobody had watched it happen. Watching it happen is what changed the assessment; it was found
on the emulator with `python3 tool/mock_openai.py --scenario malformed`, which is also the way to
reproduce it on demand.

## The change

In `_resolveReply`, treat a parse failure the way an inference failure is already treated: an
error-styled message rather than the model's text.

```dart
StructuredFailureKind.parse => (
    'Error generating response: the reply was not in the expected format.',
    null,
  ),
```

Keep `failure.rawText` reaching the logger, so the text is still recoverable when debugging. It is
the *display* that is wrong, not the capture.

## Deliberately not in this change

- **A retry button.** No failure has one today, including network errors. Adding retry is a change to
  how every failed turn behaves, not a fix to this one, so it belongs in its own item if it is wanted.
- **Distinct styling for failure messages.** Error turns currently render as ordinary tutor bubbles
  with error text. Making failures look like failures is worth doing and is worth doing once, for all
  of them, rather than here.

## Done when

- With the mock in `malformed` mode, the conversation shows the error line instead of the model's
  prose, checked on the emulator.
- A unit test on `_resolveReply` covers the parse branch, next to the existing coverage of the others.
- `scripts/check.sh` green.

## What the implementation found

Done 2026-09-25, and it is the one-line change the plan described plus a `warn` log, with the reason
in a doc comment on `_resolveReply` so the next reader does not "restore" the old behaviour.

The existing unit test was named `sendMessage handles parse failure with raw text` and asserted the
raw text *was* the reply. It now asserts the error line and explicitly that the garbled text is
absent, with a comment saying what it used to assert. That is the second test this week whose job
changed rather than whose bug was fixed, which is worth noticing: both were tests of a behaviour
nobody had watched.

Verified on the emulator, not just in unit tests: the journey in
[`../17_emulator_e2e/`](../17_emulator_e2e/tracking.md) now drives the mock into `malformed` mode and
asserts the failure line appears and the model's prose does not.

Still true, and still deliberate: a failed turn looks like an ordinary tutor bubble with error text,
and there is no retry. Both remain out of scope here.
