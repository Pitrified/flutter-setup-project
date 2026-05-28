# Phase 05 - Controllers and Screens

Wire all core systems into an end-to-end tutoring interaction.
The user types a message and receives a structured correction + conversational reply.

## Goal

A working tutor conversation: launch app, start session, exchange messages,
see corrections, persist history. Initially backed by FakeInferenceEngine,
then swapped to the real model via provider override.

## Plans

| # | File | Status | Produces |
|---|------|--------|----------|
| 00 | 00_conversation_controller.md | not-started | ConversationController + provider |
| 01 | 01_app_controller.md | not-started | AppController + provider |
| 02 | 02_welcome_screen.md | not-started | Welcome screen (full implementation) |
| 03 | 03_model_download_screen.md | not-started | Model download screen (full implementation) |
| 04 | 04_conversation_screen.md | not-started | Conversation screen + MessageBubble + CorrectionCard |
| 05 | 05_integration.md | not-started | End-to-end wiring, demo-ready |

## Execution order

1. **00 + 01** - Controllers first (can be developed in parallel)
2. **02 + 03** - Screens that depend on AppController
3. **04** - Conversation screen depends on ConversationController
4. **05** - Integration ties everything together

## Dependencies

Requires Phase 04 complete (all core systems individually functional):
- InferenceEngine interface + FakeInferenceEngine + FlutterGemmaEngine
- StructuredOutputParser
- ConversationRepository (Hive persistence)
- ModelManager (download + cache)
- PromptManager (versioned templates)

## Key architectural decisions

- Screens never import services directly - always through Riverpod providers
- AppController manages lifecycle; router redirects based on AppState
- ConversationController orchestrates the send/receive loop
- FakeInferenceEngine is the default for development/testing
- Real engine swap happens via provider override in main.dart
