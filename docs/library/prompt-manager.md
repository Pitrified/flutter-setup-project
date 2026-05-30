# PromptManager

> System spec for `lib/services/prompt/prompt_manager.dart`

## Purpose

Manages versioned prompt templates stored as plain text files in app assets.
Loads templates, caches them in memory, and substitutes `{{variable}}`
placeholders with runtime values.

## Constructor parameters

None.

## Public API

| Method | Signature | Description |
|--------|-----------|-------------|
| `loadTemplate({name, version?})` | `Future<String>` | Load raw template text (cached after first load) |
| `buildPrompt({name, variables, version?})` | `Future<String>` | Load template + substitute all variables |
| `clearCache()` | `void` | Clear the in-memory template cache |

## Template conventions

- Location: `assets/prompts/{name}/vN.txt`
- Variable syntax: `{{variable_name}}`
- Version discovery: tries v10 down to v1, uses first found
- If explicit version provided, loads that version directly

## buildPrompt parameters

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | `String` | yes | Template name (maps to directory under `assets/prompts/`) |
| `variables` | `Map<String, String>` | yes | Key-value pairs for substitution |
| `version` | `int?` | no | Explicit version; null = latest |

## Current templates

| Name | Variables | Used by |
|------|-----------|---------|
| `tutor_response` | `cefr_level`, `user_message`, `conversation_history` | `ConversationController.sendMessage()` |

## Internal state

- `Map<String, String> _cache` - maps `"name/vN"` to template content.
- Uses `rootBundle.loadString()` for asset loading.

## Dependencies

- `flutter/services.dart` (`rootBundle`)

## Provider

`promptManagerProvider` in `lib/providers/service_providers.dart`:

```dart
final promptManagerProvider = Provider<PromptManager>((ref) {
  return PromptManager();
});
```
