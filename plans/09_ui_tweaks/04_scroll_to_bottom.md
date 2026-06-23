# 04 - Scroll to bottom

Part of phase 09 (UI tweaks and small functionality). Makes the conversation
keep the latest content in view, while respecting a user who has scrolled up to
re-read earlier messages.

## draft

when the user sends a message, the conversation should automatically scroll to the bottom to show the latest messages and responses
and same for any action that creates content at the bottom of the conversation, such as showing the translation, receiving a response from the tutor, ...
and also when opening the keyboard

smooth scroll so that latest content is on the screen
 
only exception: if the user has manually scrolled up to read previous messages, then we should not scroll to the bottom when new messages or responses are received, to avoid interrupting the user reading previous content
in this case, we can render a "arrows down" button that the user can tap to scroll to the bottom

## Goal

After this change:

- The list auto-scrolls (smooth, ~200ms ease-out) to the newest content when:
  - the user sends a message,
  - a tutor reply streams in (each delta grows the live overlay),
  - the streamed turn is committed to the message list,
  - the soft keyboard opens (bottom inset grows).
- Auto-scroll only happens while the user is *pinned to bottom* (already at or
  within a small threshold of the bottom).
- If the user has scrolled up, new content does **not** yank the view down.
  Instead a circular "scroll to bottom" button (down arrow) fades in above the
  input bar. Tapping it smooth-scrolls to the bottom and re-pins.
- The button is hidden whenever the user is pinned to bottom.

## Non-goals

- No "N new messages" counter / unread badge on the button (just an arrow).
- No auto-scroll triggered by toggling a translation on a non-last bubble
  (plan 01). A pinned user near the bottom already sees the AnimatedSize grow;
  re-pinning after an arbitrary mid-list tap is out of scope.
- No change to the streaming engine, controller, or message model.
- No "scroll to bottom on screen open" animation beyond the list's natural
  initial layout (the first build already starts at the top of a short list).

## Current state

`lib/screens/conversation/conversation_screen.dart` already has:

- a single `ScrollController _scrollController` attached to the `ListView.builder`
  in `_buildMessageList`,
- a `_scrollToBottom()` helper that animates to `maxScrollExtent` in a
  post-frame callback (currently only called at the end of `_sendMessage`).

The streaming overlay (`_buildStreamingOverlay`) is the last item in the list
and rebuilds per delta via its own `StreamBuilder`; the committed messages come
from the outer `conversationStream` `StreamBuilder`.

## Design

Track a single piece of state: is the user pinned to the bottom?

- Add `bool _isPinnedToBottom = true;`
- Add a scroll listener (`_scrollController.addListener(_onScroll)` in
  `initState`, removed in `dispose`) that recomputes pinned state:

  ```dart
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    final atBottom = pos.maxScrollExtent - pos.pixels <= _bottomThreshold;
    if (atBottom != _isPinnedToBottom) {
      setState(() => _isPinnedToBottom = atBottom);
    }
  }
  ```

  with `static const _bottomThreshold = 80.0;` (a few rows of slack so small
  layout jitter / the streaming overlay growing does not unpin the user).

- Replace the unconditional `_scrollToBottom()` with a guarded
  `_autoScrollIfPinned()` used by the content-growth triggers, while the button
  tap and `_sendMessage` use a forced `_scrollToBottom()` that also sets
  `_isPinnedToBottom = true` (sending is an explicit intent to follow along).

  ```dart
  void _autoScrollIfPinned() {
    if (_isPinnedToBottom) _scrollToBottom();
  }
  ```

Because the animated scroll lands exactly at `maxScrollExtent`, the listener
ends with `atBottom == true`, so programmatic scrolls keep the user pinned.

### Trigger points

1. **Send** - `_sendMessage` already calls `_scrollToBottom()`; change it to
   force-pin first (`_isPinnedToBottom = true`) so a user who had scrolled up
   and then sends is brought back down.
2. **Streaming deltas** - in `_buildStreamingOverlay`'s `StreamBuilder.builder`,
   schedule `_autoScrollIfPinned()` in a post-frame callback on each rebuild
   that has content. (Cheap: it no-ops unless pinned, and animateTo to an
   already-current max is a no-op.)
