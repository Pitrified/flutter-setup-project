import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'providers/app_provider.dart';
import 'providers/inference_provider.dart';
import 'providers/service_providers.dart';
import 'services/inference/fake_inference_engine.dart';
import 'services/inference/flutter_gemma_engine.dart';
import 'services/persistence/conversation_repository.dart';

/// Set to true via --dart-define=FAKE_ENGINE=true for dev/test builds.
const bool kUseFakeEngine = bool.fromEnvironment(
  'FAKE_ENGINE',
  defaultValue: false,
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  if (!kUseFakeEngine) {
    await FlutterGemma.initialize();
  }

  // Initialize repository before app starts
  final repo = ConversationRepository();
  await repo.initialize();

  runApp(
    ProviderScope(
      overrides: [
        engineFactoryProvider.overrideWithValue(
          kUseFakeEngine
              ? (_) => FakeInferenceEngine()
              : (modelPath) => FlutterGemmaEngine(modelPath: modelPath),
        ),
        if (kUseFakeEngine)
          skipModelCheckProvider.overrideWithValue(true),
        conversationRepositoryProvider.overrideWithValue(repo),
      ],
      child: const FalaApp(),
    ),
  );
}
