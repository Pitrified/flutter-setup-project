# 07 - Engine selection: correct model name, OpenAI default, scoped settings

Part of phase 09 (UI tweaks and small functionality). Three related engine /
settings fixes from README section 07:

1. The welcome screen shows the right model name for the active engine (not a
   hard-coded Qwen name). **Done** - see part 1.
2. OpenAI is the default engine.
3. The Settings page only shows the settings relevant to the selected engine.

## Part 1 - Correct model name on the welcome screen (done)

### Problem

`WelcomeScreen._buildStatusWidget` rendered `Model: ${modelInfo.name}` from the
`AppReady` state, whose name traced back to `AppController.modelName`, which
defaults to `ModelConfig.defaultModelFileName` (`Qwen3-0.6B.litertlm`).
`appControllerProvider` never overrides it, so the label was the Qwen file name
regardless of the selected `EngineKind`.

### Fix (implemented)

Compute the label in the view from the providers, reactively:

```dart
String _modelLabel() {
  final kind = ref.watch(selectedEngineKindProvider);
  return switch (kind) {
    EngineKind.openai => ref.watch(openaiModelProvider),
    EngineKind.gemma => ModelConfig.defaultModelFileName,
    EngineKind.fake => EngineKind.fake.displayName,
  };
}
```

The `AppReady` arm of `_buildStatusWidget` uses `_modelLabel()` instead of
`modelInfo.name`. This stays reactive to an OpenAI-model change without
re-initializing `AppController` (`openaiModelProvider` deliberately does not
invalidate `appControllerProvider`).

Rejected alternative: pass `modelName` into `AppController` - it bakes the
value at init time and spreads engine-name logic into the controller layer.

## Part 2 - Make OpenAI the default engine

### Change

- `lib/services/settings/app_settings_repository.dart`
  - `defaultEngineKind`: `EngineKind.gemma` -> `EngineKind.openai`.

### Side effects to verify

- `skipModelCheckFor(EngineKind.openai)` is already `true`, so a fresh install
  no longer routes through the model-download gate on first launch
  (`AppController.initialize` skips the model check). This is the intended
  cloud-first behaviour, but confirm the welcome -> conversation flow works
  with no model file present and no OpenAI key yet (the OpenAI engine surfaces
  a clear error on send rather than at startup).
- Existing users keep their persisted `engine_kind`; only first-launch /
  unset installs change. No migration needed.
- Check tests that assume the gemma default (search for `defaultEngineKind`,
  `EngineKind.gemma`, and any welcome/app-init tests) and update expectations.

## Part 3 - Scope Settings sections to the selected engine

### Current state

`SettingsScreen.build` always renders: the engine dropdown, the default-CEFR
section (engine-agnostic), and the OpenAI section (`_OpenAiSection`). There is
**no** gemma-specific settings group today - on-device model handling lives in
the separate model-download screen.

### Change

- `lib/screens/settings/settings_screen.dart`
  - Keep the engine dropdown and the default-CEFR section always visible (CEFR
    is not engine-specific).
  - Show the OpenAI section (heading + divider + `_OpenAiSection`) only when
    `selectedKind == EngineKind.openai`. `selectedKind` is already read at the
    top of `build` via `ref.watch(selectedEngineKindProvider)`, so gate the
    relevant `children` on it (e.g. build the list conditionally or
    `if (selectedKind == EngineKind.openai) ...[ ... ]`).
  - gemma: no dedicated settings exist yet. Either render nothing engine-
    specific, or a short placeholder ("On-device model is managed on the
    download screen."). Recommended: render nothing now and leave a `// TODO`
    so the structure is obvious when gemma settings appear.
  - fake: no settings; render nothing engine-specific.

### Note on the "and so on for the other models" wording

Only OpenAI has engine-specific settings today, so the visible effect is:
hide the OpenAI block unless OpenAI is active. The structure (switch / per-kind
section) should make adding a gemma block later a single addition.

## Files touched (remaining: parts 2 + 3)

Modified:

- `lib/services/settings/app_settings_repository.dart` - default engine kind.
- `lib/screens/settings/settings_screen.dart` - conditional OpenAI section.

## Acceptance criteria

- `flutter analyze` clean.
- Tests updated for the new default engine kind; full suite passes.
- Manual smoke:
  - Fresh install lands on the conversation screen with OpenAI active (welcome
    status shows the OpenAI model id, not Qwen).
  - Settings shows the OpenAI section only when OpenAI is selected; switching to
    on-device hides it.

## Commit message (suggested)

```
feat(settings): default to OpenAI and scope settings to the active engine

- Default EngineKind is now OpenAI (cloud-first; first launch skips the
  on-device model gate).
- Settings shows the OpenAI section only when OpenAI is selected; the engine
  and default-CEFR sections stay visible for all engines.
- (Part 1, already landed) the welcome screen shows the active engine's model
  name instead of a hard-coded Qwen default.
```
