/// Identifies which inference engine implementation is active.
///
/// Persisted in [AppSettingsRepository] under the `engine_kind` key as the
/// enum's [name]. Selection in the Settings screen drives which factory the
/// engine registry returns.
enum EngineKind {
  /// Scripted responses from an asset fixture. Used in tests and on-device
  /// UI smoke testing.
  fake,

  /// On-device LLM via `flutter_gemma` (currently Qwen3 0.6B).
  gemma,

  /// OpenAI cloud chat completions. Wired up in plan 03.2.
  openai,
}

/// UI helpers for [EngineKind].
extension EngineKindX on EngineKind {
  /// Human-readable label shown in the Settings selector.
  String get displayName {
    switch (this) {
      case EngineKind.fake:
        return 'Fake (scripted)';
      case EngineKind.gemma:
        return 'On-device (Gemma / Qwen3)';
      case EngineKind.openai:
        return 'OpenAI (cloud)';
    }
  }

  /// Whether a factory is registered for this kind in the engine registry.
  ///
  /// Returns `false` for kinds that are reserved but not yet wired up.
  /// 03.2 flips [openai] to `true` once `OpenAiInferenceEngine` lands.
  bool get isImplemented {
    switch (this) {
      case EngineKind.fake:
      case EngineKind.gemma:
        return true;
      case EngineKind.openai:
        return false;
    }
  }
}
