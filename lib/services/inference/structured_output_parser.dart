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
