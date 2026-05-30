# Prompt engineering guide

How prompts work in fala, which files are involved, and how to iterate on them.

---

## Architecture overview

```
assets/prompts/{name}/vN.txt        <-- prompt templates (versioned plain text)
assets/prompts/{name}_schema.json   <-- expected JSON schema (reference only)
lib/services/prompt/prompt_manager.dart  <-- loads + substitutes variables
lib/services/inference/structured_output_parser.dart  <-- parses LLM output
lib/services/inference/json_extractor.dart  <-- extracts JSON from raw text
lib/models/tutor_response.dart      <-- Dart model for structured output
```

---

## File roles

### `assets/prompts/tutor_response/v1.txt`

The prompt template sent to the on-device model. Contains:

- System instruction (role, language, CEFR level)
- Exact JSON format the model must produce
- Rules constraining behavior
- Variable placeholders: `{{cefr_level}}`, `{{user_message}}`, `{{conversation_history}}`

This is the primary file you edit when improving response quality.

### `assets/prompts/tutor_response_schema.json`

JSON Schema describing the expected output structure. Used as documentation reference only (not enforced at runtime). Keep it in sync with `TutorResponse` model.

### `lib/services/prompt/prompt_manager.dart`

Loads the highest-versioned template from assets and substitutes `{{variable}}` placeholders with runtime values. Does NOT modify the prompt content itself.

### `lib/services/inference/json_extractor.dart`

Extracts JSON from whatever the model returns, using three strategies in order:

1. Direct parse (output is already pure JSON)
2. Markdown code block (` ```json ... ``` `)
3. JSON substring (first `{` to last `}`)

This means the model can output extra text around the JSON and it will still parse.

### `lib/services/inference/structured_output_parser.dart`

Wires `JsonExtractor` to the `TutorResponse.fromJson` factory. If extraction or deserialization fails, returns a `ParseFailure` with the raw text (which the UI shows as a fallback message).

### `lib/models/tutor_response.dart`

Freezed model defining the Dart types: `TutorResponse`, `CorrectionBlock`, `ConversationBlock`, `CorrectionError`. Generated code handles JSON deserialization. The field names here must match the JSON keys in the prompt template.

---

## How to iterate on a prompt

### 1. Never edit an existing version

Create a new version file instead:

```
assets/prompts/tutor_response/v2.txt
```

The `PromptManager` auto-selects the highest version number (scans v10 down to v1).

### 2. Template variables available

| Variable | Source | Description |
|----------|--------|-------------|
| `{{cefr_level}}` | Conversation metadata | A1, A2, B1, B2, C1, C2 |
| `{{user_message}}` | User input | The message the user just typed |
| `{{conversation_history}}` | Last N messages | Formatted history for context |

### 3. Key constraints for on-device models

Small models (0.6B-1B parameters) need different prompting than cloud APIs:

- **Be explicit about format.** Show the exact JSON structure with field descriptions.
- **Use "Output ONLY the JSON"** to reduce preamble/commentary.
- **Keep instructions short.** Long system prompts eat into the token budget (1024 max).
- **Avoid complex reasoning.** Small models struggle with multi-step logic.
- **Repeat critical rules.** Redundancy helps small models comply.
- **Test with thinking disabled.** Qwen3's thinking mode (`<think>` tags) can leak into output. We set `isThinking: false` in the engine.

### 4. Testing prompts without building APK

Use the fake engine with a modified response to test parsing:

```bash
flutter test test/services/prompt_manager_test.dart
```

Or run the full app with `--dart-define=FAKE_ENGINE=true` to bypass the model entirely and test UI flow with canned responses.

### 5. Debugging on-device output

When the model produces unexpected output:

1. Check logcat for the raw response:
   ```bash
   adb logcat --pid=$(adb shell pidof com.fala.app) | grep "flutter"
   ```

2. Look for `InferenceChat: Complete response accumulated:` in logs - this shows exactly what the model returned.

3. If the JSON is malformed, the `JsonExtractor` will fail and `StructuredParseFailure` fires. The UI shows the raw text as a fallback.

4. Common issues:
   - Model outputs text before/after JSON -> `JsonExtractor` handles this (strategy 3)
   - Model outputs `<think>...</think>` tags -> Filtered by flutter_gemma when `isThinking: false`
   - Model hallucinates extra fields -> `fromJson` ignores unknown keys (freezed default)
   - Model omits required fields -> Parse fails, raw text shown

---

## Adding a new prompt type

1. Create folder: `assets/prompts/{new_name}/v1.txt`
2. Add schema reference: `assets/prompts/{new_name}_schema.json`
3. Create Dart model in `lib/models/{new_name}.dart` with `@freezed` + `fromJson`
4. Register in `pubspec.yaml` assets (glob `assets/prompts/` already covers it)
5. Create a new `StructuredInferenceEngine<NewModel>` provider wired with the appropriate parser

---

## Current prompt: tutor_response v1

The current prompt instructs the model to:

- Act as a Portuguese tutor
- Correct errors in the user's message (max 3)
- Reply conversationally in Portuguese
- Include English translations
- Output structured JSON matching `TutorResponse` schema
- Match complexity to the user's CEFR level

The model (Qwen3 0.6B) produces reasonable responses at this scale but may:

- Give generic corrections for unusual sentences
- Struggle with idiomatic Portuguese expressions
- Produce shorter replies than larger models would

These limitations are expected for a 0.6B parameter model and can be improved by upgrading to a larger model later (the `InferenceEngine` interface makes this a config-level change).
