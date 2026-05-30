# Plan 06/01 - Loading States

## Status: complete

## Goal

Every async operation shows clear progress to the user. No blank screens,
no missing feedback. Timeouts prevent infinite loading.

## Context

Current loading states:
- `AppLoading` in AppState (welcome screen shows spinner)
- `DownloadInProgress(progress)` with LinearProgressIndicator
- `_isSending` bool in ConversationScreen (send button disabled + spinner)
- `InferenceStatus.loading` on engine status stream

Missing:
- No timeout on inference generation (could hang forever)
- No skeleton/shimmer for conversation loading
- Model download has no estimated time or size display
- No "still working" indicator for long inference (>5s)

## Tasks

### 1. Add inference timeout

File: Update `StructuredInferenceEngine.generate()`

Add configurable timeout (default 30s). On timeout, return
`StructuredInferenceFailure(error: 'Response timed out')`.

### 2. Typing indicator widget

File: `lib/screens/conversation/widgets/typing_indicator.dart`

Animated dots shown in message list while tutor is "thinking".
ConversationScreen shows this when `_isSending` is true.

### 3. Model download progress detail

Update `ModelDownloadScreen` to show:
- File size (from HTTP Content-Length header)
- Estimated time remaining
- Download speed

Requires minor update to `DownloadInProgress` to carry `totalBytes`.

### 4. Skeleton loading for conversation

Show placeholder message bubbles while conversation is initializing
(loading from Hive).

### 5. App initialization timeout

`AppController.initialize()` should timeout after 10s on engine init
and transition to `AppError` rather than hanging.

## Produces

- Updated `StructuredInferenceEngine` with timeout
- `lib/screens/conversation/widgets/typing_indicator.dart`
- Updated `ModelDownloadScreen` with detail
- Updated `DownloadInProgress` model (add `totalBytes`)
- Updated `AppController` with timeout

## Tests

- Unit test: inference timeout returns failure after configured duration
- Unit test: app controller times out and sets error state
- Widget test: typing indicator animates
