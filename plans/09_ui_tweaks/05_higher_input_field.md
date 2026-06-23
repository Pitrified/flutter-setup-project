# 05 - Higher, wrapping input field

Part of phase 09 (UI tweaks and small functionality). Lets a long user
message wrap onto multiple lines and grows the input box up to a cap.

## Goal

After this change:

- A long message wraps onto multiple lines inside the input field instead of
  scrolling horizontally on one line.
- The field starts at one line and grows as the user types, up to a maximum
  of 5 visible lines; beyond that it scrolls internally.
- The send button and submit behaviour are unchanged.

## Non-goals

- No newline-on-Enter editing: Enter still submits (see decision below).
- No auto-resize of the surrounding layout beyond the field itself.
- No draft persistence across navigation.

## Files touched

Modified:

- `lib/screens/conversation/conversation_screen.dart`
  - In `_buildInputBar`, the `TextField` (currently single-line) gains:
    - `minLines: 1`
    - `maxLines: 5`
    - `keyboardType: TextInputType.multiline`
    - `textCapitalization: TextCapitalization.sentences` (optional, matches a
      chat field; skip if it changes existing behaviour unexpectedly).
  - Keep `textInputAction: TextInputAction.send` and the existing
    `onSubmitted: (_) => _sendMessage()` so Enter continues to send. The
    `const InputDecoration` stays as-is; `contentPadding` already suits a
    growing field.
  - The `Row` keeps `crossAxisAlignment` at its default (`center`). If the
    growing field makes the send button look misaligned at >1 line, set the
    `Row`'s `crossAxisAlignment: CrossAxisAlignment.end` so the button hugs
    the bottom of the field.

## Decision: Enter vs. newline

`maxLines: 5` with `keyboardType: TextInputType.multiline` normally makes the
soft keyboard show a return key that inserts a newline. We keep
`textInputAction: TextInputAction.send`, so:

- Wrapping for long text is automatic (the field grows as lines fill).
- Pressing the action key submits, preserving today's behaviour.
- Users do not get a manual newline key. This is the intended trade-off - the
  spec asks for wrapping/height, not multi-paragraph composition.

If a future tweak wants manual newlines, switch to
`textInputAction: TextInputAction.newline` and rely on the send button only;
that is out of scope here.

## Behaviour contract

- Empty / whitespace-only input is still rejected by `_sendMessage`'s
  `text.isEmpty` guard after trim.
- `_textController.clear()` after send collapses the field back to one line.
- Auto-scroll: growing the input grows the bottom inset; `didChangeMetrics`
  already calls `_autoScrollIfPinned`, so the message list keeps following the
  bottom while the field grows. No new scroll wiring needed.

## Acceptance criteria

- `flutter analyze` clean.
- Existing tests still pass.
- Manual smoke: type a long sentence - it wraps and the field grows to at
  most 5 lines, then scrolls internally; the send button stays reachable;
  Enter/the action key sends; after send the field returns to one line.

## Commit message (suggested)

```
feat(conversation): wrap long input over up to 5 lines

- The composer TextField now grows from 1 to 5 lines (minLines/maxLines)
  with multiline keyboard, wrapping long messages instead of scrolling on
  one line. Enter still submits; send button unchanged.
```
