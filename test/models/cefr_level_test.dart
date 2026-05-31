import 'package:fala/models/cefr_level.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('displayName uppercases the enum name', () {
    expect(CefrLevel.a1.displayName, 'A1');
    expect(CefrLevel.b2.displayName, 'B2');
    expect(CefrLevel.c2.displayName, 'C2');
  });

  test('description is non-empty for every level', () {
    for (final level in CefrLevel.values) {
      expect(level.description, isNotEmpty);
    }
  });

  group('CefrLevelX.fromString', () {
    test('parses the enum name (lowercase)', () {
      expect(CefrLevelX.fromString('a1'), CefrLevel.a1);
      expect(CefrLevelX.fromString('c2'), CefrLevel.c2);
    });

    test('parses the display name (uppercase)', () {
      expect(CefrLevelX.fromString('A1'), CefrLevel.a1);
      expect(CefrLevelX.fromString('B1'), CefrLevel.b1);
    });

    test('returns null for unknown values', () {
      expect(CefrLevelX.fromString('foo'), isNull);
      expect(CefrLevelX.fromString(''), isNull);
      expect(CefrLevelX.fromString(null), isNull);
    });
  });
}
