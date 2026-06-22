import 'dart:convert';

import 'package:fala/services/inference/partial_json_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = PartialJsonParser();

  group('PartialJsonParser - openings', () {
    test('empty buffer yields an empty, open map', () {
      final result = parser.parse('');
      expect(result.value, <String, dynamic>{});
      expect(result.closure.closed, isFalse);
    });

    test('lone opening brace yields an empty, open map', () {
      final result = parser.parse('{');
      expect(result.value, <String, dynamic>{});
      expect(result.closure.closed, isFalse);
    });

    test('completed key without colon is not committed', () {
      final result = parser.parse('{"a"');
      expect(result.value, <String, dynamic>{});
      expect(result.closure.closed, isFalse);
    });

    test('key with colon but no value yields a null leaf', () {
      final result = parser.parse('{"a":');
      expect(result.value, {'a': null});
      expect(result.closure.field('a')!.closed, isFalse);
    });
  });

  group('PartialJsonParser - strings', () {
    test('mid-token string is exposed as its prefix and left open', () {
      final result = parser.parse('{"a":"hel');
      expect(result.value, {'a': 'hel'});
      expect(result.closure.field('a')!.closed, isFalse);
    });

    test('closed string is marked closed', () {
      final result = parser.parse('{"a":"hello"');
      expect(result.value, {'a': 'hello'});
      expect(result.closure.field('a')!.closed, isTrue);
    });

    test('escaped quote inside a closed string', () {
      final result = parser.parse(r'{"a":"he\"llo"}');
      expect(result.value, {'a': 'he"llo'});
      expect(result.closure.field('a')!.closed, isTrue);
      expect(result.closure.closed, isTrue);
    });

    test('escaped quote inside a truncated string stays open', () {
      final result = parser.parse(r'{"a":"he\"llo');
      expect(result.value, {'a': 'he"llo'});
      expect(result.closure.field('a')!.closed, isFalse);
    });

    test('dangling backslash at end-of-input is dropped', () {
      final result = parser.parse(r'{"a":"hi\');
      expect(result.value, {'a': 'hi'});
      expect(result.closure.field('a')!.closed, isFalse);
    });
  });

  group('PartialJsonParser - unicode escapes', () {
    test('complete unicode escape decodes', () {
      final result = parser.parse(r'{"a":"é"}');
      expect(result.value, {'a': 'é'});
      expect(result.closure.field('a')!.closed, isTrue);
    });

    test('incomplete unicode escape is dropped, prefix kept and open', () {
      final result = parser.parse(r'{"a":"x\u00');
      expect(result.value, {'a': 'x'});
      expect(result.closure.field('a')!.closed, isFalse);
    });
  });

  group('PartialJsonParser - numbers', () {
    test('number mid-token is exposed but left open', () {
      final result = parser.parse('{"n":12');
      expect(result.value, {'n': 12});
      expect(result.closure.field('n')!.closed, isFalse);
    });

    test('number followed by a delimiter is closed', () {
      final result = parser.parse('{"n":12,"m":3}');
      expect(result.value, {'n': 12, 'm': 3});
      expect(result.closure.field('n')!.closed, isTrue);
      expect(result.closure.field('m')!.closed, isTrue);
    });

    test('trailing dot keeps the longest numeric prefix', () {
      final result = parser.parse('{"n":12.');
      expect(result.value, {'n': 12});
      expect(result.closure.field('n')!.closed, isFalse);
    });
  });

  group('PartialJsonParser - arrays', () {
    test('open array exposes zero elements and stays open', () {
      final result = parser.parse('{"a":"hello","b":[');
      expect(result.value, {'a': 'hello', 'b': <dynamic>[]});
      expect(result.closure.field('a')!.closed, isTrue);
      expect(result.closure.field('b')!.closed, isFalse);
      expect(result.closure.field('b')!.elements, isEmpty);
    });

    test('closed array marks elements closed', () {
      final result = parser.parse('{"b":[1,2]}');
      expect(result.value, {
        'b': [1, 2],
      });
      final b = result.closure.field('b')!;
      expect(b.closed, isTrue);
      expect(b.element(0)!.closed, isTrue);
      expect(b.element(1)!.closed, isTrue);
    });

    test('last element partial: array exposes k elements, last open', () {
      final result = parser.parse('{"a":[{"x":1},{"x":');
      expect(result.value, {
        'a': [
          {'x': 1},
          {'x': null},
        ],
      });
      final a = result.closure.field('a')!;
      expect(a.closed, isFalse);
      expect(a.element(0)!.closed, isTrue);
      expect(a.element(0)!.field('x')!.closed, isTrue);
      expect(a.element(1)!.closed, isFalse);
      expect(a.element(1)!.field('x')!.closed, isFalse);
    });
  });

  group('PartialJsonParser - markdown fence and completion', () {
    test('skips a leading code fence to find the object', () {
      final result = parser.parse('```json\n{"a":"hi"}');
      expect(result.value, {'a': 'hi'});
      expect(result.closure.closed, isTrue);
    });

    test('ignores a trailing fence after the closed object', () {
      final result = parser.parse('```json\n{"a":"hi"}\n```');
      expect(result.value, {'a': 'hi'});
      expect(result.closure.closed, isTrue);
    });

    test('a complete document matches jsonDecode and is fully closed', () {
      const input =
          '{"correction":{"content":"Ola","errors":[{"original":"vc",'
          '"corrected":"voce"}]},"conversation":{"content":"Oi!"}}';
      final result = parser.parse(input);
      expect(result.value, jsonDecode(input));
      expect(result.closure.closed, isTrue);
      final errors = result.closure.field('correction')!.field('errors')!;
      expect(errors.closed, isTrue);
      expect(errors.element(0)!.field('corrected')!.closed, isTrue);
    });
  });
}
