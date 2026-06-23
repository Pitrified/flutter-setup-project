import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'providers/service_providers.dart';
import 'providers/settings_provider.dart';
import 'services/inference/engine_kind.dart';
import 'services/persistence/conversation_repository.dart';
import 'services/settings/app_settings_repository.dart';

/// Set to true via --dart-define=FAKE_ENGINE=true for dev/test builds.
///
/// When set on a fresh install (no persisted setting), boots into the fake
/// engine instead of the default on-device Gemma. Once the user picks an
/// engine in Settings, the persisted value wins.
const bool kUseFakeEngine = bool.fromEnvironment(
  'FAKE_ENGINE',
  defaultValue: false,
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  final settings = AppSettingsRepository();
  await settings.initialize();

  // Developer override: --dart-define=FAKE_ENGINE=true forces the fake engine
  // on this run and persists the choice so the Settings screen reflects it.
  if (kUseFakeEngine) {
    await settings.setEngineKind(EngineKind.fake);
  }

  // flutter_gemma requires initialize() before any plugin call, including the
  // model-installed check that runs when the on-device engine is selected.
  // Always initialize so switching to Gemma at runtime works regardless of
  // which engine the app booted with.
  await FlutterGemma.initialize();

  final repo = ConversationRepository();
  await repo.initialize();

  runApp(
    ProviderScope(
      overrides: [
        appSettingsRepositoryProvider.overrideWithValue(settings),
        conversationRepositoryProvider.overrideWithValue(repo),
      ],
      child: const FalaApp(),
    ),
  );
}
