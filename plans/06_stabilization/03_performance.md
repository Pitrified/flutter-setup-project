# Plan 06/03 - Performance

## Status: complete

## Goal

Define memory and latency budgets. Validate the app runs within constraints
on the target device tier. Identify and fix any hot-path allocations.

## Context

Target device: mid-range Android (4GB RAM, Snapdragon 600-series equivalent).
Model: Gemma 3 1B (~1.2GB on disk, ~1.5GB in RAM during inference).

Key constraints:
- Total app RAM must stay under 2.5GB (model + app + OS headroom)
- First token latency: <3s on target device
- Full response generation: <15s for typical 50-token response
- UI must remain responsive (60fps) during inference (runs on isolate)
- No allocations in build methods or frequently-called code

## Tasks

### 1. Audit build methods for allocations

Scan all widget `build()` methods for:
- `TextStyle(...)` created inline (should be const or cached)
- Lists/maps created per frame
- String interpolation in hot paths

Fix any found issues.

### 2. Add memory monitoring utility

File: `lib/services/debug/memory_monitor.dart`

Debug-only utility that logs peak RSS at key points:
- After engine initialization
- During inference
- After conversation with 20+ messages

Only active in debug mode; no-op in release.

### 3. Profile inference latency

Document expected latency for FakeInferenceEngine vs real engine.
Add `Stopwatch` instrumentation in `StructuredInferenceEngine.generate()`
(debug mode only) to log:
- Time to first token (if engine supports streaming later)
- Total generation time
- Parse time

### 4. Conversation history pruning

Ensure `ConversationController._formatHistory()` limits context window
to prevent prompt from exceeding model's context length (2048 tokens for 1B).

Current: `maxHistoryMessages = 10` - verify this stays within budget.
Estimate: ~50 tokens/message * 10 = 500 tokens for history. Safe.

### 5. Widget rebuild optimization

Ensure `ConversationScreen` ListView only rebuilds new messages, not entire
list. Current `StreamBuilder` rebuilds full list - acceptable for <100 messages
but document the limit.

## Produces

- Audit results (inline fixes if needed)
- `lib/services/debug/memory_monitor.dart` (debug-only)
- Instrumentation in `StructuredInferenceEngine`
- Documentation: `docs/performance-budget.md` with actual numbers

## Tests

- No new tests (performance is validated manually on device)
- Ensure existing tests still pass after any changes
