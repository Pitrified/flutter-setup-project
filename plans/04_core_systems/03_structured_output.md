---
status: not-started
depends_on: [04_core_systems/00_inference_interface.md, 03_scaffold/02_generated_models.md]
produces: [lib/services/inference/structured_output_parser.dart]
---

# Plan: Structured Output Pipeline

## Goal

Parse raw LLM text output into a validated TutorResponse. Handle the gap between
what the model actually generates and what the app expects. Two strategies:

1. **Constrained decoding** (preferred): SDK generates only valid JSON via FSM grammar
2. **Post-hoc parsing** (fallback): extract JSON from raw text, validate, recover

## Implementation

`lib/services/inference/structured_output_parser.dart`:

```dart
import 'dart:convert';

import '../../models/tutor_response.dart';

/// Result of parsing raw LLM output into structured form.
sealed class ParseResult {
  const ParseResult();
}

class ParseSuccess extends ParseResult {
  const ParseSuccess({required this.response});
  final TutorResponse response;
}

class ParseFailure extends ParseResult {
  const ParseFailure({required this.rawText, required this.error});
  final String rawText;
  final String error;
}

/// Parses raw LLM text output into a validated [TutorResponse].
///
/// Attempts multiple extraction strategies in order:
/// 1. Direct JSON parse (if output is pure JSON)
/// 2. Extract JSON from markdown code block
/// 3. Extract JSON substring (first { to last })
///
/// Validates the parsed structure against the TutorResponse schema.
class StructuredOutputParser {
  const StructuredOutputParser();

  /// Parse raw text into a TutorResponse.
  ParseResult parse(String rawText) {
    final trimmed = rawText.trim();

    // Strategy 1: direct JSON parse
    final direct = _tryParseJson(trimmed);
    if (direct != null) return ParseSuccess(response: direct);

    // Strategy 2: extract from markdown code block
    final codeBlock = _extractCodeBlock(trimmed);
    if (codeBlock != null) {
      final parsed = _tryParseJson(codeBlock);
      if (parsed != null) return ParseSuccess(response: parsed);
    }

    // Strategy 3: extract JSON substring
    final substring = _extractJsonSubstring(trimmed);
    if (substring != null) {
      final parsed = _tryParseJson(substring);
      if (parsed != null) return ParseSuccess(response: parsed);
    }

    return ParseFailure(
      rawText: rawText,
      error: 'Could not extract valid JSON from LLM output',
    );
  }

  TutorResponse? _tryParseJson(String text) {
    try {
      final decoded = jsonDecode(text);
      if (decoded is! Map<String, dynamic>) return null;
      return TutorResponse.fromJson(decoded);
    } on Object {
      return null;
    }
  }

  String? _extractCodeBlock(String text) {
    final regex = RegExp(r'```(?:json)?\s*\n?([\s\S]*?)\n?```');
    final match = regex.firstMatch(text);
    return match?.group(1)?.trim();
  }

  String? _extractJsonSubstring(String text) {
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start == -1 || end == -1 || end <= start) return null;
    return text.substring(start, end + 1);
  }
}
```

## Constrained decoding configuration

If the SDK supports grammar-guided generation, provide the JSON schema:

```json
{
  "type": "object",
  "required": ["correction", "conversation"],
  "properties": {
    "correction": {
      "type": "object",
      "required": ["content", "translation", "errors"],
      "properties": {
        "content": {"type": "string"},
        "translation": {"type": "string"},
        "errors": {
          "type": "array",
          "items": {
            "type": "object",
            "required": ["original", "corrected", "explanation"],
            "properties": {
              "original": {"type": "string"},
              "corrected": {"type": "string"},
              "explanation": {"type": "string"}
            }
          }
        }
      }
    },
    "conversation": {
      "type": "object",
      "required": ["content", "translation"],
      "properties": {
        "content": {"type": "string"},
        "translation": {"type": "string"}
      }
    }
  }
}
```

Store as `assets/prompts/tutor_response_schema.json` for runtime loading.

## Integration with InferenceEngine

The pipeline sits between the raw engine output and the app:

```
User input -> Prompt builder -> InferenceEngine.generate()
  -> raw text -> StructuredOutputParser.parse()
  -> TutorResponse (or fallback)
```

The provider that orchestrates this:

```dart
// In ConversationController (Phase 05):
final result = await engine.generate(request);
if (result is InferenceSuccess) {
  final parsed = parser.parse(result.rawText);
  // Use parsed result or handle failure
}
```

## Fallback behavior

When parsing fails:
- Log the raw output for debugging
- Show the user a generic "I had trouble formatting my response" message
- Optionally display the raw text as-is (dev mode only)
- Do NOT retry automatically (expensive on-device, no network retry pattern applies)

## Tests

`test/services/structured_output_parser_test.dart`:

- Pure JSON input -> success
- JSON in markdown code block -> success
- JSON embedded in surrounding text -> success
- Invalid JSON -> failure with error message
- Valid JSON but wrong schema (missing required fields) -> failure
- Empty string -> failure
- Multiple JSON objects in text -> extracts first valid one

## Acceptance criteria

- [ ] StructuredOutputParser handles all 3 extraction strategies
- [ ] Sealed ParseResult type for exhaustive matching
- [ ] Schema JSON file stored in assets
- [ ] All test cases pass
- [ ] No dependency on any specific inference SDK
- [ ] `flutter analyze` passes
