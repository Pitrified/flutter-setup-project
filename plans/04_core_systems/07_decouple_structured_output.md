---
status: complete
depends_on: [04_core_systems/00_inference_interface.md, 04_core_systems/03_structured_output.md, 04_core_systems/01_fake_inference_engine.md]
produces: [lib/services/inference/inference_engine.dart, lib/services/inference/json_extractor.dart, lib/services/inference/structured_output_parser.dart, lib/services/inference/structured_inference_engine.dart, lib/services/inference/fake_inference_engine.dart]
---

# Plan: Decouple Structured Output from InferenceEngine

## Goal

Refactor the inference layer so that:
1. InferenceEngine is pure text-in/text-out (no domain types)
2. StructuredOutputParser is generic (not tied to TutorResponse)
3. A new StructuredInferenceEngine<T> composes engine + parser

This fixes the coupling of InferenceSuccess to TutorResponse and creates a
clean, reusable architecture for structured LLM output.

See [99_notes/01_structured_parsing.md](../99_notes/01_structured_parsing.md)
for the full analysis and rejected alternatives.

## Design: Option H + C

### Layer 1: InferenceEngine (text-in/text-out)

Remove `tutorResponse` from `InferenceSuccess`. Engine knows nothing about
downstream parsing.

`lib/services/inference/inference_engine.dart` (modified):

```dart
/// Result of an inference call.
sealed class InferenceResult {
  const InferenceResult();
}

class InferenceSuccess extends InferenceResult {
  const InferenceSuccess({required this.rawText});
  final String rawText;
}

class InferenceFailure extends InferenceResult {
  const InferenceFailure({required this.error});
  final String error;
}
```

### Layer 2: JsonExtractor (shared text extraction strategies)

Separates the "find JSON in messy LLM text" concern from deserialization.
Independently testable.

`lib/services/inference/json_extractor.dart` (new):

```dart
/// Extracts a JSON string from raw LLM text output.
///
/// Tries multiple strategies in order:
/// 1. Direct parse (output is already pure JSON)
/// 2. Extract from markdown code block (```json ... ```)
/// 3. Extract JSON substring (first { to last })
class JsonExtractor {
  const JsonExtractor();

  /// Attempt to extract a valid JSON string from raw text.
  ///
  /// Returns the extracted JSON string, or null if no JSON found.
  String? extract(String rawText) {
    final trimmed = rawText.trim();

    // Strategy 1: already valid JSON
    if (_isValidJson(trimmed)) return trimmed;

    // Strategy 2: markdown code block
    final codeBlock = _extractCodeBlock(trimmed);
    if (codeBlock != null && _isValidJson(codeBlock)) return codeBlock;

    // Strategy 3: JSON substring
    final substring = _extractJsonSubstring(trimmed);
    if (substring != null && _isValidJson(substring)) return substring;

    return null;
  }

  bool _isValidJson(String text) {
    try {
      jsonDecode(text);
      return true;
    } on Object {
      return false;
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

### Layer 3: StructuredOutputParser<T> (generic)

Takes a `fromJson` factory. Uses JsonExtractor to find JSON, then deserializes.

`lib/services/inference/structured_output_parser.dart` (rewritten):

```dart
import 'dart:convert';

import 'json_extractor.dart';

/// Result of parsing raw LLM output into a structured type.
sealed class ParseResult<T> {
  const ParseResult();
}

class ParseSuccess<T> extends ParseResult<T> {
  const ParseSuccess({required this.value});
  final T value;
}

class ParseFailure<T> extends ParseResult<T> {
  const ParseFailure({required this.rawText, required this.error});
  final String rawText;
  final String error;
}

/// Generic parser that extracts JSON from LLM text and deserializes to T.
///
/// Works with any type that has a fromJson factory (all freezed models do).
class StructuredOutputParser<T> {
  const StructuredOutputParser({
    required this.fromJson,
    this.extractor = const JsonExtractor(),
  });

  /// Factory function to deserialize JSON map into T.
  final T Function(Map<String, dynamic>) fromJson;

  /// JSON extraction strategy.
  final JsonExtractor extractor;

  /// Parse raw LLM text into a validated instance of T.
  ParseResult<T> parse(String rawText) {
    final jsonString = extractor.extract(rawText);
    if (jsonString == null) {
      return ParseFailure(
        rawText: rawText,
        error: 'Could not extract valid JSON from LLM output',
      );
    }

    try {
      final map = jsonDecode(jsonString) as Map<String, dynamic>;
      return ParseSuccess(value: fromJson(map));
    } on Object catch (e) {
      return ParseFailure(rawText: rawText, error: e.toString());
    }
  }
}
```

### Layer 4: StructuredInferenceEngine<T> (composition)

Composes a raw InferenceEngine with a StructuredOutputParser<T>. This is what
the ConversationController depends on.

`lib/services/inference/structured_inference_engine.dart` (new):

```dart
import 'inference_engine.dart';
import 'structured_output_parser.dart';

/// Result of a structured inference call.
///
/// Three possible outcomes:
/// - [StructuredSuccess]: inference succeeded and output parsed to T
/// - [StructuredInferenceFailure]: engine failed to generate
/// - [StructuredParseFailure]: engine generated text but parsing failed
sealed class StructuredResult<T> {
  const StructuredResult();
}

