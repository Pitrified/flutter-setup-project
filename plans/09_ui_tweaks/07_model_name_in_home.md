# 07 - Correct model name on the welcome screen

Part of phase 09 (UI tweaks and small functionality). The welcome screen
always shows the Qwen model name, even when the OpenAI engine is selected.

## Problem

`WelcomeScreen._buildStatusWidget` renders `Model: ${modelInfo.name}` from the
`AppReady` state. That `modelInfo.name` comes from
`AppController.modelInfo`, whose `name` is `AppController.modelName`, which
defaults to `ModelConfig.defaultModelFileName` (`Qwen3-0.6B.litertlm`).
`appControllerProvider` never overrides `modelName`, so the label is the Qwen
file name regardless of the selected `EngineKind`. With OpenAI selected it
should show the OpenAI model id (e.g. `gpt-4o-mini`), and for the fake engine
something sensible.

## Goal

After this change, the welcome screen's status line reflects the active
engine:

- gemma -> the on-device model name (today: `Qwen3-0.6B.litertlm`).
- openai -> the configured OpenAI model id (`openaiModelProvider`).
- fake -> a clear label such as "Fake (scripted)".

## Design decision: fix in the view, reactively

The model label is presentation derived from settings, so compute it in
`WelcomeScreen` (already a `ConsumerStatefulWidget`) by watching the relevant
providers. This keeps it reactive to an OpenAI-model change without depending
on `AppController` re-initialization.

Note: `openaiModelProvider` changes deliberately do **not** invalidate
`appControllerProvider` (Settings-invalidation discipline from phase 08), so
baking the name into `AppReady` at init time would go stale until the next
init. Reading it in the view avoids that.

We keep using `EngineKind.displayName` where a human label fits.

## Files touched

Modified:

- `lib/screens/welcome/welcome_screen.dart`
  - Import `engine_kind.dart`, `settings_provider.dart`, and `model_config.dart`.
  - In `build`, read the selected kind and (for OpenAI) the model id, or read
    them inside a small helper.
  - Replace the `AppReady` arm of `_buildStatusWidget` so it shows a label
    derived from the engine kind rather than `modelInfo.name`:
    ```dart
    String _modelLabel(WidgetRef ref) {
      final kind = ref.watch(selectedEngineKindProvider);
      return switch (kind) {
        EngineKind.openai => ref.watch(openaiModelProvider),
        EngineKind.gemma => ModelConfig.defaultModelFileName,
        EngineKind.fake => EngineKind.fake.displayName,
      };
    }
    ```
    and render `Text('Model: ${_modelLabel(ref)}', ...)` for `AppReady`.
  - Since `_buildStatusWidget` is a method on the State, it can call
    `ref.watch` directly (the State has `ref`). Make `_modelLabel` a method on
    the State and drop the `ref` parameter, or keep the signature consistent
    with the file's style.

## Alternative considered (not chosen)

Pass `modelName` into `AppController` from `appControllerProvider` based on the
engine kind. Rejected: it bakes the value at init time, so OpenAI-model edits
would not reflect until re-init, and it spreads engine-name logic into the
controller layer. The view-layer fix is smaller and reactive.

## Behaviour contract

- The label updates immediately when the OpenAI model id changes in Settings
  (view watches `openaiModelProvider`).
- The gemma label stays the on-device file name; if a friendlier display name
  is wanted later, add a constant - out of scope here.
- No change to `AppController`, `ModelMetadata`, or initialization flow.

## Acceptance criteria

- `flutter analyze` clean.
- Existing tests pass.
- Manual smoke: with gemma selected the welcome screen shows the Qwen name;
  switch to OpenAI in Settings, return to the welcome screen, and it shows the
  OpenAI model id (not Qwen).

## Commit message (suggested)

```
fix(welcome): show the active engine's model name

- The welcome status line derived its label from a hard-coded Qwen default
  regardless of the selected engine. It now reads the selected EngineKind
  (and openaiModelProvider for OpenAI) so the OpenAI model id is shown when
  OpenAI is active.
```
