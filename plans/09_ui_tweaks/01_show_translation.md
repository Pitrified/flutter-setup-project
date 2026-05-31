# 01 - Show translation on tap

Part of phase 09 (UI tweaks and small functionality). Adds a tap-to-reveal
translation under each tutor message bubble.

## Goal

After this change:

- Tapping a tutor message bubble toggles a smaller, dimmer translation line
  rendered directly under the original Portuguese reply.
- Default state: only the Portuguese reply is visible.
- The translation comes from `message.tutorResponse?.conversation.translation`
  - no extra inference call.
- User messages are unaffected.

## Non-goals

- No translation toggle for correction blocks (the correction card already
  shows its own translation via `CorrectionCard`).
- No persisted "show all translations" setting.
- No animated expand/collapse beyond a basic `AnimatedSize` (one line, fast).
- No tap feedback on user messages.

## Files touched

Modified:

- `lib/screens/conversation/widgets/message_bubble.dart`
  - Convert `MessageBubble` from `StatelessWidget` to `StatefulWidget`.
  - Add `bool _showTranslation = false`.
  - Wrap the bubble in a `GestureDetector` (or `InkWell`) that toggles
    `_showTranslation` only when `message.role == MessageRole.tutor` and
    `message.tutorResponse?.conversation.translation` is non-empty.
  - Render the translation below the existing `Text(content)` inside a
    `Column`, using `Theme.of(context).textTheme.bodySmall` with a faded
    `onSurfaceVariant` color.
  - Wrap the translation in `AnimatedSize(duration: 150ms)` with a `SizedBox`
    when hidden.

New:

- `test/screens/conversation/widgets/message_bubble_test.dart` - widget tests:
  - Tutor message with translation: tap shows the translation text, second
    tap hides it.
  - Tutor message without translation: tap does nothing visible.
  - User message: tap does not reveal anything.

## Behaviour contract

- `_showTranslation` is local widget state - it resets when the list is
  rebuilt (e.g. on a new message). Acceptable: translations are a glance
  affordance, not persistent UI.
- The bubble's `maxWidth` constraint already in place applies to both lines,
  so the translation wraps inside the same bubble width.
- Hit target is the full bubble (not just the text), preserving the existing
  padding.

## Acceptance criteria

- `flutter analyze` clean.
- All existing tests still pass; new widget tests cover the three cases
  above.
- Manual smoke: send a Portuguese sentence, tap the tutor reply, see the
  English translation appear in smaller / dimmer text under the original.
  Tap again - it hides.

## Commit message (suggested)

```
feat(conversation): tap tutor message to reveal translation

- MessageBubble is now stateful; tutor bubbles with a translation in
  TutorResponse.conversation.translation toggle a small dim line under
  the original reply on tap.
- User bubbles and tutor bubbles without a translation are inert.
```
