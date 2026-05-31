import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cefr_level.dart';
import '../services/inference/engine_kind.dart';
import '../services/settings/api_key_store.dart';
import '../services/settings/app_settings_repository.dart';
import 'inference_provider.dart';

/// Provider for the non-secret settings repository (Hive-backed).
///
/// Must be overridden in `main.dart` with an already-initialized instance.
final appSettingsRepositoryProvider = Provider<AppSettingsRepository>((ref) {
  throw UnimplementedError(
    'appSettingsRepositoryProvider must be overridden with an initialized '
    'AppSettingsRepository in main.dart',
  );
});

/// Provider for the secure-storage wrapper around the OpenAI API key.
///
/// Default value is fine for runtime; override in tests with a fake.
final apiKeyStoreProvider = Provider<ApiKeyStore>((ref) => ApiKeyStore());

/// Reactive holder for the currently selected [EngineKind].
///
/// Reads the initial value from [AppSettingsRepository] and persists every
/// change. Mutating the state via [select] invalidates [appControllerProvider]
/// so the next welcome-screen entry re-initializes against the new engine.
class SelectedEngineKindNotifier extends Notifier<EngineKind> {
  @override
  EngineKind build() {
    return ref.read(appSettingsRepositoryProvider).engineKind();
  }

  /// Persist [kind] and update the active selection.
  ///
  /// Refuses kinds that are not yet implemented (see
  /// [EngineKindX.isImplemented]) so a stale UI cannot pick `openai` before
  /// plan 03.2 lands.
  Future<void> select(EngineKind kind) async {
    if (!kind.isImplemented) {
      throw StateError('EngineKind.${kind.name} is not implemented yet.');
    }
    if (kind == state) return;
    await ref.read(appSettingsRepositoryProvider).setEngineKind(kind);
    // Clear the cached engine instance so the next AppController.initialize
    // builds a fresh one for the new kind. appControllerProvider and
    // engineFactoryProvider rebuild automatically because they watch this
    // provider; calling ref.invalidate on them here would trip Riverpod's
    // circular-dependency guard.
    ref.read(inferenceEngineProvider.notifier).clearEngine();
    state = kind;
  }
}

/// Provider for the currently selected [EngineKind].
final selectedEngineKindProvider =
    NotifierProvider<SelectedEngineKindNotifier, EngineKind>(
      SelectedEngineKindNotifier.new,
    );

/// Reactive holder for the selected OpenAI model id.
///
/// Persists to the same Hive box used by [SelectedEngineKindNotifier], but
/// **does not invalidate** the engine providers: the active
/// `OpenAiInferenceEngine` reads the model on every `generate()` call, so the
/// new value applies to the next message without rebuilding anything.
///
/// Future non-engine settings (CEFR level, persona, theme) should follow this
/// same pattern: dedicated notifier, write-through to the repository, no
/// cross-invalidation of engine providers.
class OpenaiModelNotifier extends Notifier<String> {
  @override
  String build() {
    return ref.read(appSettingsRepositoryProvider).openaiModel();
  }

  /// Persist [model] and update the cached value.
  Future<void> setModel(String model) async {
    final trimmed = model.trim();
    if (trimmed.isEmpty || trimmed == state) return;
    await ref.read(appSettingsRepositoryProvider).setOpenaiModel(trimmed);
    state = trimmed;
  }
}

/// Provider for the OpenAI model id (e.g. `gpt-4o-mini`).
final openaiModelProvider = NotifierProvider<OpenaiModelNotifier, String>(
  OpenaiModelNotifier.new,
);

/// Reactive holder for the default [CefrLevel] used to seed new conversations.
///
/// Persists to [AppSettingsRepository] but **does not invalidate** the engine
/// providers - changing the CEFR level is a non-engine setting (Settings
/// invalidation discipline from `08/03.2`).
///
/// The active conversation's level is owned by the conversation itself
/// (via `ConversationController.setCefrLevel`); this provider only controls
/// the default applied to brand-new conversations.
class DefaultCefrLevelNotifier extends Notifier<CefrLevel> {
  @override
  CefrLevel build() {
    return ref.read(appSettingsRepositoryProvider).defaultCefr();
  }

  /// Persist [level] as the default CEFR for future conversations.
  Future<void> select(CefrLevel level) async {
    if (level == state) return;
    await ref.read(appSettingsRepositoryProvider).setDefaultCefr(level);
    state = level;
  }
}

/// Provider for the default [CefrLevel] used when starting new conversations.
final defaultCefrLevelProvider =
    NotifierProvider<DefaultCefrLevelNotifier, CefrLevel>(
      DefaultCefrLevelNotifier.new,
    );

/// Reactive holder for the default topic seed used when starting new
/// conversations. Empty string = no topic preference.
///
/// Same discipline as [DefaultCefrLevelNotifier]: persists to the repository,
/// no engine-provider invalidation. The active conversation's topic is owned
/// by the conversation itself (via `ConversationController.setTopic`).
class DefaultTopicNotifier extends Notifier<String> {
  @override
  String build() {
    return ref.read(appSettingsRepositoryProvider).defaultTopicValue();
  }

  /// Persist [topic] (trimmed) as the default for future conversations.
  Future<void> select(String topic) async {
    final trimmed = topic.trim();
    if (trimmed == state) return;
    await ref.read(appSettingsRepositoryProvider).setDefaultTopic(trimmed);
    state = trimmed;
  }
}

/// Provider for the default topic seed (or empty string).
final defaultTopicProvider =
    NotifierProvider<DefaultTopicNotifier, String>(DefaultTopicNotifier.new);
