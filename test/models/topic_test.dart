import 'package:fala/models/topic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Topic equality is value-based', () {
    expect(const Topic(value: 'food'), const Topic(value: 'food'));
    expect(
      const Topic(value: 'food', isCustom: true),
      const Topic(value: 'food'),
    );
  });

  test('Topic.none is empty', () {
    expect(Topic.none.isEmpty, isTrue);
    expect(Topic.none.value, '');
  });

  test('kSuggestedTopics is non-empty and unique', () {
    expect(kSuggestedTopics, isNotEmpty);
    final values = kSuggestedTopics.map((t) => t.value).toSet();
    expect(values.length, kSuggestedTopics.length);
  });
}
