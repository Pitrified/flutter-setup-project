# Phase 06 - Stabilization

Harden the app: handle all failure modes gracefully, add tests,
and validate performance on target Android devices.

## Goal

The app never crashes. Every error produces a recoverable UI state.
Tests pass in CI using the fake engine. Inference latency is acceptable
on the target device tier.

## Plans

| # | File | Status | Produces |
|---|------|--------|----------|
| 00 | [00_error_handling.md](00_error_handling.md) | not-started | Failure taxonomy + recovery UI |
| 01 | [01_loading_states.md](01_loading_states.md) | not-started | Timeouts + progress detail |
| 02 | [02_testing_strategy.md](02_testing_strategy.md) | not-started | Widget + integration tests |
| 03 | [03_performance.md](03_performance.md) | not-started | Memory/latency budgets |

## Dependencies

Requires Phase 05 (conversation loop must be functional end-to-end).
