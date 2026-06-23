/// CEFR (Common European Framework of Reference) proficiency level.
///
/// Used by the conversation flow to bias the tutor's vocabulary and grammar
/// complexity. Persisted on each `Conversation` as a plain string, and as a
/// default in `AppSettingsRepository` under `default_cefr`.
enum CefrLevel {
  a1,
  a2,
  b1,
  b2,
  c1,
  c2,
}

/// Human-friendly display + parsing helpers for [CefrLevel].
extension CefrLevelX on CefrLevel {
  /// Two-character label, e.g. `'A1'`.
  String get displayName => name.toUpperCase();

  /// Short label, shown alongside [displayName] in the picker title, the
  /// Settings dropdown, and the chip tooltip.
  String get description {
    switch (this) {
      case CefrLevel.a1:
        return 'Beginner';
      case CefrLevel.a2:
        return 'Elementary';
      case CefrLevel.b1:
        return 'Intermediate';
      case CefrLevel.b2:
        return 'Upper-intermediate';
      case CefrLevel.c1:
        return 'Advanced';
      case CefrLevel.c2:
        return 'Mastery';
    }
  }

  /// Detailed sentence describing what the learner can do at this level.
  /// Shown as the picker subtitle and under the Settings default-level
  /// dropdown.
  String get guidance {
    switch (this) {
      case CefrLevel.a1:
        return 'Basic phrases, introductions, simple needs.';
      case CefrLevel.a2:
        return 'Familiar topics, short routine exchanges.';
      case CefrLevel.b1:
        return 'Travel situations, opinions on familiar topics.';
      case CefrLevel.b2:
        return 'Detailed discussion on a wide range of topics.';
      case CefrLevel.c1:
        return 'Fluent, flexible, nuanced expression.';
      case CefrLevel.c2:
        return 'Effortless, precise, near-native command.';
    }
  }

  /// Parse a string back to a [CefrLevel].
  ///
  /// Accepts both the enum name (`'a1'`) and the display name (`'A1'`).
  /// Returns `null` if [value] does not map to a known level.
  static CefrLevel? fromString(String? value) {
    if (value == null) return null;
    final lowered = value.toLowerCase();
    for (final level in CefrLevel.values) {
      if (level.name == lowered) return level;
    }
    return null;
  }
}
