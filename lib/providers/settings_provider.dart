import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/inference/engine_kind.dart';
import '../services/settings/api_key_store.dart';
import '../services/settings/app_settings_repository.dart';
import 'app_provider.dart';
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
    state = kind;
    ref.invalidate(inferenceEngineProvider);
    ref.invalidate(appControllerProvider);
  }
}

/// Provider for the currently selected [EngineKind].
final selectedEngineKindProvider =
    NotifierProvider<SelectedEngineKindNotifier, EngineKind>(
      SelectedEngineKindNotifier.new,
    );
