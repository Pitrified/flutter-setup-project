import 'dart:convert';

import 'package:fala/models/tutor_response.dart';
import 'package:fala/services/inference/structured_output_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = StructuredOutputParser<TutorResponse>(
    fromJson: TutorResponse.fromJson,
  );

  final validJson = jsonEncode({
    'correction': {
      'content': 'Eu gosto de cafe',
      'translation': 'I like coffee',
      'errors': <Map<String, dynamic>>[],
    },
    'conversation': {
      'content': 'Muito bem!',
      'translation': 'Very good!',
    },
  });

  group('StructuredOutputParser', () {
    test('parses pure JSON directly', () {
      final result = parser.parse(validJson);
      expect(result, isA<ParseSuccess<TutorResponse>>());
      final success = result as ParseSuccess<TutorResponse>;
      expect(success.value.conversation.content, 'Muito bem!');
    });

    test('extracts JSON from markdown code block', () {
      final input = 'Here is the response:\n```json\n$validJson\n```\n';
      final result = parser.parse(input);
      expect(result, isA<ParseSuccess<TutorResponse>>());
    });

    test('extracts JSON substring from surrounding text', () {
      final input = 'Sure! Here you go: $validJson and that is it.';
      final result = parser.parse(input);
      expect(result, isA<ParseSuccess<TutorResponse>>());
    });

    test('returns failure for invalid JSON', () {
      final result = parser.parse('not json at all');
      expect(result, isA<ParseFailure<TutorResponse>>());
      final failure = result as ParseFailure<TutorResponse>;
      expect(failure.error, contains('Could not extract'));
    });

    test('returns failure for empty string', () {
      final result = parser.parse('');
      expect(result, isA<ParseFailure<TutorResponse>>());
    });

    test('returns failure for valid JSON but wrong schema', () {
      final result = parser.parse('{"foo": "bar"}');
      expect(result, isA<ParseFailure<TutorResponse>>());
    });

    test('parses response with errors', () {
      final json = jsonEncode({
        'correction': {
          'content': 'Eu estou cansado',
          'translation': 'I am tired',
          'errors': [
            {
              'original': 'Eu sou cansado',
              'corrected': 'Eu estou cansado',
              'explanation': 'Use estar for temporary states.',
            },
          ],
        },
        'conversation': {
          'content': 'Boa tentativa!',
          'translation': 'Good try!',
        },
      });
      final result = parser.parse(json);
      expect(result, isA<ParseSuccess<TutorResponse>>());
      final success = result as ParseSuccess<TutorResponse>;
      expect(success.value.correction.errors, hasLength(1));
      expect(
        success.value.correction.errors.first.original,
        'Eu sou cansado',
      );
    });
  });
}
