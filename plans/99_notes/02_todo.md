Remaining TODOs (29/05/2026)

Testing (06/02 - in-progress)

Missing: screen widget tests (WelcomeScreen, ModelDownloadScreen, ConversationScreen)
Missing: integration test (full conversation flow end-to-end)
Unit tests pass (50/50)

Play Store Alpha (07/01 - in-progress)

Manual steps remain: signing key setup, Play Console enrollment, first AAB upload, internal track configuration

Dead code cleanup

ModelManager.downloadModel() / progress stream are now unused (download screen uses FlutterGemma.installModel directly). Could be removed or kept for future flexibility.

Docs gap

docs/project-summary.md referenced in 07/02 template but doesn't exist yet
