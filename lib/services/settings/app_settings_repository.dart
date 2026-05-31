import 'package:hive/hive.dart';

import '../../models/cefr_level.dart';
import '../inference/engine_kind.dart';

/// Hive-backed store for non-secret app settings.
///
/// Uses a single `Box<String>` (`app_settings` by default), with plain string
/// values keyed by the constants on this class. Enums are persisted via
/// [Enum.name] and parsed defensively so a renamed value does not crash the
/// app - the documented default is used instead.
///
/// Secrets (the OpenAI API key) live in `ApiKeyStore`, not here.
class AppSettingsRepository {
  AppSettingsRepository({this.boxName = boxNameDefault});

  /// Default Hive box name. Exposed for tests that want a fresh box.
  static const String boxNameDefault = 'app_settings';

  /// Hive key storing the selected [EngineKind] as its [Enum.name].
  static const String keyEngineKind = 'engine_kind';

  /// Hive key storing the OpenAI model id (used by 03.2). Reserved here.
  static const String keyOpenaiModel = 'openai_model';

  /// Hive key storing the default [CefrLevel] for new conversations.
  static const String keyDefaultCefr = 'default_cefr';

  /// Hive key storing the default topic seed for new conversations.
  static const String keyDefaultTopic = 'default_topic';

  /// Fallback when no value is stored or the stored value is unknown.
  static const EngineKind defaultEngineKind = EngineKind.gemma;

  /// Fallback OpenAI model id used by 03.2.
  static const String defaultOpenaiModel = 'gpt-4o-mini';

  /// Fallback CEFR level for the very first conversation.
  static const CefrLevel defaultCefrLevel = CefrLevel.a1;

  /// Empty string means "no topic" (the prompt template degrades gracefully).
  static const String defaultTopic = '';

  final String boxName;
  late Box<String> _box;

  /// Open the Hive box. Must be called before any other method.
  Future<void> initialize() async {
    _box = await Hive.openBox<String>(boxName);
  }

  /// Returns the persisted [EngineKind], or [defaultEngineKind] when none is
  /// stored or the stored value does not map to a known enum case.
  EngineKind engineKind() {
    final raw = _box.get(keyEngineKind);
    if (raw == null) return defaultEngineKind;
    try {
      return EngineKind.values.byName(raw);
    } on ArgumentError {
      return defaultEngineKind;
    }
  }

  /// Persist [kind] as the active engine selection.
  Future<void> setEngineKind(EngineKind kind) async {
    await _box.put(keyEngineKind, kind.name);
  }

  /// Returns the persisted OpenAI model id, or [defaultOpenaiModel].
  String openaiModel() {
    return _box.get(keyOpenaiModel) ?? defaultOpenaiModel;
  }

  /// Persist [model] as the OpenAI model id.
  Future<void> setOpenaiModel(String model) async {
    await _box.put(keyOpenaiModel, model);
  }

  /// Returns the persisted default [CefrLevel], or [defaultCefrLevel] when
  /// none is stored or the stored value does not map to a known level.
  CefrLevel defaultCefr() {
    return CefrLevelX.fromString(_box.get(keyDefaultCefr)) ?? defaultCefrLevel;
  }

  /// Persist [level] as the default CEFR level for new conversations.
  Future<void> setDefaultCefr(CefrLevel level) async {
    await _box.put(keyDefaultCefr, level.name);
  }

  /// Returns the persisted default topic seed (or empty string).
  String defaultTopicValue() {
    return _box.get(keyDefaultTopic) ?? defaultTopic;
  }

  /// Persist [topic] as the default topic seed for new conversations.
  Future<void> setDefaultTopic(String topic) async {
    await _box.put(keyDefaultTopic, topic);
  }

  /// Close the underlying Hive box.
  Future<void> close() async {
    await _box.close();
  }
}
