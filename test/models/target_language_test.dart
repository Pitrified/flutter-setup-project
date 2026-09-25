import 'package:fala/models/target_language.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('codes are unique BCP-47 tags', () {
    final codes = TargetLanguage.values.map((l) => l.code).toList();
    expect(codes.toSet().length, codes.length);
    for (final code in codes) {
      expect(code, matches(RegExp(r'^[a-z]{2}-[A-Z]{2}$')));
    }
  });

  test('display name and endonym are non-empty for every language', () {
    for (final language in TargetLanguage.values) {
      expect(language.displayName, isNotEmpty, reason: language.name);
      expect(language.endonym, isNotEmpty, reason: language.name);
    }
  });

  test('promptName carries the variant only where there is one', () {
    expect(TargetLanguage.ptBr.promptName, 'Portuguese (Brazilian)');
    expect(TargetLanguage.frFr.promptName, 'French');
  });

  test('fromCode round-trips every language', () {
    for (final language in TargetLanguage.values) {
      expect(TargetLanguageX.fromCode(language.code), language);
    }
  });

  test('fromCode is case-insensitive', () {
    expect(TargetLanguageX.fromCode('PT-br'), TargetLanguage.ptBr);
  });

  test('fromCode returns null for null and for unsupported codes', () {
    expect(TargetLanguageX.fromCode(null), isNull);
    expect(TargetLanguageX.fromCode(''), isNull);
    expect(TargetLanguageX.fromCode('pt'), isNull);
    expect(TargetLanguageX.fromCode('ja-JP'), isNull);
  });

  test('en-US is not offered while explanations are English-only', () {
    expect(TargetLanguageX.fromCode('en-US'), isNull);
  });
}