3. **Committed turn** - in the outer `conversationStream` `StreamBuilder.builder`
   (or `_buildMessageList`), schedule `_autoScrollIfPinned()` when the message
   count grows. Track `int _lastMessageCount` to only fire on growth.
4. **Keyboard open** - make the state a `WidgetsBindingObserver`
   (`with WidgetsBindingObserver`), register in `initState`
   (`WidgetsBinding.instance.addObserver(this)`), unregister in `dispose`, and
   override `didChangeMetrics()` to call `_autoScrollIfPinned()` in a post-frame
   callback. When the keyboard pushes the viewport up, a pinned user follows the
   bottom.

### The button

Wrap the `Expanded` list in a `Stack` so the button floats over the bottom of
the list, above the input bar:

```dart
Expanded(
  child: Stack(
    children: [
      StreamBuilder<Conversation?>( ... existing list ... ),
      Positioned(
        right: 16,
        bottom: 16,
        child: AnimatedOpacity(
          opacity: _isPinnedToBottom ? 0 : 1,
          duration: const Duration(milliseconds: 150),
          child: IgnorePointer(
            ignoring: _isPinnedToBottom,
            child: FloatingActionButton.small(
              heroTag: null,
              onPressed: () {
                setState(() => _isPinnedToBottom = true);
                _scrollToBottom();
              },
              child: const Icon(Icons.keyboard_arrow_down),
            ),
          ),
        ),
      ),
    ],
  ),
),
```

`IgnorePointer` keeps the faded-out button non-interactive. `heroTag: null`
avoids a hero-tag clash if any other FAB is ever added.

## Files touched

Modified:

- `lib/screens/conversation/conversation_screen.dart`
  - `_ConversationScreenState` gains `with WidgetsBindingObserver`.
  - Add `_isPinnedToBottom`, `_lastMessageCount`, `_bottomThreshold`,
    `_onScroll`, `_autoScrollIfPinned`; register/unregister scroll listener and
    `WidgetsBindingObserver` in `initState`/`dispose`; override
    `didChangeMetrics`.
  - `_sendMessage` force-pins before scrolling.
  - `_buildStreamingOverlay` and the committed-message path schedule
    `_autoScrollIfPinned()`.
  - Wrap the list `Expanded` body in a `Stack` with the floating button.

New:

- `test/screens/conversation/widgets/...` or
  `test/screens/conversation/conversation_scroll_test.dart` - widget tests
  (see below).

## Behaviour contract

- Pinned is recomputed from scroll position, not stored across rebuilds beyond
  the in-state bool; a rebuild that keeps the position at the bottom keeps it
  pinned.
- The threshold (80px) means the user can drift a little above the very bottom
  and still be auto-followed; scrolling up past it unpins and reveals the button.
- Forced scrolls (send, button tap) always re-pin even if the user was scrolled
  up.
- `_autoScrollIfPinned` and `didChangeMetrics` both guard on
  `_scrollController.hasClients` (no list mounted when the conversation is empty).

## Acceptance criteria

- `flutter analyze` clean.
- All existing tests still pass.
- New widget tests cover:
  - Pinned user: a new tutor message keeps the view at the bottom; button hidden.
  - Scrolled-up user: a new message does **not** move the view; button visible.
  - Tapping the button scrolls to bottom and hides the button.
- Manual smoke (device/emulator with keyboard):
  - Send a message - view follows the streamed reply to the bottom.
  - Scroll up mid-conversation while a reply streams - view stays put, arrow
    button appears; tap it - jumps to bottom.
  - Open the keyboard while pinned - latest content stays visible.

## Commit message (suggested)

```
feat(conversation): auto-scroll to bottom with scroll-to-bottom button

- Track whether the user is pinned to the bottom of the message list and
  auto-scroll (send, streamed deltas, committed turn, keyboard open) only
  while pinned.
- When the user has scrolled up, suppress auto-scroll and show a floating
  down-arrow button that re-pins and scrolls to the bottom on tap.
```

## Tweaks

when pressing the down arrow button, scrolls to last user message, not the last tutor message

when pressing the tutor message to show the translation, does not scroll
