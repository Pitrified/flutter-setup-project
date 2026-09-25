/// The language the learner is practising.
///
/// Persisted on each `Conversation` as the BCP-47 [TargetLanguageX.code], and
/// as a default in `AppSettingsRepository` under `default_language`. The set is
/// curated rather than free-form so the picker can list it, the prompt can name
/// the language properly, and an unknown stored value can fall back to the
/// documented default.
///
/// `en-US` is deliberately absent: the prompt writes corrections and
/// translations in English, so an English target would make every translation a
/// restatement. It becomes available when the explanation language is itself a
/// setting (see `docs/functional-specs.md`, "Target language").
enum TargetLanguage {
  ptBr,
  esEs,
  frFr,
  itIt,
  deDe,
}

/// Codes, labels and parsing for [TargetLanguage].
extension TargetLanguageX on TargetLanguage {
  /// BCP-47 tag, e.g. `'pt-BR'`. This is the persisted form, and what the
  /// audio work in phase 14 will need for dictation and speech locales.
  String get code {
    switch (this) {
      case TargetLanguage.ptBr:
        return 'pt-BR';
      case TargetLanguage.esEs:
        return 'es-ES';
      case TargetLanguage.frFr:
        return 'fr-FR';
      case TargetLanguage.itIt:
        return 'it-IT';
      case TargetLanguage.deDe:
        return 'de-DE';
    }
  }

  /// English name of the language, used in our own UI copy.
  String get displayName {
    switch (this) {
      case TargetLanguage.ptBr:
        return 'Portuguese';
      case TargetLanguage.esEs:
        return 'Spanish';
      case TargetLanguage.frFr:
        return 'French';
      case TargetLanguage.itIt:
        return 'Italian';
      case TargetLanguage.deDe:
        return 'German';
    }
  }

  /// The language's own name, shown as the picker subtitle.
  String get endonym {
    switch (this) {
      case TargetLanguage.ptBr:
        return 'português';
      case TargetLanguage.esEs:
        return 'español';
      case TargetLanguage.frFr:
        return 'français';
      case TargetLanguage.itIt:
        return 'italiano';
      case TargetLanguage.deDe:
        return 'Deutsch';
    }
  }

  /// Regional qualifier shown next to [displayName] where the code carries one
  /// that a learner would notice, e.g. Brazilian rather than European
  /// Portuguese. Empty when the region adds nothing for the user.
  String get variantLabel {
    switch (this) {
      case TargetLanguage.ptBr:
        return 'Brazilian';
      case TargetLanguage.esEs:
        return 'European';
      case TargetLanguage.frFr:
      case TargetLanguage.itIt:
      case TargetLanguage.deDe:
        return '';
    }
  }

  /// How the language is named to the model, e.g. `'Portuguese (Brazilian)'`.
  /// Both the English name and the variant, because the prompt is an English
  /// instruction about a language the reply has to be written in.
  String get promptName =>
      variantLabel.isEmpty ? displayName : '$displayName ($variantLabel)';

  /// Parse a persisted [code] back to a [TargetLanguage].
  ///
  /// Accepts the BCP-47 tag case-insensitively. Returns `null` when [value] is
  /// null or does not map to a supported language, so callers can apply their
  /// own documented default.
  static TargetLanguage? fromCode(String? value) {
    if (value == null) return null;
    final lowered = value.toLowerCase();
    for (final language in TargetLanguage.values) {
      if (language.code.toLowerCase() == lowered) return language;
    }
    return null;
  }
}
