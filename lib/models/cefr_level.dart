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

  /// One-sentence description suitable for the picker bottom sheet.
  String get description {
    switch (this) {
      case CefrLevel.a1:
        return 'Beginner.';
      case CefrLevel.a2:
        return 'Elementary.';
      case CefrLevel.b1:
        return 'Intermediate.';
      case CefrLevel.b2:
        return 'Upper-intermediate.';
      case CefrLevel.c1:
        return 'Advanced.';
      case CefrLevel.c2:
        return 'Mastery.';
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
