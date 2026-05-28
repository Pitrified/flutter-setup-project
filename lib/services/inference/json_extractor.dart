import 'dart:convert';

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
    } on FormatException {
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
