import 'dart:convert';

import 'json_extractor.dart';

/// Result of parsing raw LLM output into a structured type.
sealed class ParseResult<T> {
  const ParseResult();
}

class ParseSuccess<T> extends ParseResult<T> {
  const ParseSuccess({required this.value});

  /// The parsed and validated domain object.
  final T value;
}

class ParseFailure<T> extends ParseResult<T> {
  const ParseFailure({required this.rawText, required this.error});

  /// The raw text that could not be parsed.
  final String rawText;

  /// Description of the parse failure.
  final String error;
}

/// Generic parser that extracts JSON from LLM text and deserializes to T.
///
/// Works with any type that has a fromJson factory (all freezed models do).
/// Uses [JsonExtractor] for text extraction strategies, then [fromJson] for
/// deserialization and validation.
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
      final decoded = jsonDecode(jsonString);
      if (decoded is! Map<String, dynamic>) {
        return ParseFailure(
          rawText: rawText,
          error: 'Extracted JSON is not a Map',
        );
      }
      return ParseSuccess(value: fromJson(decoded));
    } on Object catch (e) {
      return ParseFailure(rawText: rawText, error: e.toString());
    }
  }
}
