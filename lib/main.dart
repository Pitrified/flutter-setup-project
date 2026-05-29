import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'providers/inference_provider.dart';
import 'providers/service_providers.dart';
import 'services/inference/fake_inference_engine.dart';
import 'services/persistence/conversation_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // Initialize repository before app starts
  final repo = ConversationRepository();
  await repo.initialize();

  runApp(
    ProviderScope(
      overrides: [
        inferenceEngineProvider.overrideWithValue(FakeInferenceEngine()),
        conversationRepositoryProvider.overrideWithValue(repo),
      ],
      child: const FalaApp(),
    ),
  );
}
