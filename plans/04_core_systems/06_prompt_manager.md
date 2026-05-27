---
status: not-started
depends_on: [03_scaffold/00_create_project.md]
produces: [lib/services/prompt/prompt_manager.dart, assets/prompts/tutor_response/v1.txt]
---

# Plan: Prompt Manager

## Goal

Load versioned prompt templates from app assets, substitute variables, and manage
token budgets. Prompts are bundled in the APK under `assets/prompts/`. Each prompt
type has a folder with `v1.txt`, `v2.txt`, etc. The manager auto-selects the latest.

## Implementation

`lib/services/prompt/prompt_manager.dart`:

```dart
import 'package:flutter/services.dart';

/// Manages versioned prompt templates from app assets.
///
/// Prompts are stored as plain text files in assets/prompts/<name>/vN.txt.
/// The manager loads the highest-numbered version and substitutes variables.
class PromptManager {
  PromptManager();

  final Map<String, String> _cache = {};

  /// Load a prompt template by name, using the specified version.
  ///
  /// If [version] is null, loads the highest available version.
  /// Templates use {{variable}} syntax for substitution.
  Future<String> loadTemplate({
    required String name,
    int? version,
  }) async {
    final key = '$name/v${version ?? "latest"}';
    if (_cache.containsKey(key)) return _cache[key]!;

    final assetPath = version != null
        ? 'assets/prompts/$name/v$version.txt'
        : await _findLatestVersion(name);

    final content = await rootBundle.loadString(assetPath);
    _cache[key] = content;
    return content;
  }

  /// Build a prompt by loading template and substituting variables.
  ///
  /// Variables in the template like {{user_message}} are replaced with
  /// the corresponding values from [variables].
  Future<String> buildPrompt({
    required String name,
    required Map<String, String> variables,
    int? version,
  }) async {
    var template = await loadTemplate(name: name, version: version);

    for (final entry in variables.entries) {
      template = template.replaceAll('{{${entry.key}}}', entry.value);
    }

    return template;
  }

  /// Find the highest version number for a prompt template.
  Future<String> _findLatestVersion(String name) async {
    // AssetManifest approach: load manifest and find matching assets
    final manifestContent = await rootBundle.loadString('AssetManifest.json');
    final manifest = manifestContent; // parse and find latest

    // Fallback: try versions starting from a reasonable max
    for (var v = 10; v >= 1; v--) {
      final path = 'assets/prompts/$name/v$v.txt';
      try {
        await rootBundle.loadString(path);
        return path;
      } on FlutterError {
        continue;
      }
    }

    throw StateError('No prompt template found for "$name"');
  }

  /// Clear the template cache.
  void clearCache() => _cache.clear();
}
```

## Initial prompt template

`assets/prompts/tutor_response/v1.txt`:

```
You are a Portuguese language tutor. The user is learning Portuguese at {{cefr_level}} level.

Respond in this exact JSON format:
{
  "correction": {
    "content": "the full corrected sentence in Portuguese",
    "translation": "English translation of the corrected sentence",
    "errors": [
      {
        "original": "what the user wrote incorrectly",
        "corrected": "the correct version",
        "explanation": "brief explanation in English",
      }
    ]
  },
  "conversation": {
    "content": "your conversational reply in Portuguese",
    "translation": "English translation of your reply"
  }
}

Rules:
- Always reply in Portuguese (Brazilian).
- If the user's message has no errors, set correction.content and correction.translation to empty strings and correction.errors to an empty array.
- Maximum 3 errors per message.
- Keep your reply conversational and encouraging.
- Match complexity to {{cefr_level}} level.
- Output ONLY the JSON object, no other text.

User message: {{user_message}}

Conversation history:
{{conversation_history}}
```

## Variable substitution

| Variable | Source | Example |
|----------|--------|---------|
| `{{cefr_level}}` | Conversation.cefrLevel | "A1" |
| `{{user_message}}` | Current user input | "Eu gosto de cafe" |
| `{{conversation_history}}` | Last N messages formatted | "User: Oi\nTutor: Ola!" |

## Token budget awareness

For small models (1B-3B), prompt + response must fit in context window:
- Gemma 3 1B: 8192 token context
- Reserve ~512 tokens for response
- System prompt: ~200 tokens
- Available for history: ~7400 tokens
- Approximate 1 token per 4 characters for Portuguese

The ConversationController (Phase 05) manages history truncation.
PromptManager only handles template loading and substitution.

## Provider

```dart
final promptManagerProvider = Provider<PromptManager>((ref) {
  return PromptManager();
});
```

## Tests

- Load existing template by explicit version
- Variable substitution replaces all placeholders
- Unknown variable placeholders are left as-is (no crash)
- Cache returns same content on second load
- Nonexistent template throws StateError

## Acceptance criteria

- [ ] PromptManager loads versioned templates from assets
- [ ] Variable substitution with {{var}} syntax works
- [ ] Template cache avoids redundant asset reads
- [ ] v1.txt prompt exists with tutor response format
- [ ] Tests pass
- [ ] `flutter analyze` passes
