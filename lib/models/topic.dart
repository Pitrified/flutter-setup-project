/// A topic biases the tutor's prompts toward a chosen subject.
///
/// `isCustom == false` indicates the entry came from [kSuggestedTopics];
/// `true` means the user typed it. Persisted as a plain string on the
/// `Conversation` and in `AppSettingsRepository.default_topic`; the
/// `isCustom` flag is metadata used by the picker UI only and is not
/// persisted.
class Topic {
  const Topic({required this.value, this.isCustom = false});

  /// The topic label as shown to the user and substituted into the prompt.
  final String value;

  /// Whether the user typed this rather than picking from suggestions.
  final bool isCustom;

  /// A sentinel for "no topic selected"; the prompt template degrades.
  static const Topic none = Topic(value: '');

  bool get isEmpty => value.isEmpty;

  @override
  bool operator ==(Object other) => other is Topic && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

/// Curated suggestions shown in the topic picker sheet. Stable, non-LLM.
const List<Topic> kSuggestedTopics = [
  Topic(value: 'Daily routine'),
  Topic(value: 'Food and cooking'),
  Topic(value: 'Travel'),
  Topic(value: 'Work and career'),
  Topic(value: 'Family'),
  Topic(value: 'Hobbies'),
  Topic(value: 'Sports'),
  Topic(value: 'Music'),
  Topic(value: 'Movies and TV'),
  Topic(value: 'Books and reading'),
  Topic(value: 'Health and fitness'),
  Topic(value: 'Technology'),
  Topic(value: 'Weather and seasons'),
  Topic(value: 'Shopping'),
  Topic(value: 'Brazilian culture'),
];
