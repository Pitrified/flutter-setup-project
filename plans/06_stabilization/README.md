# Phase 06 - Stabilization

Harden the app: handle all failure modes gracefully, add tests,
and validate performance on target Android devices.

## Goal

The app never crashes. Every error produces a recoverable UI state.
Tests pass in CI using the fake engine. Inference latency is acceptable
on the target device tier.

## Planned contents

| File | Produces |
|------|----------|
| 00_error_handling.md | Failure taxonomy + recovery UI |
| 01_loading_states.md | Download progress, generation indicator, timeouts |
| 02_testing_strategy.md | Unit, widget, and integration test suite |
| 03_performance.md | Memory/latency budgets, minimum device tier |

## Dependencies

Requires Phase 05 (conversation loop must be functional end-to-end).