class StructuredSuccess<T> extends StructuredResult<T> {
  const StructuredSuccess({required this.value, required this.rawText});

  /// The parsed and validated domain object.
  final T value;

  /// The raw text from the engine (kept for logging/debugging).
  final String rawText;
}

class StructuredInferenceFailure<T> extends StructuredResult<T> {
  const StructuredInferenceFailure({required this.error});
  final String error;
}

class StructuredParseFailure<T> extends StructuredResult<T> {
  const StructuredParseFailure({required this.rawText, required this.error});

  /// The raw text that could not be parsed.
  final String rawText;

  /// Description of the parse failure.
  final String error;
}

/// Composes a raw InferenceEngine with a StructuredOutputParser<T>.
///
/// Provides a single typed API: send a prompt, get back T or an explicit
/// failure mode. The caller never deals with raw text directly.
class StructuredInferenceEngine<T> {
  const StructuredInferenceEngine({
    required this.engine,
    required this.parser,
  });

  /// The underlying raw text inference engine.
  final InferenceEngine engine;

  /// The parser that converts raw text to T.
  final StructuredOutputParser<T> parser;

  /// Delegates to the underlying engine.
  InferenceStatus get status => engine.status;

  /// Delegates to the underlying engine.
  Stream<InferenceStatus> get statusStream => engine.statusStream;

  /// Delegates to the underlying engine.
  bool get isReady => engine.isReady;

  /// Generate and parse a structured response.
  Future<StructuredResult<T>> generate(InferenceRequest request) async {
    final result = await engine.generate(request);
    return switch (result) {
      InferenceFailure(:final error) =>
        StructuredInferenceFailure(error: error),
      InferenceSuccess(:final rawText) => switch (parser.parse(rawText)) {
        ParseSuccess(:final value) =>
          StructuredSuccess(value: value, rawText: rawText),
        ParseFailure(:final rawText, :final error) =>
          StructuredParseFailure(rawText: rawText, error: error),
      },
    };
  }

  /// Delegates to the underlying engine.
  Future<void> dispose() => engine.dispose();
}
```

### Update FakeInferenceEngine

Remove `tutorResponse` from the return value. Only return `rawText` (serialized
JSON). The structured engine layer handles parsing.

```dart
// Before:
return InferenceSuccess(
  rawText: jsonEncode(response.toJson()),
  tutorResponse: response,
);

// After:
return InferenceSuccess(rawText: jsonEncode(response.toJson()));
```

### Update FlutterGemmaEngine

No change needed - it already only returns rawText.

## Provider setup

`lib/providers/inference_provider.dart` (updated):

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/tutor_response.dart';
import '../services/inference/inference_engine.dart';
import '../services/inference/structured_inference_engine.dart';
import '../services/inference/structured_output_parser.dart';

/// Provider for the raw inference engine.
///
/// Override in tests with FakeInferenceEngine.
/// Override in production with FlutterGemmaEngine.
final inferenceEngineProvider = Provider<InferenceEngine>((ref) {
  throw UnimplementedError(
    'inferenceEngineProvider must be overridden with a concrete implementation',
  );
});

/// Provider for the structured inference engine (TutorResponse).
///
/// Composes the raw engine with the tutor response parser.
final structuredInferenceEngineProvider =
    Provider<StructuredInferenceEngine<TutorResponse>>((ref) {
  return StructuredInferenceEngine(
    engine: ref.watch(inferenceEngineProvider),
    parser: StructuredOutputParser(fromJson: TutorResponse.fromJson),
  );
});
```

## Tests

`test/services/json_extractor_test.dart`:
- Extracts pure JSON string
- Extracts from markdown code block (with and without json tag)
- Extracts JSON substring from mixed text
- Returns null for text with no JSON

`test/services/structured_output_parser_test.dart`:
- Parses valid TutorResponse JSON
- Parses valid JSON of any freezed type (test with ModelMetadata)
- Returns ParseFailure for invalid JSON
- Returns ParseFailure for valid JSON that doesn't match schema
- Returns ParseFailure for non-JSON text

`test/services/structured_inference_engine_test.dart`:
- Returns StructuredSuccess when engine succeeds and parsing succeeds
- Returns StructuredInferenceFailure when engine fails
- Returns StructuredParseFailure when engine succeeds but parsing fails

## Migration checklist

- [ ] Create `json_extractor.dart`
- [ ] Rewrite `structured_output_parser.dart` as generic
- [ ] Create `structured_inference_engine.dart`
- [ ] Remove `tutorResponse` field from `InferenceSuccess`
- [ ] Remove `TutorResponse` import from `inference_engine.dart`
- [ ] Update `FakeInferenceEngine` (remove tutorResponse from return)
- [ ] Update `inference_provider.dart` (add structuredInferenceEngineProvider)
- [ ] Update all existing tests that reference `InferenceSuccess.tutorResponse`
- [ ] `flutter analyze` passes
- [ ] All tests pass

## Acceptance criteria

- [ ] InferenceEngine has no knowledge of TutorResponse or any domain type
- [ ] StructuredOutputParser<T> works with any type that has fromJson
- [ ] StructuredInferenceEngine<T> composes engine + parser with three-state result
- [ ] JsonExtractor is independently testable
- [ ] Existing tests updated and passing
- [ ] No breaking change to engine implementations (just removal of one field)
