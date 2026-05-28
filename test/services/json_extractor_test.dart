import 'dart:convert';

import 'package:fala/services/inference/json_extractor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const extractor = JsonExtractor();

  group('JsonExtractor', () {
    test('parses direct JSON string', () {
      const input = '{"name": "test"}';
      final result = extractor.extract(input);
      expect(result, isNotNull);
      final map = jsonDecode(result!) as Map<String, dynamic>;
      expect(map['name'], 'test');
    });

    test('extracts JSON from markdown code block', () {
      const input = '''
Here is the response:
```json
{"correction": {"content": "Ola", "translation": "Hello", "errors": []}, "conversation": {"content": "Oi!", "translation": "Hi!"}}
```
''';
      final result = extractor.extract(input);
      expect(result, isNotNull);
      final map = jsonDecode(result!) as Map<String, dynamic>;
      expect(map['correction'], isA<Map>());
    });

    test('extracts JSON from code block without language tag', () {
      const input = '''
```
{"key": "value"}
```
''';
      final result = extractor.extract(input);
      expect(result, isNotNull);
      final map = jsonDecode(result!) as Map<String, dynamic>;
      expect(map['key'], 'value');
    });

    test('extracts JSON embedded in prose', () {
      const input =
          'Sure! Here is the output: {"key": "value"} Hope that helps!';
      final result = extractor.extract(input);
      expect(result, isNotNull);
      final map = jsonDecode(result!) as Map<String, dynamic>;
      expect(map['key'], 'value');
    });

    test('returns null for invalid input', () {
      const input = 'This is just plain text with no JSON.';
      final result = extractor.extract(input);
      expect(result, isNull);
    });

    test('returns null for empty string', () {
      final result = extractor.extract('');
      expect(result, isNull);
    });

    test('handles nested JSON objects', () {
      const input =
          '{"outer": {"inner": "value"}, "list": [1, 2, 3]}';
      final result = extractor.extract(input);
      expect(result, isNotNull);
      final map = jsonDecode(result!) as Map<String, dynamic>;
      expect(map['outer'], isA<Map>());
      expect(map['list'], isA<List>());
    });
  });
}
