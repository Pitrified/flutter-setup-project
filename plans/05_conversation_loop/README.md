# Phase 05 - Conversation Loop

Wire all core systems into an end-to-end tutoring interaction.
The user types a message and receives a structured correction + conversational reply.

## Goal

A working tutor conversation: launch app, start session, exchange messages,
see corrections, persist history. Initially backed by FakeInferenceEngine,
then swapped to the real model.

## Planned contents

| File | Produces |
|------|----------|
| 00_conversation_controller.md | ConversationController state machine |
| 01_prompt_engineering.md | On-device tutor prompt templates |
| 02_ui_screens.md | Welcome + Conversation screens |
| 03_backend_swap.md | Switch from fake to real engine |
| 04_integration_test.md | End-to-end flow validation |

## Dependencies

Requires Phase 04 (core systems must be individually functional).
